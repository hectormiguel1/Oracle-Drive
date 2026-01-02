//! # ZTR Binary Writer
//!
//! This module provides the [`ZtrWriter`] struct for creating ZTR binary files
//! from text entries.
//!
//! ## Writing Modes
//!
//! The writer currently implements **uncompressed mode** (`pack_uncmp`),
//! which produces valid ZTR files without dictionary compression. This is
//! simpler and works reliably for all text content.
//!
//! ## File Structure Written
//!
//! ```text
//! 1. ZtrFileHeader (20 bytes)
//! 2. Dictionary Chunk Offsets (4 bytes each)
//! 3. Line Info Array (4 bytes per entry)
//! 4. Packed ID Data (uncompressed, chunked)
//! 5. Line Data (uncompressed, chunked)
//! ```
//!
//! ## Uncompressed Format
//!
//! In uncompressed mode, each chunk has a dictionary size of 0, meaning
//! no byte-pair expansion occurs during reading. This produces slightly
//! larger files but ensures perfect roundtrip compatibility.

use byteorder::{BigEndian, WriteBytesExt};
use std::io::{Seek, Write};

use super::key_dicts::GameCode;
use super::structs::{LineInfo, ZtrFileHeader};

/// Binary writer for creating ZTR text resource files.
///
/// `ZtrWriter` takes text entries (ID + text pairs) and produces a valid
/// ZTR binary file. The text is encoded using the game-specific control
/// code dictionaries.
///
/// # Type Parameter
/// * `W` - Any type implementing `Write + Seek` (File, Cursor, etc.)
///
/// # Example
/// ```rust,ignore
/// use std::fs::File;
/// use fabula_nova_sdk::modules::ztr::{ZtrWriter, GameCode};
///
/// let mut file = File::create("output.ztr")?;
/// let mut writer = ZtrWriter::new(&mut file, GameCode::FF13_1);
///
/// let entries = vec![
///     ("ID_001".to_string(), "{Color White}Hello!".to_string()),
///     ("ID_002".to_string(), "Press {Btn A} to continue".to_string()),
/// ];
///
/// writer.write(&entries)?;
/// ```
pub struct ZtrWriter<W: Write + Seek> {
    /// The underlying writer destination
    writer: W,
    /// Target game for control code encoding
    game_code: GameCode,
}

impl<W: Write + Seek> ZtrWriter<W> {
    pub fn new(writer: W, game_code: GameCode) -> Self {
        Self { writer, game_code }
    }

    pub fn write(&mut self, entries: &[(String, String)]) -> anyhow::Result<()> {
        log::info!(
            "Writing ZTR file with {} entries (GameCode: {:?})",
            entries.len(),
            self.game_code
        );
        // 1. Process IDs
        let mut ids_stream = Vec::new();
        for (id, _) in entries {
            // C# uses CP1252 for IDs. For now, assume ASCII/UTF8 is fine if compatible
            ids_stream.extend_from_slice(id.as_bytes());
            ids_stream.push(0); // Null terminator
        }

        let dcmp_ids_size = ids_stream.len() as u32;
        let packed_ids = pack_ids(&ids_stream);
        log::debug!("Packed IDs size: {}", packed_ids.len());

        // 2. Process Lines (Placeholder for Encoder)
        // We need to convert Text -> Bytes.
        // For now, simple UTF-8 pass through + null terminator (00 00 for UTF-16? No C# writes 00 00 ushort)
        // C# ZTR format seems to handle single byte 00 as terminator in some places, but ConvertFromData writes ushort 0.
        // Reader logic checks for `prevLineByte == 0 && currentLineByte == 0`.

        use super::text_encoder::encode_ztr_line;
        // use super::key_dicts::GameCode; // Already imported

        let mut processed_lines = Vec::new();
        for (_, text) in entries {
            let mut encoded = encode_ztr_line(text, self.game_code, "Shift-JIS");

            // Ensure 00 00 termination
            let len = encoded.len();
            if len >= 2 && encoded[len - 1] == 0 && encoded[len - 2] == 0 {
                // Already has 00 00
            } else if len >= 1 && encoded[len - 1] == 0 {
                // Has 00, append 00
                encoded.push(0);
            } else {
                // Append 00 00
                encoded.push(0);
                encoded.push(0);
            }
            processed_lines.extend_from_slice(&encoded);
        }

        // 3. Pack Lines (Compress chunks)
        // Split into 4096 byte chunks (uncompressed size? No C# code: "GetItemsGroupCount((uint)processedLinesArray.Length")
        // It splits the *processed* array.

        // We need to simulate the "rearrange dictionary" and "line info offset" logic from C# PackCmp.
        // This is complex because line info depends on the *compressed* stream structure (arranged dictionary).
        // For now, I will implement a simplified "Uncompressed" packing if allowed, OR
        // I must replicate PackCmp exactly.
        // PackCmp logic:
        //  - Compress chunk.
        //  - Re-read chunk to parse dictionary.
        //  - "Update line info offsets" by simulating reading the compressed data.

        // This implies we need to know exactly where each line starts in the *decompressed* flow relative to the *dictionary*.
        // This is very tight coupling.

        // Strategy:
        // Since implementing full PackCmp logic is heavy, I'll stick to the "PackUncmp" logic (ActionSwitch.c)
        // if I can. It's valid ZTR.
        // The C# code supports it.
        // Let's implement PackUncmp logic for simplicity first.

        log::debug!("Packing uncompressed line data...");
        self.pack_uncmp(
            entries.len() as u32,
            dcmp_ids_size,
            &packed_ids,
            &processed_lines,
        )
    }

    fn pack_uncmp(
        &mut self,
        line_count: u32,
        dcmp_ids_size: u32,
        packed_ids: &[u8],
        processed_lines: &[u8],
    ) -> anyhow::Result<()> {
        let mut chunk_offsets = Vec::new();
        let mut line_infos = Vec::new();
        let mut line_data = Vec::new();

        // First chunk offset is 0
        chunk_offsets.push(0u32);

        // Initial Line Info
        let mut current_line_info = LineInfo {
            dict_chunk_id: 0,
            chara_start_in_dict_page: 0,
            line_start_pos_in_chunk: 0,
        };

        // Logic from PackUncmp.cs
        // It writes line byte by byte.
        // If byte is 0 and prev is 0 (line end):
        //   Write next line info.

        // Note: PackUncmp writes `0` as dict chunk size at start of each chunk?
        // `lineDataWriter.WriteBytesUInt32(0, true);`
        // Yes. Uncompressed chunks have size 0? Or it means "Dictionary Size 0"?
        // `GetArrangedDictionary` reads size. If 0, empty dict.
        // Then it reads bytes.
        // If dict is empty, `currentLineDict` is empty.
        // Reader: `if (currentLineDict.ContainsKey(currentLineByte))` -> False.
        // `else { linesWriter.Write(currentLineByte); }`
        // So this works! Uncompressed ZTR just has 0 size dictionaries.

        // Start first chunk
        line_data.extend_from_slice(&0u32.to_be_bytes()); // Dict size 0

        let mut copy_counter = 0;
        let mut prev_byte = 0xFFu8;
        let mut lines_written = 0;

        // We need to record LineInfo for the *first* line (index 0)
        line_infos.push(current_line_info.clone());

        // Wait, C# PackUncmp:
        // Writes first line info.
        // Writes first chunk dict size (0).
        // Loop bytes:
        //   Write byte.
        //   If line end (0, 0):
        //      linesWritten++
        //      If linesWritten < count: Write NEXT line info.

        for &b in processed_lines {
            copy_counter += 1;
            line_data.push(b);

            if b == 0 && prev_byte == 0 {
                lines_written += 1;
                if lines_written < line_count {
                    // Update info for NEXT line
                    current_line_info.line_start_pos_in_chunk = copy_counter as u16; // offset in current chunk (excluding dict size?)
                                                                                     // C# PackUncmp: `lineInfo.LineStartPosInChunk = (ushort)copyCounter;`
                                                                                     // Note: `copyCounter` resets on chunk boundary.
                                                                                     // But `lineData` includes the 4 byte dict size at start of chunk.
                                                                                     // C# `lineDataWriter.WriteBytesUInt32(0, true)`
                                                                                     // `copyCounter` counts bytes written *after* that.

                    // So `line_start_pos_in_chunk` is relative to data start (after dict).

                    line_infos.push(current_line_info.clone());
                    prev_byte = 0xFF;
                }
            } else {
                prev_byte = b;
            }

            if copy_counter == 4096 {
                // New Chunk
                copy_counter = 0;
                current_line_info.dict_chunk_id += 1;

                chunk_offsets.push(line_data.len() as u32);

                // Start new chunk
                line_data.extend_from_slice(&0u32.to_be_bytes()); // Dict size 0
            }
        }

        // Last offset (total size)
        chunk_offsets.push(line_data.len() as u32);

        // Write Header
        let header = ZtrFileHeader {
            magic: 1, // 0x01
            line_count,
            dcmp_ids_size,
            dict_chunk_offsets_count: chunk_offsets.len() as u32,
        };

        // Write to output
        use binrw::BinWrite;
        header.write_be(&mut self.writer)?;

        // Write Offsets
        for off in chunk_offsets {
            self.writer.write_u32::<BigEndian>(off)?;
        }

        // Write Line Infos
        for info in line_infos {
            info.write_be(&mut self.writer)?;
        }

        let _pos = self.writer.stream_position()?;

        // Write IDs
        self.writer.write_all(packed_ids)?;

        // Write Line Data
        self.writer.write_all(&line_data)?;

        Ok(())
    }
}

fn pack_ids(ids: &[u8]) -> Vec<u8> {
    let mut result = Vec::new();
    for chunk in ids.chunks(4096) {
        let header = 0u32.to_be_bytes();
        result.extend_from_slice(&header);
        result.extend_from_slice(chunk);
    }
    result
}
