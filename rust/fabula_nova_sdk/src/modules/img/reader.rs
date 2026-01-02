//! # IMG Binary Reader
//!
//! This module provides binary parsing for texture header files.
//!
//! ## GTEX Chunk Discovery
//!
//! GTEX headers can be embedded at arbitrary positions within larger files
//! (e.g., XGR packages contain multiple textures). The reader scans for the
//! "GTEX" magic bytes to locate headers.
//!
//! ## Scan Algorithm
//!
//! ```text
//! File:  [other data...] G T E X [header...] [other data...]
//!                        ^
//!                        Scan finds magic here
//!
//! 1. Read file in 4KB chunks
//! 2. Search each chunk for "GTEX" bytes
//! 3. On overlap boundaries, backtrack 3 bytes to avoid missing split magic
//! 4. Return header position and parsed struct
//! ```
//!
//! ## DDS Reading
//!
//! DDS files have a fixed header at position 0, so reading is straightforward.

use std::io::{Read, Seek, SeekFrom};
use binrw::BinReaderExt;
use anyhow::Result;
use super::structs::{GtexHeader, DdsHeader};

/// Binary reader for texture files.
///
/// Supports both GTEX (game format) and DDS (standard format) headers.
///
/// # Type Parameter
///
/// `R` - Any type implementing `Read + Seek`, typically `BufReader<File>`.
///
/// # Example
///
/// ```rust,ignore
/// let file = File::open("texture.txbh")?;
/// let mut reader = ImgReader::new(BufReader::new(file));
///
/// if let Some((header, offset)) = reader.read_gtex()? {
///     println!("Found GTEX at offset {}: {}x{}",
///         offset, header.width, header.height);
/// }
/// ```
pub struct ImgReader<R: Read + Seek> {
    reader: R,
}

impl<R: Read + Seek> ImgReader<R> {
    /// Creates a new image reader wrapping the given stream.
    pub fn new(reader: R) -> Self {
        Self { reader }
    }

    /// Scans for and reads a GTEX header from the stream.
    ///
    /// Searches the entire file for the "GTEX" magic bytes, then parses
    /// the header structure at that location.
    ///
    /// # Returns
    ///
    /// - `Ok(Some((header, offset)))` - Found GTEX at the given byte offset
    /// - `Ok(None)` - No GTEX magic found in the file
    /// - `Err(_)` - I/O or parsing error
    ///
    /// # Algorithm
    ///
    /// Uses a chunked scan with overlap handling to ensure magic bytes
    /// split across chunk boundaries are detected:
    ///
    /// ```text
    /// Chunk 1: [...data...GT]     <- "GT" at end
    /// Chunk 2: [EX...data...]     <- "EX" at start
    ///          ^-- Would miss "GTEX" without backtrack
    /// ```
    ///
    /// After each 4KB chunk, seeks back 3 bytes before reading the next chunk.
    pub fn read_gtex(&mut self) -> Result<Option<(GtexHeader, u64)>> {
        // Get file bounds for scan
        let start_pos = self.reader.stream_position()?;
        let len = self.reader.seek(SeekFrom::End(0))?;
        self.reader.seek(SeekFrom::Start(start_pos))?;

        // 4KB buffer for chunked reading
        let mut buffer = [0u8; 4096];
        let magic = b"GTEX";

        loop {
            let pos = self.reader.stream_position()?;
            if pos >= len {
                break;
            }

            let read = self.reader.read(&mut buffer)?;
            if read < 4 {
                break; // Not enough bytes to contain magic
            }

            // Linear scan through buffer for magic bytes
            for i in 0..read - 3 {
                if &buffer[i..i+4] == magic {
                    // Found GTEX - seek to position and parse header
                    let gtex_pos = pos + i as u64;
                    log::debug!("Found GTEX chunk at {}", gtex_pos);
                    self.reader.seek(SeekFrom::Start(gtex_pos))?;
                    let header: GtexHeader = self.reader.read_be()?;
                    return Ok(Some((header, gtex_pos)));
                }
            }

            // Overlap handling: backtrack 3 bytes to catch split magic
            // Only needed if we read a full chunk (more data may follow)
            if read == 4096 {
                self.reader.seek(SeekFrom::Current(-3))?;
            }
        }

        Ok(None) // No GTEX found
    }

    /// Reads a DDS header from the current stream position.
    ///
    /// Assumes the stream is positioned at the start of a DDS file
    /// (the "DDS " magic bytes).
    ///
    /// # Endianness
    ///
    /// DDS headers are read in little-endian format.
    ///
    /// # Errors
    ///
    /// Returns an error if the magic bytes don't match "DDS " or if
    /// reading fails.
    pub fn read_dds(&mut self) -> Result<DdsHeader> {
        let header: DdsHeader = self.reader.read_le()?;
        Ok(header)
    }
}
