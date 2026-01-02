//! # WPD Module - Package Container Handler
//!
//! This module handles WPD (WhiteBin Package) files, which are simpler container
//! formats used for grouping related resources. WPD is used for shader packages,
//! database bundles, and image collections.
//!
//! ## WPD vs WBT
//!
//! | Feature       | WPD                    | WBT                    |
//! |---------------|------------------------|------------------------|
//! | Compression   | None (raw data)        | ZLIB compressed        |
//! | Encryption    | None                   | Encrypted filelist     |
//! | Use Case      | Small packages         | Large archives         |
//! | File Count    | Typically < 100        | Thousands              |
//!
//! ## File Format
//!
//! ```text
//! ┌─────────────────────────────────────────────────────────────┐
//! │ Header (8 bytes)                                             │
//! │   - Magic: "WPD\0" (4 bytes)                                 │
//! │   - Record Count (u32)                                       │
//! ├─────────────────────────────────────────────────────────────┤
//! │ Record Headers (32 bytes each)                               │
//! │   - Name (16 bytes, null-padded)                             │
//! │   - Offset (u32)                                             │
//! │   - Length (u32)                                             │
//! │   - Padding (8 bytes)                                        │
//! ├─────────────────────────────────────────────────────────────┤
//! │ Record Data                                                  │
//! │   - Raw file data at specified offsets                       │
//! └─────────────────────────────────────────────────────────────┘
//! ```
//!
//! ## IMGB Integration
//!
//! WPD files with `.xgr` or `.txbh` extensions often have paired `.imgb` files
//! containing image data. The module automatically extracts these as DDS files.
//!
//! ## Submodules
//!
//! - [`structs`] - Data structures for WPD files
//! - [`reader`] - Binary WPD parser
//! - [`writer`] - Binary WPD generator
//! - [`api`] - High-level public API
//!
//! ## Usage Example
//!
//! ```rust,ignore
//! use fabula_nova_sdk::modules::wpd;
//!
//! // Unpack WPD to directory
//! wpd::unpack_wpd("shader.wpd", "output/")?;
//!
//! // Repack from directory
//! wpd::repack_wpd("output/", "shader_modified.wpd")?;
//! ```

pub mod structs;
pub mod reader;
pub mod writer;
pub mod api;

// Re-export all public items
pub use structs::*;
pub use reader::*;
pub use writer::*;
pub use api::*;

#[cfg(test)]
mod tests {
    use std::path::PathBuf;
    use super::api::unpack_wpd;

    #[test]
    fn test_unpack_wpd_crystal_fang() {
        let mut d = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
        d.push("ai_resources/WDBJsonTool/WDBJsonTool/crystal_fang.wdb");
        let wdb_path = d;
        
        let mut out_dir = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
        out_dir.push("target/test_wpd_unpack");
        
        if !wdb_path.exists() {
            eprintln!("Test file not found: {:?}", wdb_path);
            return;
        }
        
        // Ensure out_dir is clean
        if out_dir.exists() {
            let _ = std::fs::remove_dir_all(&out_dir);
        }
        
        let result = unpack_wpd(&wdb_path, &out_dir);
        assert!(result.is_ok(), "Failed to unpack WPD: {:?}", result.err());
        
        // Verify some files exist
        // WDB files have sections starting with !!
        // crystal_fang.wdb should have !!string, !!strtypelist etc.
        assert!(out_dir.join("!!string").exists());
        assert!(out_dir.join("!!strtypelist").exists());
    }

    #[test]
    fn test_wpd_roundtrip() {
        use super::api::{unpack_wpd, repack_wpd};
        let mut d = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
        d.push("ai_resources/WDBJsonTool/WDBJsonTool/crystal_fang.wdb");
        let wdb_path = d;
        
        let mut out_dir = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
        out_dir.push("target/test_wpd_roundtrip_dir");
        
        let mut repack_path = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
        repack_path.push("target/test_wpd_repacked.wdb");

        if !wdb_path.exists() { return; }
        
        if out_dir.exists() { let _ = std::fs::remove_dir_all(&out_dir); }
        if repack_path.exists() { let _ = std::fs::remove_file(&repack_path); }

        unpack_wpd(&wdb_path, &out_dir).unwrap();
        repack_wpd(&out_dir, &repack_path).unwrap();

        assert!(repack_path.exists());
        
        // Verify size is similar (might differ slightly due to padding if original wasn't 4-byte aligned at end)
        let original_size = std::fs::metadata(&wdb_path).unwrap().len();
        let repacked_size = std::fs::metadata(&repack_path).unwrap().len();
        
        println!("Original: {}, Repacked: {}", original_size, repacked_size);
        // They should be very close.
        assert!((repacked_size as i64 - original_size as i64).abs() < 32);
    }

    #[test]
    fn test_wpd_full_roundtrip_with_imgb() {
        use super::api::{unpack_wpd, repack_wpd};
        let mut d = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
        d.push("ai_resources/WPD.Lib/example_files/crystal.win32.xgr");
        let wpd_path = d;

        let mut out_dir = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
        out_dir.push("target/test_wpd_imgb_dir");

        let mut repack_path = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
        repack_path.push("target/test_crystal_repacked.win32.xgr");

        if !wpd_path.exists() { return; }

        if out_dir.exists() { let _ = std::fs::remove_dir_all(&out_dir); }
        if repack_path.exists() { let _ = std::fs::remove_file(&repack_path); }

        // Unpack (should also extract DDS if logic is correct and trb/gtex files are present)
        unpack_wpd(&wpd_path, &out_dir).expect("Failed to unpack WPD with IMGB");

        // Check if any DDS was created (crystal.win32.xgr contains trb files which are images)
        let mut dds_found = false;
        for entry in std::fs::read_dir(&out_dir).unwrap() {
            let entry = entry.unwrap();
            if entry.path().extension().map_or(false, |ext| ext == "dds") {
                dds_found = true;
                break;
            }
        }
        assert!(dds_found, "No DDS files were extracted from IMGB");

        // Repack
        repack_wpd(&out_dir, &repack_path).expect("Failed to repack WPD with IMGB");

        assert!(repack_path.exists());

        let original_size = std::fs::metadata(&wpd_path).unwrap().len();
        let repacked_size = std::fs::metadata(&repack_path).unwrap().len();

        println!("Full Roundtrip - Original: {}, Repacked: {}", original_size, repacked_size);
        assert!((repacked_size as i64 - original_size as i64).abs() < 64);
    }

    /// Test WPD roundtrip with wdbpack.bin from Lightning Returns
    #[test]
    fn test_wpd_roundtrip_lr_wdbpack() {
        use super::api::{unpack_wpd, repack_wpd};
        use super::reader::WpdReader;
        use std::io::BufReader;
        use std::fs::File;

        let wpd_path = PathBuf::from("/Users/hramirez/Desktop/Development/ff13-lr_data/white_img2a/db/resident/wdbpack.bin");
        let out_dir = PathBuf::from("/tmp/test_wdbpack_dir");
        let repack_path = PathBuf::from("/tmp/wdbpack_repacked.bin");

        if !wpd_path.exists() {
            eprintln!("Test file not found: {:?}", wpd_path);
            return;
        }

        if out_dir.exists() { let _ = std::fs::remove_dir_all(&out_dir); }
        if repack_path.exists() { let _ = std::fs::remove_file(&repack_path); }

        // 1. Read original file headers to get offsets
        let file = File::open(&wpd_path).unwrap();
        let mut reader = WpdReader::new(BufReader::new(file));
        let header = reader.read_header().unwrap();
        let original_records = reader.read_records(&header).unwrap();

        println!("DEBUG: Original WPD has {} records", header.record_count);

        // 2. Unpack
        unpack_wpd(&wpd_path, &out_dir).expect("Failed to unpack WPD");

        // Verify records list exists
        assert!(out_dir.join("!!WPD_Records.txt").exists(), "Records list should exist");

        // 3. Repack
        repack_wpd(&out_dir, &repack_path).expect("Failed to repack WPD");
        assert!(repack_path.exists(), "Repacked file should exist");

        // 4. Read repacked file and compare
        let file2 = File::open(&repack_path).unwrap();
        let mut reader2 = WpdReader::new(BufReader::new(file2));
        let header2 = reader2.read_header().unwrap();
        let repacked_records = reader2.read_records(&header2).unwrap();

        assert_eq!(header.record_count, header2.record_count, "Record count should match");
        assert_eq!(original_records.len(), repacked_records.len(), "Records length should match");

        // 5. Compare record data
        for (i, (orig, repacked)) in original_records.iter().zip(repacked_records.iter()).enumerate() {
            assert_eq!(orig.name, repacked.name, "Record {} name mismatch", i);
            assert_eq!(orig.extension, repacked.extension, "Record {} extension mismatch", i);
            assert_eq!(orig.data.len(), repacked.data.len(), "Record {} data length mismatch: orig={}, repacked={}", i, orig.data.len(), repacked.data.len());
            assert_eq!(orig.data, repacked.data, "Record {} data content mismatch", i);
        }

        // 6. Compare file sizes
        let original_size = std::fs::metadata(&wpd_path).unwrap().len();
        let repacked_size = std::fs::metadata(&repack_path).unwrap().len();

        println!("DEBUG: Original size: {}, Repacked size: {}", original_size, repacked_size);
        println!("DEBUG: All {} records match!", original_records.len());
    }

    /// Compare offsets between original and repacked WPD
    #[test]
    fn test_wpd_offset_comparison() {
        use super::api::{unpack_wpd, repack_wpd};
        use std::io::{BufReader, Seek, SeekFrom};
        use std::fs::File;
        use byteorder::{BigEndian, ReadBytesExt};

        let wpd_path = PathBuf::from("/Users/hramirez/Desktop/Development/ff13-lr_data/white_img2a/db/resident/wdbpack.bin");
        let out_dir = PathBuf::from("/tmp/test_wdbpack_offset_dir");
        let repack_path = PathBuf::from("/tmp/wdbpack_offset_repacked.bin");

        if !wpd_path.exists() {
            eprintln!("Test file not found");
            return;
        }

        if out_dir.exists() { let _ = std::fs::remove_dir_all(&out_dir); }

        // Unpack and repack
        unpack_wpd(&wpd_path, &out_dir).unwrap();
        repack_wpd(&out_dir, &repack_path).unwrap();

        // Read both files and compare offsets
        let mut orig_file = BufReader::new(File::open(&wpd_path).unwrap());
        let mut repacked_file = BufReader::new(File::open(&repack_path).unwrap());

        // Skip magic (4 bytes)
        orig_file.seek(SeekFrom::Start(4)).unwrap();
        repacked_file.seek(SeekFrom::Start(4)).unwrap();

        let orig_count = orig_file.read_u32::<BigEndian>().unwrap();
        let repacked_count = repacked_file.read_u32::<BigEndian>().unwrap();
        assert_eq!(orig_count, repacked_count, "Record count should match");

        println!("DEBUG: Comparing offsets for {} records", orig_count);

        // Compare first 10 record offsets
        for i in 0..std::cmp::min(10, orig_count) {
            let header_pos = 16 + (i as u64 * 32);

            // Read original offset (at header_pos + 16)
            orig_file.seek(SeekFrom::Start(header_pos + 16)).unwrap();
            let orig_offset = orig_file.read_u32::<BigEndian>().unwrap();

            repacked_file.seek(SeekFrom::Start(header_pos + 16)).unwrap();
            let repacked_offset = repacked_file.read_u32::<BigEndian>().unwrap();

            println!("  Record {}: orig_offset=0x{:08X}, repacked_offset=0x{:08X}, match={}",
                     i, orig_offset, repacked_offset, orig_offset == repacked_offset);

            // Check 4-byte alignment (per C# WPD.Lib implementation)
            assert_eq!(repacked_offset % 4, 0, "Repacked offset for record {} should be 4-byte aligned", i);
        }

        println!("DEBUG: Offset comparison complete!");
    }
}
