//! # Event Module
//!
//! This module provides parsing and extraction for Event files (cutscene schedules).
//!
//! Event files (`.white.win32.xwb`) are WPD containers that hold cutscene data
//! for the Final Fantasy XIII trilogy. They contain:
//!
//! - Schedule data (SEDBSCB format) defining actors, blocks, and timing
//! - Sound resource info (SRB format)
//! - External resource references
//! - Dialogue entry references
//!
//! ## Quick Start
//!
//! ```rust,ignore
//! use fabula_nova_sdk::modules::event;
//!
//! // Parse metadata without extracting
//! let meta = event::parse_event_metadata("ev_ddaa_080.white.win32.xwb")?;
//! println!("Event: {}", meta.name);
//! println!("Actors: {:?}", meta.actors);
//!
//! // Extract to directory
//! let result = event::extract_event("ev_ddaa_080.white.win32.xwb", "./output")?;
//! ```
//!
//! ## Module Structure
//!
//! - [`api`] - High-level API functions
//! - [`reader`] - Binary parsing implementation
//! - [`structs`] - Data structures

pub mod api;
pub mod reader;
pub mod structs;

// Re-export main API functions
pub use api::{
    parse_event_metadata,
    parse_event_metadata_bytes,
    parse_event_directory,
    extract_event,
    get_event_summary,
    parse_event_to_json,
};

// Re-export main types
pub use structs::{
    EventMetadata,
    EventSummary,
    EventActor,
    EventBlock,
    EventResource,
    SoundBlock,
    DialogueEntry,
    ExtractedEvent,
    ActorType,
    EventDataSet,
    MotionControlBlock,
    CameraControlBlock,
};

#[cfg(test)]
mod tests {
    use super::*;
    use std::path::Path;

    const SAMPLE_DIR: &str = "/home/hectorr/Development/Flutter/Oracle-Drive/ai_resources/event/schedule";

    #[test]
    fn test_parse_event_small() {
        let path = format!("{}/ev_comn_250/bin/ev_comn_250.white.win32.xwb", SAMPLE_DIR);
        if !Path::new(&path).exists() {
            println!("Skipping test: sample file not found at {}", path);
            return;
        }

        let meta = parse_event_metadata(&path).expect("Failed to parse event");

        println!("Event: {}", meta.name);
        println!("  Records: {}", meta.record_count);
        println!("  Actors: {}", meta.actors.len());
        for actor in &meta.actors {
            println!("    - {} ({:?})", actor.name, actor.actor_type);
        }
        println!("  Blocks: {}", meta.blocks.len());
        for block in &meta.blocks {
            println!("    - {} ({} frames = {:.2}s)", block.name, block.duration_frames, block.duration_seconds);
        }
        println!("  Resources: {}", meta.resources.len());
        println!("  Sound blocks: {}", meta.sound_blocks.len());
        println!("  Dialogue entries: {}", meta.dialogue_entries.len());

        // Basic assertions
        assert!(!meta.name.is_empty());
        assert!(meta.record_count > 0);
    }

    #[test]
    fn test_parse_event_medium() {
        let path = format!("{}/ev_ddaa_080/bin/ev_ddaa_080.white.win32.xwb", SAMPLE_DIR);
        if !Path::new(&path).exists() {
            println!("Skipping test: sample file not found at {}", path);
            return;
        }

        let meta = parse_event_metadata(&path).expect("Failed to parse event");

        println!("\nEvent: {}", meta.name);
        println!("  Records: {}", meta.record_count);
        println!("  Actors: {}", meta.actors.len());
        println!("  Blocks: {}", meta.blocks.len());
        println!("  Resources: {}", meta.resources.len());
        println!("  Sound blocks: {}", meta.sound_blocks.len());
        println!("  Dialogue entries: {}", meta.dialogue_entries.len());

        // Medium event should have dialogue
        assert!(meta.dialogue_entries.len() > 0, "Expected dialogue entries");

        for entry in &meta.dialogue_entries {
            println!("    Dialogue: {} -> {} (raw: {})", entry.record_name, entry.ztr_key, entry.raw_content);
        }
    }

    #[test]
    fn test_event_summary() {
        let path = format!("{}/ev_comn_250/bin/ev_comn_250.white.win32.xwb", SAMPLE_DIR);
        if !Path::new(&path).exists() {
            println!("Skipping test: sample file not found");
            return;
        }

        let summary = get_event_summary(&path).expect("Failed to get summary");
        println!("Summary: {:?}", summary);

        assert!(!summary.name.is_empty());
    }

    #[test]
    fn test_parse_all_samples() {
        if !Path::new(SAMPLE_DIR).exists() {
            println!("Skipping test: sample directory not found");
            return;
        }

        let mut success = 0;
        let mut failures = Vec::new();

        for entry in std::fs::read_dir(SAMPLE_DIR).unwrap() {
            let entry = entry.unwrap();
            let path = entry.path();
            if path.is_dir() {
                let xwb_pattern = path.join("bin").join("*.xwb");
                for xwb_entry in glob::glob(xwb_pattern.to_str().unwrap()).unwrap() {
                    if let Ok(xwb_path) = xwb_entry {
                        match parse_event_metadata(&xwb_path) {
                            Ok(meta) => {
                                success += 1;
                                println!("OK: {} ({} actors, {} blocks)",
                                    meta.name, meta.actors.len(), meta.blocks.len());
                            }
                            Err(e) => {
                                failures.push((xwb_path.display().to_string(), e.to_string()));
                            }
                        }
                    }
                }
            }
        }

        println!("\nParsed {} events successfully", success);
        if !failures.is_empty() {
            println!("Failures:");
            for (path, err) in &failures {
                println!("  {}: {}", path, err);
            }
        }

        assert!(success > 0, "Expected at least some events to parse");
        assert!(failures.is_empty(), "Some events failed to parse");
    }

    #[test]
    fn test_parse_directory_with_dataset() {
        // Find an event with DataSet folder
        let dir_with_dataset = format!("{}/ev_yuaa_360", SAMPLE_DIR);
        if !Path::new(&dir_with_dataset).exists() {
            println!("Skipping test: sample with DataSet not found at {}", dir_with_dataset);
            return;
        }

        let meta = parse_event_directory(&dir_with_dataset).expect("Failed to parse event directory");

        println!("\nEvent Directory: {}", meta.name);
        println!("  Actors: {}", meta.actors.len());
        println!("  Blocks: {}", meta.blocks.len());
        println!("  Dialogue entries: {}", meta.dialogue_entries.len());

        if let Some(dataset) = &meta.dataset {
            println!("  DataSet:");
            println!("    Source files: {:?}", dataset.source_files);
            println!("    Motion blocks: {}", dataset.motion_blocks.len());
            println!("    Camera blocks: {}", dataset.camera_blocks.len());

            for mcb in dataset.motion_blocks.iter().take(3) {
                println!("      MCB: {} (v{}, flags={}, size={})",
                    mcb.name, mcb.version, mcb.flags, mcb.data_size);
            }
            for ccb in dataset.camera_blocks.iter().take(3) {
                println!("      CCB: {} (flags={}, size={})",
                    ccb.name, ccb.flags, ccb.data_size);
            }

            assert!(!dataset.motion_blocks.is_empty() || !dataset.camera_blocks.is_empty(),
                "Expected at least some motion or camera blocks");
        } else {
            println!("  No DataSet found");
        }
    }

    #[test]
    fn test_new_metadata_fields() {
        let path = format!("{}/ev_ddaa_080/bin/ev_ddaa_080.white.win32.xwb", SAMPLE_DIR);
        if !Path::new(&path).exists() {
            println!("Skipping test: sample file not found at {}", path);
            return;
        }

        let meta = parse_event_metadata(&path).expect("Failed to parse event");

        println!("\n=== New Event Metadata Fields Test ===");

        // Test WPD records info
        println!("\nWPD Records ({}):", meta.wpd_records.len());
        for rec in &meta.wpd_records {
            println!("  {} ({}) @ 0x{:X}, {} bytes", rec.name, rec.extension, rec.offset, rec.size);
        }
        assert!(!meta.wpd_records.is_empty(), "Expected WPD records");

        // Test schedule header
        println!("\nSchedule Header:");
        if let Some(hdr) = &meta.schedule_header {
            println!("  Magic: {}", hdr.magic);
            println!("  Version: {}", hdr.version);
            println!("  Header size: 0x{:X}", hdr.header_size);
            println!("  Data size: 0x{:X}", hdr.data_size);
            assert_eq!(hdr.magic, "SEDBSCB");
        } else {
            panic!("Expected schedule header");
        }

        // Test section counts
        println!("\nSection Counts:");
        println!("  @CRST: {}", meta.section_counts.crst);
        println!("  @CRES: {}", meta.section_counts.cres);
        println!("  @CACT: {}", meta.section_counts.cact);
        println!("  @CBLK: {}", meta.section_counts.cblk);
        println!("  @CTRK: {}", meta.section_counts.ctrk);
        // At least some sections should be found
        let total_sections = meta.section_counts.crst + meta.section_counts.cres +
            meta.section_counts.cact + meta.section_counts.cblk;
        assert!(total_sections > 0, "Expected some section counts");

        // Test external resources
        println!("\nExternal Resources ({}):", meta.external_resources.len());
        for res in meta.external_resources.iter().take(5) {
            println!("  {} -> {} ({:?})", res.name, res.hash, res.category);
        }
        if meta.external_resources.len() > 5 {
            println!("  ... and {} more", meta.external_resources.len() - 5);
        }

        // Test sound references
        println!("\nSound References ({}):", meta.sound_references.len());
        for snd in &meta.sound_references {
            println!("  {} ({:?}) in block '{}'", snd.sound_id, snd.sound_type, snd.block_name);
        }

        println!("\n=== All new fields populated successfully ===");
    }
}
