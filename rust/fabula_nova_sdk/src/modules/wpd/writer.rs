//! # WPD Binary Writer
//!
//! This module provides binary serialization for WPD (WhiteBin Package) files.
//! Creates WPD files from a collection of records.

use std::io::{Write, Seek, SeekFrom};
use byteorder::{WriteBytesExt, BigEndian};
use anyhow::Result;
use super::structs::WpdRecord;

/// Binary writer for WPD package files.
///
/// Creates WPD files with proper header, record headers, and data sections.
pub struct WpdWriter<W: Write + Seek> {
    writer: W,
}

impl<W: Write + Seek> WpdWriter<W> {
    /// Creates a new WPD writer.
    pub fn new(writer: W) -> Self {
        Self { writer }
    }

    /// Writes a complete WPD file from records.
    ///
    /// C# implementation details:
    /// 1. Write "WPD" + 13 null bytes (16 bytes header)
    /// 2. Write all record headers (name 16 bytes + offset 4 bytes placeholder + size 4 bytes placeholder + extension 8 bytes)
    /// 3. Update record count at position 4
    /// 4. Append data directly after headers (no alignment padding between headers and data)
    /// 5. After each record's data, pad to 4-byte alignment
    pub fn write(&mut self, records: &[WpdRecord]) -> Result<()> {
        let record_count = records.len() as u32;

        // 1. Write Header: "WPD" + 13 null bytes = 16 bytes total
        // C#: outWpdRecordsWriter.Write("WPD");
        //     PadNullBytes(outWpdRecordsWriter, 13);
        self.writer.seek(SeekFrom::Start(0))?;
        self.writer.write_all(b"WPD")?;
        self.writer.write_all(&[0u8; 13])?; // 13 null bytes to make 16 total

        // 2. Write all record headers with placeholder offsets/sizes
        // C#: for (int r = 0; r < totalRecords; r++) { ... write name, pad, extension }
        for record in records.iter() {
            // Name (up to 16 bytes, null-padded)
            let name_bytes = record.name.as_bytes();
            let name_len = name_bytes.len().min(16);
            self.writer.write_all(&name_bytes[..name_len])?;

            // Pad name to 16 bytes + 8 bytes for offset/size placeholder
            // C#: PadNullBytes(outWpdRecordsWriter, (16 - (uint)currentRecordNameArray.Length) + 8);
            let name_padding = (16 - name_len) + 8;
            self.writer.write_all(&vec![0u8; name_padding])?;

            // Extension (8 bytes, null-padded)
            // C#: if (currentRecordLineData[1] == "null") { PadNullBytes(8); }
            //     else { write extension + pad to 8 }
            if record.extension.is_empty() {
                self.writer.write_all(&[0u8; 8])?;
            } else {
                let ext_bytes = record.extension.as_bytes();
                let ext_len = ext_bytes.len().min(8);
                self.writer.write_all(&ext_bytes[..ext_len])?;
                if ext_len < 8 {
                    self.writer.write_all(&vec![0u8; 8 - ext_len])?;
                }
            }
        }

        // 3. Update record count at position 4
        // C#: outWPDoffsetWriter.BaseStream.Position = 4;
        //     outWPDoffsetWriter.WriteBytesUInt32(totalRecords, true);
        self.writer.seek(SeekFrom::Start(4))?;
        self.writer.write_u32::<BigEndian>(record_count)?;

        // 4. Write record data and update offsets
        // C#: uint readStartPos = 16; uint writeStartPos = 32;
        // Note: readStartPos is used in C# for reading record names, but we already have records in memory
        let mut write_start_pos: u64 = 32; // offset field is at position 16 + 16 = 32 for first record

        for record in records.iter() {
            // Get current data position (end of file)
            // C#: var recordDataStartPos = (uint)outWPDdataStream.Length;
            let record_data_start_pos = self.writer.seek(SeekFrom::End(0))? as u32;

            // Update offset in header
            // C#: outWPDoffsetWriter.BaseStream.Position = writeStartPos;
            //     outWPDoffsetWriter.WriteBytesUInt32(recordDataStartPos, true);
            self.writer.seek(SeekFrom::Start(write_start_pos))?;
            self.writer.write_u32::<BigEndian>(record_data_start_pos)?;

            // Update size in header
            // C#: outWPDoffsetWriter.BaseStream.Position = writeStartPos + 4;
            //     outWPDoffsetWriter.WriteBytesUInt32(currentFileSize, true);
            let current_file_size = record.data.len() as u32;
            self.writer.seek(SeekFrom::Start(write_start_pos + 4))?;
            self.writer.write_u32::<BigEndian>(current_file_size)?;

            // Write data at end of file
            // C#: currentFileStream.CopyStreamTo(outWPDdataStream, currentFileSize, false);
            self.writer.seek(SeekFrom::End(0))?;
            self.writer.write_all(&record.data)?;

            // Pad to 4-byte alignment
            // C#: const int padValue = 4;
            //     if (currentPos % padValue != 0) { ... pad ... }
            let current_pos = self.writer.seek(SeekFrom::End(0))?;
            const PAD_VALUE: u64 = 4;
            if current_pos % PAD_VALUE != 0 {
                let remainder = current_pos % PAD_VALUE;
                let null_bytes_amount = PAD_VALUE - remainder;
                self.writer.write_all(&vec![0u8; null_bytes_amount as usize])?;
            }

            // Move to next record header position
            // C#: writeStartPos += 32;
            write_start_pos += 32;
        }

        Ok(())
    }
}
