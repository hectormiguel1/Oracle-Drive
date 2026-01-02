//! # ZTR Binary Reader
//!
//! This module provides the [`ZtrReader`] struct for parsing ZTR binary files.
//! The reader handles the complex dictionary-based decompression scheme used
//! by Final Fantasy XIII's text resource format.
//!
//! ## Reading Process
//!
//! 1. Parse file header to get counts and offsets
//! 2. Read dictionary chunk offset table
//! 3. Decompress string IDs using dictionary expansion
//! 4. For each text entry:
//!    a. Read LineInfo to locate text within chunks
//!    b. Load appropriate dictionary chunk
//!    c. Expand compressed bytes using dictionary
//!    d. Read until double-null terminator
//!
//! ## Dictionary Compression
//!
//! ZTR uses a byte-pair encoding scheme where common two-byte sequences
//! are replaced with single-byte references. The dictionary at the start
//! of each chunk defines these replacements.
//!
//! ```text
//! Dictionary Entry: [PageIndex, Byte1, Byte2]
//! When PageIndex is encountered, it expands to [Byte1, Byte2]
//! If Byte1 or Byte2 is also a PageIndex, recursively expand
//! ```

use binrw::BinReaderExt;
use std::collections::HashMap;
use std::io::{Cursor, Read, Seek, SeekFrom};

use super::structs::{LineInfo, ZtrError, ZtrFileHeader};

// =============================================================================
// ZtrReader - Main Parser
// =============================================================================

/// Binary reader for ZTR text resource files.
///
/// `ZtrReader` wraps any `Read + Seek` source and provides methods to
/// parse the ZTR file format. The result is a vector of (ID, raw_bytes)
/// pairs that can then be decoded using the text_decoder module.
///
/// # Type Parameter
/// * `R` - Any type implementing `Read + Seek` (File, Cursor, etc.)
///
/// # Example
/// ```rust,ignore
/// use std::fs::File;
/// use std::io::BufReader;
/// use fabula_nova_sdk::modules::ztr::ZtrReader;
///
/// let file = File::open("txtres_us.ztr")?;
/// let mut reader = ZtrReader::new(BufReader::new(file));
/// let entries = reader.read()?;
///
/// for (id, raw_bytes) in entries {
///     println!("ID: {}, {} bytes", id, raw_bytes.len());
/// }
/// ```
pub struct ZtrReader<R: Read + Seek> {
    /// The underlying reader source
    reader: R,
}

impl<R: Read + Seek> ZtrReader<R> {
    /// Creates a new ZtrReader wrapping the given source.
    ///
    /// # Arguments
    /// * `reader` - Any reader implementing `Read + Seek`
    pub fn new(reader: R) -> Self {
        Self { reader }
    }

    /// Reads and parses the entire ZTR file.
    ///
    /// This method performs the complete parsing process:
    /// 1. Reads the file header
    /// 2. Decompresses string IDs
    /// 3. Extracts each text entry using dictionary decompression
    ///
    /// # Returns
    /// A vector of (ID, raw_bytes) tuples where:
    /// - ID: The string identifier for this text entry
    /// - raw_bytes: The raw binary content (use text_decoder to convert to text)
    ///
    /// # Errors
    /// Returns `ZtrError` if:
    /// - I/O errors occur during reading
    /// - Binary structure parsing fails
    /// - UTF-8 decoding of IDs fails
    pub fn read(&mut self) -> Result<Vec<(String, Vec<u8>)>, ZtrError> {
        let header: ZtrFileHeader = self.reader.read_be()?;
        log::debug!("ZTR Header: {:?}", header);

        let mut dict_chunk_offsets = Vec::with_capacity(header.dict_chunk_offsets_count as usize);
        for _ in 0..header.dict_chunk_offsets_count {
            let offset: u32 = self.reader.read_be()?;
            dict_chunk_offsets.push(offset);
        }

        let mut id_chunk_sizes = Vec::new();
        let mut remaining = header.dcmp_ids_size;
        while remaining > 0 {
            let chunk_size = std::cmp::min(remaining, 4096);
            id_chunk_sizes.push(chunk_size);
            remaining -= chunk_size;
        }

        let line_info_start = 20 + (header.dict_chunk_offsets_count * 4) as u64;
        let ids_start = line_info_start + (header.line_count * 4) as u64;

        self.reader.seek(SeekFrom::Start(ids_start))?;

        let mut ids_data = Vec::new();

        for (idx, &chunk_decompressed_size) in id_chunk_sizes.iter().enumerate() {
            let compressed_size: u32 = self.reader.read_be()?;
            let chunk_start_pos = self.reader.stream_position()?;

            let page_indices = get_dict_chunk_pages(&mut self.reader, compressed_size)?;

            self.reader.seek(SeekFrom::Start(chunk_start_pos))?;
            let arranged_dict = arrange_dict_chunk(&mut self.reader, &page_indices)?;

            let mut remaining_str_data = chunk_decompressed_size;
            while remaining_str_data > 0 {
                let val: u8 = self.reader.read_be()?;
                if page_indices.contains(&val) {
                    if let Some(list) = arranged_dict.get(&val) {
                        for &item in list {
                            ids_data.push(item);
                            remaining_str_data -= 1;
                        }
                    }
                } else {
                    ids_data.push(val);
                    remaining_str_data -= 1;
                }
            }
        }

        let line_dict_chunks_start = self.reader.stream_position()?;
        log::trace!(
            "Line dictionary chunks start at: {}",
            line_dict_chunks_start
        );

        let ids_cursor = Cursor::new(ids_data);
        let mut ids_reader = ZtrIdsReader::new(ids_cursor);

        let mut entries = Vec::new();

        let mut prev_dict_chunk_id = 0;
        let mut change_chunk = true;
        let mut current_dict_chunk_size;
        let mut current_dict_chunk_data_start;
        let mut current_line_dict: HashMap<u8, Vec<u8>> = HashMap::new();
        let mut current_dict_chunk_line_data_start = 0;

        log::info!("Starting extraction of {} lines", header.line_count);
        for i in 0..header.line_count {
            self.reader
                .seek(SeekFrom::Start(line_info_start + (i as u64 * 4)))?;
            let mut line_info: LineInfo = self.reader.read_be()?;

            let id_string = ids_reader.read_next_id()?;

            let mut line_bytes = Vec::new();

            if line_info.dict_chunk_id != prev_dict_chunk_id {
                change_chunk = true;
            }
            prev_dict_chunk_id = line_info.dict_chunk_id;

            if change_chunk {
                let offset = dict_chunk_offsets[line_info.dict_chunk_id as usize] as u64;
                self.reader
                    .seek(SeekFrom::Start(line_dict_chunks_start + offset))?;
                current_dict_chunk_size = self.reader.read_be()?;
                current_dict_chunk_data_start = self.reader.stream_position()?;

                current_line_dict = get_arranged_dictionary(
                    &mut self.reader,
                    current_dict_chunk_size,
                    current_dict_chunk_data_start,
                )?;

                current_dict_chunk_line_data_start = self.reader.stream_position()?;
                change_chunk = false;
            }

            self.reader.seek(SeekFrom::Start(
                current_dict_chunk_line_data_start + line_info.line_start_pos_in_chunk as u64,
            ))?;

            let mut prev_line_byte = 255u8;
            let mut prev_line_byte_before_dict = 255u8;

            loop {
                let current_pos = self.reader.stream_position()?;

                let next_chunk_offset_val =
                    dict_chunk_offsets.get((line_info.dict_chunk_id + 1) as usize);

                if let Some(&next_offset) = next_chunk_offset_val {
                    if current_pos == line_dict_chunks_start + next_offset as u64 {
                        line_info.dict_chunk_id += 1;

                        let offset = dict_chunk_offsets[line_info.dict_chunk_id as usize] as u64;
                        self.reader
                            .seek(SeekFrom::Start(line_dict_chunks_start + offset))?;
                        current_dict_chunk_size = self.reader.read_be()?;
                        current_dict_chunk_data_start = self.reader.stream_position()?;

                        current_line_dict = get_arranged_dictionary(
                            &mut self.reader,
                            current_dict_chunk_size,
                            current_dict_chunk_data_start,
                        )?;
                        current_dict_chunk_line_data_start = self.reader.stream_position()?;

                        self.reader
                            .seek(SeekFrom::Start(current_dict_chunk_line_data_start))?;
                    }
                }

                let mut current_line_byte: u8 = self.reader.read_be()?;

                if prev_line_byte == 0 && current_line_byte == 0 {
                    line_bytes.push(current_line_byte);
                    break;
                }

                prev_line_byte = current_line_byte;

                if let Some(expanded) = current_line_dict.get(&current_line_byte) {
                    prev_line_byte = prev_line_byte_before_dict;

                    let start_idx = line_info.chara_start_in_dict_page as usize;
                    line_info.chara_start_in_dict_page = 0;

                    for &b in expanded.iter().skip(start_idx) {
                        current_line_byte = b;

                        if prev_line_byte == 0 && current_line_byte == 0 {
                            line_bytes.push(current_line_byte);
                            break;
                        }

                        line_bytes.push(current_line_byte);
                        prev_line_byte = current_line_byte;
                    }

                    if line_bytes.len() >= 2
                        && line_bytes[line_bytes.len() - 1] == 0
                        && line_bytes[line_bytes.len() - 2] == 0
                    {
                        break;
                    }
                } else {
                    line_bytes.push(current_line_byte);
                }

                prev_line_byte_before_dict = current_line_byte;
            }

            entries.push((id_string, line_bytes));
        }

        Ok(entries)
    }
}

// =============================================================================
// Helper Structures and Functions
// =============================================================================

/// Internal reader for decompressed string IDs.
///
/// Once IDs are decompressed from the ZTR file, they're stored as a
/// contiguous buffer of null-terminated strings. This struct provides
/// an iterator-like interface to read them one at a time.
struct ZtrIdsReader<T> {
    /// Cursor wrapping the decompressed ID data
    cursor: Cursor<T>,
}

impl<T: AsRef<[u8]>> ZtrIdsReader<T> {
    /// Creates a new ID reader from a cursor.
    fn new(cursor: Cursor<T>) -> Self {
        Self { cursor }
    }

    /// Reads the next null-terminated string ID from the buffer.
    ///
    /// # Returns
    /// The next ID as a UTF-8 string, or an error if:
    /// - End of buffer reached
    /// - Invalid UTF-8 sequence encountered
    fn read_next_id(&mut self) -> Result<String, ZtrError> {
        let mut bytes = Vec::new();
        loop {
            let mut buf = [0u8; 1];
            if self.cursor.read(&mut buf)? == 0 {
                break; // EOF
            }
            if buf[0] == 0 {
                break; // Null terminator
            }
            bytes.push(buf[0]);
        }
        Ok(String::from_utf8(bytes)?)
    }
}

/// Extracts dictionary page indices from a dictionary chunk.
///
/// A dictionary chunk starts with a series of 3-byte entries:
/// `[PageIndex, Byte1, Byte2]`
///
/// This function collects all the PageIndex values, which are the
/// byte values that trigger dictionary expansion during decompression.
///
/// # Arguments
/// * `reader` - The file reader positioned at the dictionary start
/// * `dict_chunk_size` - Size of the dictionary in bytes (divisible by 3)
///
/// # Returns
/// Vector of page index bytes used for dictionary lookups
fn get_dict_chunk_pages<R: Read + Seek>(
    reader: &mut R,
    dict_chunk_size: u32,
) -> Result<Vec<u8>, ZtrError> {
    let mut pages = Vec::new();
    // Each dictionary entry is 3 bytes: [index, byte1, byte2]
    for _ in 0..(dict_chunk_size / 3) {
        pages.push(reader.read_be()?);
        reader.seek(SeekFrom::Current(2))?; // Skip byte1, byte2 for now
    }
    Ok(pages)
}

/// Builds the dictionary expansion mapping from raw dictionary data.
///
/// This performs a two-pass process:
/// 1. First pass: Read all [PageIndex → (Byte1, Byte2)] mappings
/// 2. Second pass: Resolve recursive references where Byte1 or Byte2
///    is itself a PageIndex, creating fully expanded byte sequences
///
/// # Algorithm Detail
/// The dictionary supports recursive expansion. If PageIndex 0x10 maps
/// to (0x11, 0x41) and PageIndex 0x11 maps to (0x42, 0x43), then:
/// - Encountering 0x10 expands to [0x42, 0x43, 0x41]
///
/// The page indices are processed in order, which ensures dependencies
/// are resolved before they're needed (topological ordering from file).
///
/// # Arguments
/// * `reader` - File reader positioned at dictionary start
/// * `page_indices` - List of page index bytes from `get_dict_chunk_pages`
///
/// # Returns
/// HashMap mapping each PageIndex to its fully expanded byte sequence
fn arrange_dict_chunk<R: Read + Seek>(
    reader: &mut R,
    page_indices: &[u8],
) -> Result<HashMap<u8, Vec<u8>>, ZtrError> {
    // Pass 1: Read raw mappings (PageIndex → [Byte1, Byte2])
    let mut pass1 = HashMap::new();
    for &idx in page_indices {
        reader.seek(SeekFrom::Current(1))?; // Skip the PageIndex byte (already known)
        let b1: u8 = reader.read_be()?;
        let b2: u8 = reader.read_be()?;
        pass1.insert(idx, vec![b1, b2]);
    }

    // Pass 2: Resolve recursive references
    // Process in order so that dependencies are resolved before they're needed
    let mut final_dict: HashMap<u8, Vec<u8>> = HashMap::new();

    for &idx in page_indices {
        let mut current_values = Vec::new();
        if let Some(items) = pass1.get(&idx) {
            for &item in items {
                if page_indices.contains(&item) {
                    // This byte is itself a PageIndex - expand it recursively
                    if let Some(existing) = final_dict.get(&item) {
                        current_values.extend_from_slice(existing);
                    }
                    // Note: If not found, the file format assumption is violated.
                    // This relies on topological ordering in the file.
                } else {
                    // Regular byte, add directly
                    current_values.push(item);
                }
            }
            final_dict.insert(idx, current_values);
        }
    }
    Ok(final_dict)
}

/// Convenience function to fully parse a dictionary chunk.
///
/// Combines `get_dict_chunk_pages` and `arrange_dict_chunk` into a single
/// call that returns the complete expansion dictionary.
///
/// # Arguments
/// * `reader` - File reader positioned at the dictionary size field
/// * `dict_chunk_size` - Size of the dictionary data in bytes
/// * `dict_chunk_data_start` - File offset where dictionary entries begin
///
/// # Returns
/// HashMap mapping PageIndex bytes to their expanded byte sequences
fn get_arranged_dictionary<R: Read + Seek>(
    reader: &mut R,
    dict_chunk_size: u32,
    dict_chunk_data_start: u64,
) -> Result<HashMap<u8, Vec<u8>>, ZtrError> {
    let page_indices = get_dict_chunk_pages(reader, dict_chunk_size)?;
    reader.seek(SeekFrom::Start(dict_chunk_data_start))?;
    arrange_dict_chunk(reader, &page_indices)
}
