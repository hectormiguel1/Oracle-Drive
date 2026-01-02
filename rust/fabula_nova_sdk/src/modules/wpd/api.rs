//! # WPD High-Level API
//!
//! This module provides the public API for WPD package operations.
//!
//! ## Functions
//!
//! - [`unpack_wpd`] - Extract all records to a directory
//! - [`repack_wpd`] - Create WPD from directory contents
//!
//! ## IMGB Integration
//!
//! When unpacking WPD files with paired `.imgb` files (image containers),
//! the module automatically extracts textures as DDS files. Similarly,
//! repacking will update the IMGB with any modified DDS files.

use std::path::Path;
use std::fs::{File, create_dir_all};
use std::io::{BufReader, BufWriter};
use anyhow::Result;
use super::reader::WpdReader;
use super::writer::WpdWriter;
use super::structs::{WpdData, WpdRecord};
use crate::modules::img::api as img_api;

/// Unpacks a WPD file to a directory.
///
/// Creates a `!!WPD_Records.txt` manifest file to preserve
/// record order and extension information for repacking.
///
/// If a paired `.imgb` file exists, textures are also extracted as DDS.
pub fn unpack_wpd<P: AsRef<Path>>(wpd_path: P, output_dir: P) -> Result<WpdData> {
    let wpd_path = wpd_path.as_ref();
    let output_dir = output_dir.as_ref();
    
    if !output_dir.exists() {
        create_dir_all(output_dir)?;
    }

    let file = File::open(wpd_path)?;
    let mut reader = WpdReader::new(BufReader::new(file));
    let header = reader.read_header()?;
    let records = reader.read_records(&header)?;

    // Create !!WPD_Records.txt
    let mut records_list = String::new();
    records_list.push_str(&format!("{}\n", records.len()));
    for record in &records {
        let ext = if record.extension.is_empty() { "null" } else { &record.extension };
        records_list.push_str(&format!("{} |-| {}\n", record.name, ext));
    }
    std::fs::write(output_dir.join("!!WPD_Records.txt"), records_list)?;

    // Check for paired IMGB
    let imgb_path = wpd_path.with_extension("imgb");
    let has_imgb = imgb_path.exists();

    for record in &records {
        let mut file_name = record.name.clone();
        if !record.extension.is_empty() {
            file_name.push('.');
            file_name.push_str(&record.extension);
        }
        
        let out_path = output_dir.join(&file_name);
        std::fs::write(&out_path, &record.data)?;

        // If it's an image and has IMGB, try to extract DDS
        if has_imgb && is_image_extension(&record.extension) {
            let mut dds_path = out_path.clone();
            dds_path.set_extension("dds");
            
            // We might want a separate directory for IMGB extracts like C# does?
            // C# uses "_" + imgbFileName.
            // For now, let's just put it next to the header file in the output dir.
            
            if let Err(e) = img_api::extract_img_to_dds(&out_path, &imgb_path, &dds_path) {
                log::warn!("Failed to extract DDS for {}: {:?}", file_name, e);
            }
        }
    }

    Ok(WpdData { records })
}

/// Repacks a directory into a WPD file.
///
/// Requires `!!WPD_Records.txt` in the input directory to determine
/// file order and extensions. Use [`unpack_wpd`] first to create this file.
///
/// If a paired `.imgb` file exists and DDS files are present,
/// the IMGB is also updated with the modified textures.
pub fn repack_wpd<P: AsRef<Path>>(input_dir: P, wpd_path: P) -> Result<()> {
    let input_dir = input_dir.as_ref();
    let wpd_path = wpd_path.as_ref();
    
    // We need the record list to know the order and extensions.
    // In Rust, we might just scan the directory, but the C# tool relies on !!WPD_Records.txt
    // to preserve order and handle cases where extensions are not obvious or "null".
    
    let records_list_path = input_dir.join("!!WPD_Records.txt");
    if !records_list_path.exists() {
        return Err(anyhow::anyhow!("Missing !!WPD_Records.txt in input directory"));
    }

    let records_list_content = std::fs::read_to_string(records_list_path)?;
    let mut lines = records_list_content.lines();
    let total_records: usize = lines.next().ok_or_else(|| anyhow::anyhow!("Empty records list"))?.parse()?;
    
    let mut records = Vec::new();
    let imgb_path = wpd_path.with_extension("imgb");
    let has_imgb = imgb_path.exists();

    for _ in 0..total_records {
        let line = lines.next().ok_or_else(|| anyhow::anyhow!("Unexpected end of records list"))?;
        let parts: Vec<&str> = line.split(" |-| ").collect();
        if parts.len() < 2 { continue; }
        
        let name = parts[0].to_string();
        let extension = if parts[1] == "null" { "".to_string() } else { parts[1].to_string() };
        
        let mut file_name = name.clone();
        if !extension.is_empty() {
            file_name.push('.');
            file_name.push_str(&extension);
        }
        
        let file_path = input_dir.join(&file_name);
        if !file_path.exists() {
            return Err(anyhow::anyhow!("File not found: {:?}", file_path));
        }

        // If it's an image and has IMGB, we might need to repack the IMGB part too.
        if has_imgb && is_image_extension(&extension) {
            let mut dds_path = file_path.clone();
            dds_path.set_extension("dds");
            
            if dds_path.exists() {
                // Repack DDS to IMGB
                if let Err(e) = img_api::repack_img_strict(&file_path, &imgb_path, &dds_path) {
                    log::warn!("Failed to repack DDS for {}: {:?}", file_name, e);
                }
            }
        }

        let data = std::fs::read(&file_path)?;
        records.push(WpdRecord {
            name,
            extension,
            data,
        });
    }

    let file = File::create(wpd_path)?;
    let mut writer = WpdWriter::new(BufWriter::new(file));
    writer.write(&records)?;

    Ok(())
}

/// Checks if a file extension indicates an image/texture file.
///
/// These extensions have paired data in IMGB files.
fn is_image_extension(ext: &str) -> bool {
    let ext = ext.to_lowercase();
    matches!(ext.as_str(), "gtex" | "trb" | "xb" | "ps3" | "txb" | "txbh" | "vtex" | "cgt")
}
