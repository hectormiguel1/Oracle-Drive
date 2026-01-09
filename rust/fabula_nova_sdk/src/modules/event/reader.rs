//! # Event Binary Reader
//!
//! This module provides binary parsing for Event files (cutscene schedules).
//! Event files are WPD containers with SEDBSCB and SRB records.

use std::io::{Read, Seek};
use anyhow::{Result, Context};
use super::structs::*;
use crate::modules::wpd::reader::WpdReader;

/// Binary reader for Event XWB files.
pub struct EventReader<R: Read + Seek> {
    reader: R,
}

impl<R: Read + Seek> EventReader<R> {
    /// Creates a new Event reader.
    pub fn new(reader: R) -> Self {
        Self { reader }
    }

    /// Reads and parses the entire event file.
    pub fn read_event(&mut self) -> Result<EventMetadata> {
        // Read as WPD container first
        let mut wpd_reader = WpdReader::new(&mut self.reader);
        let header = wpd_reader.read_header()
            .context("Failed to read WPD header")?;
        let records = wpd_reader.read_records(&header)
            .context("Failed to read WPD records")?;

        let mut meta = EventMetadata::default();
        meta.record_count = records.len();

        // Build WPD record info list
        // Note: WpdRecord doesn't track offset, so we calculate cumulative offset
        let mut cumulative_offset = 0x10 + (records.len() as u32 * 0x20); // Header + record entries
        for record in &records {
            let size = record.data.len() as u32;
            meta.wpd_records.push(WpdRecordInfo {
                name: record.name.clone(),
                extension: record.extension.clone(),
                offset: cumulative_offset,
                size,
            });
            // Align to 16-byte boundary for next record
            cumulative_offset += (size + 15) & !15;
        }

        // Parse each record based on name/extension
        for record in &records {
            match record.name.as_str() {
                "!!cutsch" => {
                    // Main schedule - parse SCB
                    self.parse_scb(&record.data, &mut meta)?;
                }
                "!!cutsndrsinf" => {
                    // Sound resource info - parse SRB
                    self.parse_srb(&record.data, &mut meta)?;
                }
                "!!cutreslist" => {
                    // Resource list - parse external references
                    self.parse_cutreslist(&record.data, &mut meta)?;
                }
                name if !name.starts_with("!!") && record.extension == "txt" => {
                    // Dialogue entry
                    let raw_content = String::from_utf8_lossy(&record.data)
                        .trim_matches('\0')
                        .to_string();

                    meta.dialogue_entries.push(DialogueEntry {
                        record_name: name.to_string(),
                        raw_content,
                        ztr_key: format!("${}", name),
                    });
                }
                _ => {
                    log::debug!("Skipping record: {} ({})", record.name, record.extension);
                }
            }
        }

        Ok(meta)
    }

    /// Parses SEDBSCB (cutscene schedule block) data.
    fn parse_scb(&self, data: &[u8], meta: &mut EventMetadata) -> Result<()> {
        // Validate SEDBSCB header
        if data.len() < 48 {
            anyhow::bail!("SCB data too short");
        }

        if &data[0..8] != b"SEDBSCB\0" {
            anyhow::bail!("Invalid SEDBSCB magic");
        }

        // Extract schedule header info
        let version = u16::from_be_bytes([data[8], data[9]]) as u32;
        let header_size = u32::from_be_bytes([data[12], data[13], data[14], data[15]]);
        let data_size = u32::from_be_bytes([data[16], data[17], data[18], data[19]]);

        meta.schedule_header = Some(ScheduleHeader {
            magic: "SEDBSCB".to_string(),
            version,
            header_size,
            data_size,
        });

        // Count all section types
        meta.section_counts = count_sections(data);

        // Scan for @CACT sections (actors)
        self.parse_actors(data, meta);

        // Scan for @CBLK sections (blocks)
        self.parse_blocks(data, meta);

        // Scan for @CRES sections (resources)
        self.parse_resources(data, meta);

        Ok(())
    }

    /// Parses SRB (sound resource block) data.
    fn parse_srb(&self, data: &[u8], meta: &mut EventMetadata) -> Result<()> {
        // Validate SRB header
        if data.len() < 16 {
            return Ok(()); // Empty or minimal SRB
        }

        if &data[0..4] != b"SRB\0" {
            anyhow::bail!("Invalid SRB magic");
        }

        // Version check: "Ver.4"
        if data.len() >= 12 && &data[4..9] != b"Ver.4" {
            log::warn!("Unexpected SRB version");
        }

        // Parse sound block entries
        // Format: After header (16 bytes), blocks are 16-byte name + data
        let mut offset = 16;

        while offset + 32 <= data.len() {
            // Check for block name pattern (e.g., "Block000")
            let name_bytes = &data[offset..offset + 16];
            let name = extract_string(name_bytes);

            if name.starts_with("Block") || (!name.is_empty() && name.chars().all(|c| c.is_alphanumeric() || c == '_') && !name.starts_with("music") && !name.starts_with("atb")) {

                // Read duration after name block
                if offset + 32 <= data.len() {
                    let duration_bytes = &data[offset + 24..offset + 28];
                    let duration_samples = u32::from_be_bytes([
                        duration_bytes[0], duration_bytes[1],
                        duration_bytes[2], duration_bytes[3]
                    ]);

                    if duration_samples > 0 && duration_samples < 0x10000000 {
                        meta.sound_blocks.push(SoundBlock {
                            name: name.clone(),
                            duration_samples,
                            duration_seconds: duration_samples as f32 / 44100.0,
                        });
                    }
                }
            }

            offset += 32;

            // Safety limit
            if meta.sound_blocks.len() > 100 {
                break;
            }
        }

        // Extract sound references by scanning for known patterns
        self.extract_sound_references(data, meta);

        Ok(())
    }

    /// Extracts sound references from SRB data by scanning for known patterns.
    fn extract_sound_references(&self, data: &[u8], meta: &mut EventMetadata) {
        // Sound reference patterns to look for
        let patterns: &[&[u8]] = &[
            b"music_",
            b"atb_",
            b"se_",
            b"voice_",
            b"vo_",
            b"sfx_",
            b"amb_",
            b"bgm_",
        ];

        let mut current_block = String::from("unknown");

        // First, try to find the block name context
        if let Some(pos) = data.windows(5).position(|w| w == b"Block") {
            if pos + 16 <= data.len() {
                current_block = extract_string(&data[pos..pos + 16]);
            }
        }

        for pattern in patterns {
            for pos in find_all_patterns(data, pattern) {
                // Extract the full sound ID
                let start = pos;
                let end = data[start..].iter()
                    .position(|&b| b == 0 || !b.is_ascii_graphic())
                    .map(|e| start + e)
                    .unwrap_or((start + 64).min(data.len()));

                if end > start {
                    let sound_id = String::from_utf8_lossy(&data[start..end]).to_string();

                    // Skip if too short or already added
                    if sound_id.len() < 4 {
                        continue;
                    }

                    if meta.sound_references.iter().any(|r| r.sound_id == sound_id) {
                        continue;
                    }

                    let sound_type = SoundType::from_id(&sound_id);

                    meta.sound_references.push(SoundReference {
                        block_name: current_block.clone(),
                        sound_id,
                        sound_type,
                    });
                }
            }
        }
    }

    /// Parses cutreslist (external resource references).
    fn parse_cutreslist(&self, data: &[u8], meta: &mut EventMetadata) -> Result<()> {
        // Resource list is null-separated entries
        // Format: <name>\0<hash>\0<name>\0<hash>\0...

        let text = String::from_utf8_lossy(data);
        let parts: Vec<&str> = text.split('\0').filter(|s| !s.is_empty()).collect();

        let mut i = 0;
        while i < parts.len() {
            let name = parts[i];
            let hash = if i + 1 < parts.len() && parts[i + 1].starts_with('E') {
                Some(parts[i + 1].to_string())
            } else {
                None
            };

            // Determine resource type from prefix
            let resource_type = if name.starts_with('c') {
                "camera"
            } else if name.starts_with('f') {
                "facial/animation"
            } else if name.starts_with('w') {
                "world/environment"
            } else if name.starts_with('n') {
                "normal"
            } else if name.starts_with('b') {
                "block"
            } else {
                "unknown"
            };

            // Only add if it looks like a valid resource reference
            let has_hash = hash.is_some();
            if name.len() > 2 && (has_hash || name.contains('_')) {
                // Add to resources (legacy field)
                meta.resources.push(EventResource {
                    name: name.to_string(),
                    resource_type: resource_type.to_string(),
                    external_hash: hash.clone(),
                });

                // Add to external_resources with proper categorization
                if let Some(hash_str) = &hash {
                    let category = ResourceCategory::from_name(name);
                    meta.external_resources.push(ExternalResource {
                        name: name.to_string(),
                        hash: hash_str.clone(),
                        category,
                    });
                }
            }

            i += if has_hash { 2 } else { 1 };
        }

        Ok(())
    }

    /// Scans for and parses @CACT (actor) sections.
    fn parse_actors(&self, data: &[u8], meta: &mut EventMetadata) {
        // Find all @CACT sections
        let tag = b"@CACT\0";

        for pos in find_all_patterns(data, tag) {
            if let Some(actor) = self.parse_actor_at(data, pos) {
                meta.actors.push(actor);
            }
        }
    }

    /// Parses a single actor at the given offset.
    fn parse_actor_at(&self, data: &[u8], offset: usize) -> Option<EventActor> {
        // @CACT section format:
        // 0x00: "@CACT\0" (6 bytes)
        // 0x06: entry count (u16)
        // 0x08: sub-count (u16)
        // 0x0A: type flags (u16)
        // 0x0C: reserved (4 bytes)
        // 0x10+: actor entries

        if offset + 16 > data.len() {
            return None;
        }

        let entry_count = u16::from_be_bytes([data[offset + 6], data[offset + 7]]);

        // Parse actor entries after the header
        let mut actors = Vec::new();
        let mut entry_offset = offset + 16;

        for _ in 0..entry_count {
            if entry_offset + 32 > data.len() {
                break;
            }

            // Actor entry format:
            // 0x00: flags (4 bytes)
            // 0x04: name (16 bytes)
            // 0x14: type (2 bytes)
            // 0x16: index (2 bytes)

            let flags = u32::from_be_bytes([
                data[entry_offset], data[entry_offset + 1],
                data[entry_offset + 2], data[entry_offset + 3]
            ]);

            let name = extract_string(&data[entry_offset + 4..entry_offset + 20]);
            let _type_code = u16::from_be_bytes([data[entry_offset + 20], data[entry_offset + 21]]);
            let index = u16::from_be_bytes([data[entry_offset + 22], data[entry_offset + 23]]);

            if !name.is_empty() {
                let actor_type = classify_actor(&name);
                actors.push(EventActor {
                    name,
                    actor_type,
                    index,
                    flags,
                });
            }

            // Move to next entry (variable size based on flags)
            entry_offset += 24;

            // Skip additional data based on flags
            if flags & 0x20 != 0 {
                entry_offset += 8;
            }
        }

        // Return first actor found (for single-actor sections)
        actors.into_iter().next()
    }

    /// Scans for and parses @CBLK (block) sections.
    fn parse_blocks(&self, data: &[u8], meta: &mut EventMetadata) {
        let tag = b"@CBLK\0";

        for pos in find_all_patterns(data, tag) {
            if let Some(block) = self.parse_block_at(data, pos) {
                // Avoid duplicates
                if !meta.blocks.iter().any(|b| b.name == block.name) {
                    meta.blocks.push(block);
                }
            }
        }
    }

    /// Parses a single block at the given offset.
    fn parse_block_at(&self, data: &[u8], offset: usize) -> Option<EventBlock> {
        // @CBLK section format (all multi-byte values are little-endian):
        // 0x00: "@CBLK\0" (6 bytes)
        // 0x06: id (u16 LE)
        // 0x08: padding (8 bytes)
        // 0x10: name (16 bytes)
        // 0x20: unknown1 (4 bytes)
        // 0x24: unknown2 (4 bytes)
        // 0x28: track_count (u32 LE)
        // 0x2C: unknown3 (4 bytes)
        // 0x30: duration_frames? (4 bytes)
        // 0x34+: more header data
        // 0x40: track entries start (64 bytes from header)

        if offset + 64 > data.len() {
            return None;
        }

        let id = u16::from_le_bytes([data[offset + 6], data[offset + 7]]);
        let name = extract_string(&data[offset + 16..offset + 32]);

        // Track count is at offset 0x28 (40 bytes from start), little-endian
        let track_count = u32::from_le_bytes([
            data[offset + 40], data[offset + 41],
            data[offset + 42], data[offset + 43]
        ]);

        // Duration may be at offset 0x30 or 0x20, try both
        let duration_or_unknown = u32::from_le_bytes([
            data[offset + 48], data[offset + 49],
            data[offset + 50], data[offset + 51]
        ]);

        if name.is_empty() {
            return None;
        }

        // Parse track entries starting at offset 64 from @CBLK header
        let tracks = self.parse_block_tracks(data, offset + 64, track_count);

        // Calculate total duration from track entries if possible
        let duration_frames = if duration_or_unknown > 0 && duration_or_unknown < 0x10000000 {
            duration_or_unknown
        } else {
            // Try to derive duration from tracks
            tracks.iter()
                .filter_map(|t| t.duration_frames)
                .max()
                .unwrap_or(0)
        };

        Some(EventBlock {
            name,
            id,
            duration_frames,
            duration_seconds: duration_frames as f32 / 30.0,
            track_count,
            tracks,
        })
    }

    /// Parses track entries within a block.
    fn parse_block_tracks(&self, data: &[u8], start_offset: usize, count: u32) -> Vec<BlockTrack> {
        let mut tracks = Vec::new();
        let mut offset = start_offset;
        let mut track_index = 0u32;

        // Safety limit
        let max_tracks = count.min(500) as usize;

        while tracks.len() < max_tracks && offset + 8 <= data.len() {
            // Each track entry:
            // 0x00: size (u16 LE)
            // 0x02: type (u16 LE)
            // 0x04: flags (u32 LE)
            // 0x08+: type-specific data

            let size = u16::from_le_bytes([data[offset], data[offset + 1]]);
            let type_code = u16::from_le_bytes([data[offset + 2], data[offset + 3]]);

            // Sanity check - size should be reasonable (some tracks can be up to 512 bytes)
            if size < 8 || size > 512 || offset + size as usize > data.len() {
                break;
            }

            let flags = u32::from_le_bytes([
                data[offset + 4], data[offset + 5],
                data[offset + 6], data[offset + 7]
            ]);

            let track_type = TrackType::from_code(type_code);
            let entry_data = &data[offset + 8..offset + size as usize];

            // Parse type-specific data
            let (reference, float_values) = self.parse_track_data(entry_data, &track_type);

            // Try to extract frame timing
            let (start_frame, duration_frames) = self.extract_frame_timing(entry_data, &track_type);

            tracks.push(BlockTrack {
                size,
                track_type,
                type_code,
                flags,
                index: track_index,
                reference,
                start_frame,
                duration_frames,
                float_values,
            });

            track_index += 1;
            offset += size as usize;
        }

        tracks
    }

    /// Parses type-specific track data.
    fn parse_track_data(&self, data: &[u8], track_type: &TrackType) -> (Option<String>, Vec<f32>) {
        let mut reference = None;
        let mut float_values = Vec::new();

        match track_type {
            TrackType::MotionSet | TrackType::MusicBus | TrackType::Dialogue => {
                // These types have string references
                // Look for readable strings in the data
                if let Some(s) = self.find_string_in_data(data) {
                    reference = Some(s);
                }
            }
            TrackType::Camera => {
                // Camera tracks contain float values (position, rotation, FOV, etc.)
                // Floats are typically at various offsets, look for valid float patterns
                float_values = self.extract_floats(data);
            }
            _ => {}
        }

        (reference, float_values)
    }

    /// Finds a readable string in track data.
    fn find_string_in_data(&self, data: &[u8]) -> Option<String> {
        // Look for patterns like "mset_", "chset_", "music_", "$e", "lbg_"
        let prefixes: &[&[u8]] = &[b"mset_", b"chset_", b"music_", b"$", b"lbg_", b"ev_"];

        for prefix in prefixes {
            if let Some(pos) = data.windows(prefix.len()).position(|w| w == *prefix) {
                let start = pos;
                let end = data[start..].iter()
                    .position(|&b| b == 0 || !b.is_ascii_graphic())
                    .map(|e| start + e)
                    .unwrap_or(data.len().min(start + 32));

                if end > start {
                    let s = String::from_utf8_lossy(&data[start..end]).to_string();
                    if s.len() >= 4 {
                        return Some(s);
                    }
                }
            }
        }

        None
    }

    /// Extracts float values from track data.
    fn extract_floats(&self, data: &[u8]) -> Vec<f32> {
        let mut floats = Vec::new();

        // Floats are typically at 4-byte aligned offsets
        for i in (0..data.len().saturating_sub(3)).step_by(4) {
            let bytes = [data[i], data[i + 1], data[i + 2], data[i + 3]];
            let f = f32::from_le_bytes(bytes);

            // Only keep reasonable float values (not NaN, not too large)
            if f.is_finite() && f.abs() < 10000.0 && f != 0.0 {
                floats.push(f);
            }
        }

        // Limit to first 8 floats
        floats.truncate(8);
        floats
    }

    /// Extracts frame timing from track data.
    fn extract_frame_timing(&self, data: &[u8], _track_type: &TrackType) -> (Option<u32>, Option<u32>) {
        // Frame timing is often in the first 8 bytes of entry data
        if data.len() < 8 {
            return (None, None);
        }

        // Pattern varies by type, but commonly:
        // - Start frame at offset 0 or 4 (u32 BE)
        // - Duration at offset 4 or 8

        let val0 = u32::from_be_bytes([data[0], data[1], data[2], data[3]]);
        let val1 = if data.len() >= 8 {
            u32::from_be_bytes([data[4], data[5], data[6], data[7]])
        } else {
            0
        };

        // Heuristic: reasonable frame values are < 0x100000 (about 30+ minutes at 30fps)
        let start = if val0 > 0 && val0 < 0x100000 {
            Some(val0)
        } else {
            None
        };

        let duration = if val1 > 0 && val1 < 0x10000 {
            Some(val1)
        } else {
            None
        };

        (start, duration)
    }

    /// Scans for and parses @CRES (resource) sections.
    fn parse_resources(&self, data: &[u8], meta: &mut EventMetadata) {
        let tag = b"@CRES\0";

        for pos in find_all_patterns(data, tag) {
            if let Some(resource) = self.parse_resource_at(data, pos) {
                // Avoid duplicates
                if !meta.resources.iter().any(|r| r.name == resource.name && r.resource_type == resource.resource_type) {
                    meta.resources.push(resource);
                }
            }
        }
    }

    /// Parses a single resource at the given offset.
    fn parse_resource_at(&self, data: &[u8], offset: usize) -> Option<EventResource> {
        // @CRES section format:
        // 0x00: "@CRES\0" (6 bytes)
        // 0x06: flags (2 bytes)
        // 0x08: count (2 bytes)
        // 0x0A: type flags (2 bytes)
        // 0x0C: reserved (4 bytes)
        // 0x10: resource type name (16 bytes)

        if offset + 32 > data.len() {
            return None;
        }

        let resource_type = extract_string(&data[offset + 16..offset + 32]);

        if resource_type.is_empty() {
            return None;
        }

        // Try to get the resource name (usually follows the type)
        let name_offset = offset + 32;
        let name = if name_offset + 16 <= data.len() {
            extract_string(&data[name_offset..name_offset + 16])
        } else {
            resource_type.clone()
        };

        Some(EventResource {
            name,
            resource_type,
            external_hash: None,
        })
    }
}

/// Finds all occurrences of a pattern in data.
fn find_all_patterns(data: &[u8], pattern: &[u8]) -> Vec<usize> {
    let mut positions = Vec::new();

    for i in 0..data.len().saturating_sub(pattern.len()) {
        if &data[i..i + pattern.len()] == pattern {
            positions.push(i);
        }
    }

    positions
}

/// Counts all SEDBSCB section types in the data.
fn count_sections(data: &[u8]) -> SectionCounts {
    let mut counts = SectionCounts::default();

    // Count each section tag
    counts.crst = find_all_patterns(data, b"@CRST\0").len() as u32;
    counts.cres = find_all_patterns(data, b"@CRES\0").len() as u32;
    counts.catt = find_all_patterns(data, b"@CATT\0").len() as u32;
    counts.ccpt = find_all_patterns(data, b"@CCPT\0").len() as u32;
    counts.cact = find_all_patterns(data, b"@CACT\0").len() as u32;
    counts.cdpt = find_all_patterns(data, b"@CDPT\0").len() as u32;
    counts.ctrk = find_all_patterns(data, b"@CTRK\0").len() as u32;
    counts.cbkt = find_all_patterns(data, b"@CBKT\0").len() as u32;
    counts.cblk = find_all_patterns(data, b"@CBLK\0").len() as u32;

    counts
}

/// Extracts a null-terminated string from bytes.
fn extract_string(data: &[u8]) -> String {
    let end = data.iter().position(|&b| b == 0).unwrap_or(data.len());
    let bytes = &data[..end];

    // Check if it's valid ASCII first (common case for block names like "c01", "c02")
    if bytes.iter().all(|&b| b.is_ascii() && b != 0) {
        return String::from_utf8_lossy(bytes).trim().to_string();
    }

    // Try Shift-JIS decoding for Japanese text
    if let Some(decoded) = decode_shift_jis(bytes) {
        return decoded;
    }

    // Fallback: UTF-8 lossy
    String::from_utf8_lossy(bytes).trim().to_string()
}

/// Attempts to decode Shift-JIS encoded bytes to a String.
fn decode_shift_jis(data: &[u8]) -> Option<String> {
    // Simple Shift-JIS decoder for katakana/hiragana (83xx range)
    // This is a minimal implementation for common FF13 text
    let mut result = String::new();
    let mut i = 0;

    while i < data.len() {
        let b1 = data[i];

        // ASCII range
        if b1 < 0x80 {
            if b1 == 0 {
                break;
            }
            result.push(b1 as char);
            i += 1;
            continue;
        }

        // Shift-JIS double-byte character
        if i + 1 >= data.len() {
            return None; // Incomplete sequence
        }

        let b2 = data[i + 1];

        // Katakana range (8340-839F)
        if b1 == 0x83 && (0x40..=0x9F).contains(&b2) {
            // Map to Unicode katakana (U+30A0 range)
            let offset = if b2 >= 0x80 { b2 - 0x41 } else { b2 - 0x40 };
            let unicode = 0x30A0 + offset as u32;
            if let Some(c) = char::from_u32(unicode) {
                result.push(c);
            } else {
                return None;
            }
        }
        // Hiragana range (829F-82F1)
        else if b1 == 0x82 && (0x9F..=0xF1).contains(&b2) {
            let offset = b2 - 0x9F;
            let unicode = 0x3040 + offset as u32;
            if let Some(c) = char::from_u32(unicode) {
                result.push(c);
            } else {
                return None;
            }
        }
        // Other Shift-JIS - mark as [JP]
        else if (0x81..=0x9F).contains(&b1) || (0xE0..=0xFC).contains(&b1) {
            // Unknown double-byte - skip but continue
            result.push('?');
        } else {
            // Invalid sequence
            return None;
        }

        i += 2;
    }

    if result.is_empty() || result.chars().all(|c| c == '?') {
        return None;
    }

    Some(result)
}

/// Classifies an actor by its name.
fn classify_actor(name: &str) -> ActorType {
    if name.starts_with("CameraActor_") {
        ActorType::Camera
    } else if name.starts_with("SoundActor_") {
        ActorType::Sound
    } else if name.starts_with("EffectActor_") {
        ActorType::Effect
    } else if name.starts_with("BgmActor_") {
        ActorType::Bgm
    } else if name.starts_with("ProxyActor_") {
        ActorType::Proxy
    } else if name.starts_with("System_") {
        ActorType::System
    } else if is_character_name(name) {
        ActorType::Character(name.to_string())
    } else {
        ActorType::Unknown(name.to_string())
    }
}

/// Checks if a name looks like a character name.
fn is_character_name(name: &str) -> bool {
    // Known character prefixes and names
    let known_chars = [
        "lightning", "p_lt", "snow", "p_sn", "vanille", "p_va",
        "hope", "p_hp", "sazh", "p_sz", "fang", "p_fn",
        "serah", "noel", "caius", "yeul"
    ];

    let lower = name.to_lowercase();
    known_chars.iter().any(|c| lower.contains(c))
}

// ============================================================
// DataSet Directory Parsing
// ============================================================

use std::path::Path;
use std::fs;

/// Reads an event from a directory (containing bin/ and optionally DataSet/).
///
/// The directory structure should be:
/// ```text
/// ev_xxxx_xxx/
/// ├── bin/
/// │   └── ev_xxxx_xxx.white.win32.xwb
/// └── DataSet/  (optional)
///     ├── a00.white.win32.bin
///     ├── a01.white.win32.bin
///     └── ...
/// ```
pub fn read_event_directory(dir_path: &str) -> Result<EventMetadata> {
    let path = Path::new(dir_path);

    if !path.is_dir() {
        anyhow::bail!("Path is not a directory: {}", dir_path);
    }

    // Find the schedule XWB in bin/ subdirectory
    let bin_dir = path.join("bin");
    let xwb_path = if bin_dir.is_dir() {
        // Look for .xwb file in bin/
        find_xwb_in_dir(&bin_dir)?
    } else {
        // Maybe the path itself contains the xwb
        find_xwb_in_dir(path)?
    };

    // Parse the main schedule
    let file = fs::File::open(&xwb_path)
        .with_context(|| format!("Failed to open XWB: {}", xwb_path.display()))?;
    let mut reader = EventReader::new(std::io::BufReader::new(file));
    let mut meta = reader.read_event()?;

    // Set metadata
    meta.source_path = xwb_path.to_string_lossy().to_string();
    meta.file_size = fs::metadata(&xwb_path)?.len();
    meta.name = path.file_name()
        .map(|n| n.to_string_lossy().to_string())
        .unwrap_or_else(|| "unknown".to_string());

    // Parse DataSet if present
    let dataset_dir = path.join("DataSet");
    if dataset_dir.is_dir() {
        meta.dataset = Some(parse_dataset_directory(&dataset_dir)?);
    }

    Ok(meta)
}

/// Finds the first .xwb file in a directory.
fn find_xwb_in_dir(dir: &Path) -> Result<std::path::PathBuf> {
    for entry in fs::read_dir(dir)? {
        let entry = entry?;
        let path = entry.path();
        if path.extension().map(|e| e == "xwb").unwrap_or(false) {
            return Ok(path);
        }
    }
    anyhow::bail!("No .xwb file found in directory: {}", dir.display())
}

/// Parses all DataSet/*.bin files.
fn parse_dataset_directory(dataset_dir: &Path) -> Result<EventDataSet> {
    let mut dataset = EventDataSet::default();

    for entry in fs::read_dir(dataset_dir)? {
        let entry = entry?;
        let path = entry.path();

        // Only process .bin files
        if !path.extension().map(|e| e == "bin").unwrap_or(false) {
            continue;
        }

        let filename = path.file_name()
            .map(|n| n.to_string_lossy().to_string())
            .unwrap_or_default();

        log::debug!("Parsing DataSet file: {}", filename);

        match parse_dataset_bin(&path, &filename) {
            Ok((motions, cameras)) => {
                dataset.source_files.push(filename);
                dataset.motion_blocks.extend(motions);
                dataset.camera_blocks.extend(cameras);
            }
            Err(e) => {
                log::warn!("Failed to parse DataSet file {}: {}", filename, e);
            }
        }
    }

    Ok(dataset)
}

/// Parses a single DataSet bin file (WPD container with mcb/ccb records).
fn parse_dataset_bin(path: &Path, source_file: &str) -> Result<(Vec<MotionControlBlock>, Vec<CameraControlBlock>)> {
    let data = fs::read(path)?;

    // It's a WPD container
    let mut cursor = std::io::Cursor::new(&data);
    let mut wpd_reader = WpdReader::new(&mut cursor);

    let header = wpd_reader.read_header()?;
    let records = wpd_reader.read_records(&header)?;

    let mut motion_blocks = Vec::new();
    let mut camera_blocks = Vec::new();

    for record in &records {
        match record.extension.as_str() {
            "mcb" => {
                // Motion Control Block
                if let Some(mcb) = parse_mcb_header(&record.data, &record.name, source_file) {
                    motion_blocks.push(mcb);
                }
            }
            "ccb" => {
                // Camera Control Block
                if let Some(ccb) = parse_ccb_header(&record.data, &record.name, source_file) {
                    camera_blocks.push(ccb);
                }
            }
            _ => {
                log::debug!("Skipping DataSet record: {} ({})", record.name, record.extension);
            }
        }
    }

    Ok((motion_blocks, camera_blocks))
}

/// Parses SEDBMCB header from motion control block data.
fn parse_mcb_header(data: &[u8], name: &str, source_file: &str) -> Option<MotionControlBlock> {
    // SEDBMCB format:
    // 0x00: "SEDBMCB\0" (8 bytes)
    // 0x08: version (u16)
    // 0x0A: flags (u16)
    // 0x0C: unknown (4 bytes)
    // 0x10: header_size (u32)
    // 0x14: data_size (u32)

    if data.len() < 24 {
        return None;
    }

    if &data[0..8] != b"SEDBMCB\0" {
        log::debug!("Not a valid SEDBMCB: {}", name);
        return None;
    }

    let version = u16::from_be_bytes([data[8], data[9]]);
    let flags = u16::from_be_bytes([data[10], data[11]]);
    let header_size = u32::from_be_bytes([data[16], data[17], data[18], data[19]]);
    let data_size = u32::from_be_bytes([data[20], data[21], data[22], data[23]]);

    Some(MotionControlBlock {
        name: name.to_string(),
        source_file: source_file.to_string(),
        header_size,
        data_size,
        version,
        flags,
    })
}

/// Parses SEDBCCB header from camera control block data.
fn parse_ccb_header(data: &[u8], name: &str, source_file: &str) -> Option<CameraControlBlock> {
    // SEDBCCB format:
    // 0x00: "SEDBCCB\0" (8 bytes)
    // 0x08: unknown (4 bytes)
    // 0x0C: flags (u32)
    // 0x10: header_size (u32)
    // 0x14: data_size (u32)

    if data.len() < 24 {
        return None;
    }

    if &data[0..8] != b"SEDBCCB\0" {
        log::debug!("Not a valid SEDBCCB: {}", name);
        return None;
    }

    let flags = u32::from_be_bytes([data[12], data[13], data[14], data[15]]);
    let header_size = u32::from_be_bytes([data[16], data[17], data[18], data[19]]);
    let data_size = u32::from_be_bytes([data[20], data[21], data[22], data[23]]);

    Some(CameraControlBlock {
        name: name.to_string(),
        source_file: source_file.to_string(),
        header_size,
        data_size,
        flags,
    })
}
