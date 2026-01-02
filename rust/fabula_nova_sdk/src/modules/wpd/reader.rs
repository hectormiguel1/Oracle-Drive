//! # WPD Binary Reader
//!
//! This module provides binary parsing for WPD (WhiteBin Package) files.
//! WPD is a simpler format than WBT, storing uncompressed files directly.

use std::io::{Read, Seek, SeekFrom};
use binrw::BinReaderExt;
use anyhow::Result;
use super::structs::{WpdBinaryHeader, WpdRecordHeader, WpdRecord};

/// Binary reader for WPD package files.
///
/// Reads the header, record headers, and extracts record data.
pub struct WpdReader<R: Read + Seek> {
    reader: R,
}

impl<R: Read + Seek> WpdReader<R> {
    /// Creates a new WPD reader.
    pub fn new(reader: R) -> Self {
        Self { reader }
    }

    /// Reads the WPD file header from the start of the file.
    pub fn read_header(&mut self) -> Result<WpdBinaryHeader> {
        self.reader.seek(SeekFrom::Start(0))?;
        let header: WpdBinaryHeader = self.reader.read_be()?;
        Ok(header)
    }

    /// Reads all records from the WPD file.
    ///
    /// First reads all record headers, then seeks to each record's
    /// offset to read its data.
    pub fn read_records(&mut self, header: &WpdBinaryHeader) -> Result<Vec<WpdRecord>> {
        let mut record_headers = Vec::new();
        self.reader.seek(SeekFrom::Start(16))?;
        
        for _ in 0..header.record_count {
            let rh: WpdRecordHeader = self.reader.read_be()?;
            record_headers.push(rh);
        }

        let mut records = Vec::new();
        for rh in record_headers {
            self.reader.seek(SeekFrom::Start(rh.offset as u64))?;
            let mut data = vec![0u8; rh.size as usize];
            self.reader.read_exact(&mut data)?;
            
            records.push(WpdRecord {
                name: rh.name,
                extension: rh.extension,
                data,
            });
        }

        Ok(records)
    }
}
