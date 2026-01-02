//! # WBT Container File Handler
//!
//! This module handles extraction from WBT container files (`.white_img` or `.bin`).
//! Container files store the actual file data, which is typically ZLIB compressed.
//!
//! ## File Extraction
//!
//! Files are extracted by:
//! 1. Looking up metadata (offset, sizes) from the filelist
//! 2. Seeking to the file offset in the container
//! 3. Reading compressed data
//! 4. Decompressing with ZLIB if needed
//!
//! ## Compression
//!
//! Files are compressed if `compressed_size != uncompressed_size`.
//! Uncompressed files (mostly large textures) are stored as-is.

use std::io::{Read, Seek, SeekFrom};
use log::{debug, trace};
use crate::modules::wbt::filelist::{Filelist, WbtError};
use flate2::read::ZlibDecoder;

/// WBT container file reader.
///
/// Wraps a seekable reader and provides file extraction by index.
/// Uses the filelist to locate files within the container.
pub struct WbtContainer<R: Read + Seek> {
    reader: R,
    filelist: Filelist,
}

impl<R: Read + Seek> WbtContainer<R> {
    /// Creates a new container reader.
    ///
    /// The filelist is consumed and stored internally for lookups.
    pub fn new(reader: R, filelist: Filelist) -> Self {
        debug!(
            "WbtContainer created with {} entries",
            filelist.entries.len()
        );
        Self { reader, filelist }
    }

    /// Returns the total number of files in the archive.
    pub fn total_files(&self) -> usize {
        self.filelist.entries.len()
    }

    /// Extracts a file by its index in the archive.
    ///
    /// # Returns
    ///
    /// A tuple of (virtual_path, file_data) on success.
    ///
    /// # Errors
    ///
    /// Returns an error if the index is invalid, file is corrupted,
    /// or ZLIB decompression fails.
    pub fn extract_file(&mut self, index: usize) -> Result<(String, Vec<u8>), WbtError> {
        let metadata = self.filelist.get_metadata(index)?;
        self.reader.seek(SeekFrom::Start(metadata.offset))?;

        let is_compressed = metadata.compressed_size != metadata.uncompressed_size;
        trace!(
            "Extracting file {}: offset=0x{:X}, compressed={}",
            index,
            metadata.offset,
            is_compressed
        );

        let mut data = Vec::with_capacity(metadata.uncompressed_size as usize);
        if is_compressed {
            let mut compressed_data = vec![0u8; metadata.compressed_size as usize];
            self.reader.read_exact(&mut compressed_data)?;
            let mut decoder = ZlibDecoder::new(&compressed_data[..]);
            decoder
                .read_to_end(&mut data)
                .map_err(|e| WbtError::Zlib(e.to_string()))?;
            trace!(
                "Decompressed: {} -> {} bytes",
                metadata.compressed_size,
                data.len()
            );
        } else {
            data.resize(metadata.uncompressed_size as usize, 0);
            self.reader.read_exact(&mut data)?;
            trace!("Read uncompressed: {} bytes", data.len());
        }

        Ok((metadata.path, data))
    }

    /// Returns a reference to the parsed filelist.
    pub fn filelist(&self) -> &Filelist {
        &self.filelist
    }
}
