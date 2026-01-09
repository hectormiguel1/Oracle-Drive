//! SCD file parsing implementation.

use std::io::{Cursor, Read, Seek, SeekFrom};
use byteorder::{LittleEndian, BigEndian, ReadBytesExt};
use anyhow::{Result, bail, Context};

use super::structs::*;

/// Parse SCD file from bytes.
pub fn parse_scd(data: &[u8], name: &str) -> Result<ScdMetadata> {
    let mut cursor = Cursor::new(data);

    // Verify magic
    let mut magic = [0u8; 8];
    cursor.read_exact(&mut magic)?;
    if &magic != SCD_MAGIC {
        bail!("Invalid SCD magic: expected SEDBSSCF, got {:?}", String::from_utf8_lossy(&magic));
    }

    // Read header
    let header = read_header(&mut cursor)?;

    // Read sub-header
    cursor.seek(SeekFrom::Start(header.tables_offset as u64))?;
    let sub_header = read_sub_header(&mut cursor, header.big_endian)?;

    // Read stream info entries
    let mut streams = Vec::new();
    for i in 0..sub_header.stream_count {
        // Read offset from stream info table
        let table_entry_offset = sub_header.stream_info_offset as u64 + (i as u64 * 4);
        cursor.seek(SeekFrom::Start(table_entry_offset))?;
        let stream_offset = if header.big_endian {
            cursor.read_u32::<BigEndian>()?
        } else {
            cursor.read_u32::<LittleEndian>()?
        };

        if stream_offset == 0 || stream_offset == 0xFFFFFFFF {
            continue; // Skip dummy entries
        }

        // Read stream info at offset
        cursor.seek(SeekFrom::Start(stream_offset as u64))?;
        if let Some(info) = read_stream_info(&mut cursor, header.big_endian, i as u32)? {
            streams.push(info);
        }
    }

    // Calculate total duration estimate
    let duration_seconds = streams.iter()
        .map(|s| estimate_duration(s))
        .max_by(|a, b| a.partial_cmp(b).unwrap_or(std::cmp::Ordering::Equal))
        .unwrap_or(0.0);

    Ok(ScdMetadata {
        name: name.to_string(),
        header,
        streams,
        duration_seconds,
    })
}

fn read_header(cursor: &mut Cursor<&[u8]>) -> Result<ScdHeader> {
    // Skip magic (already read), position at 0x08
    cursor.seek(SeekFrom::Start(0x08))?;

    let version = cursor.read_u32::<LittleEndian>()?;
    let big_endian = cursor.read_u8()? == 0x01;
    cursor.read_u8()?; // padding
    let tables_offset = cursor.read_u16::<LittleEndian>()?;

    // File size at 0x10
    cursor.seek(SeekFrom::Start(0x10))?;
    let file_size = cursor.read_u64::<LittleEndian>()?;

    Ok(ScdHeader {
        version,
        big_endian,
        tables_offset,
        file_size,
    })
}

fn read_sub_header(cursor: &mut Cursor<&[u8]>, big_endian: bool) -> Result<ScdSubHeader> {
    let (table1_count, table2_count, stream_count, sound_folder_id) = if big_endian {
        (
            cursor.read_u16::<BigEndian>()?,
            cursor.read_u16::<BigEndian>()?,
            cursor.read_u16::<BigEndian>()?,
            cursor.read_u16::<BigEndian>()?,
        )
    } else {
        (
            cursor.read_u16::<LittleEndian>()?,
            cursor.read_u16::<LittleEndian>()?,
            cursor.read_u16::<LittleEndian>()?,
            cursor.read_u16::<LittleEndian>()?,
        )
    };

    let (table2_offset, stream_info_offset, table4_offset) = if big_endian {
        (
            cursor.read_u32::<BigEndian>()?,
            cursor.read_u32::<BigEndian>()?,
            cursor.read_u32::<BigEndian>()?,
        )
    } else {
        (
            cursor.read_u32::<LittleEndian>()?,
            cursor.read_u32::<LittleEndian>()?,
            cursor.read_u32::<LittleEndian>()?,
        )
    };

    Ok(ScdSubHeader {
        table1_count,
        table2_count,
        stream_count,
        sound_folder_id,
        table2_offset,
        stream_info_offset,
        table4_offset,
    })
}

fn read_stream_info(cursor: &mut Cursor<&[u8]>, big_endian: bool, index: u32) -> Result<Option<ScdStreamInfo>> {
    let stream_header_start = cursor.position();

    let (data_size, channels, sample_rate, codec_raw, loop_start, loop_end, extra_data_size, aux_chunk_count) = if big_endian {
        (
            cursor.read_u32::<BigEndian>()?,
            cursor.read_u32::<BigEndian>()?,
            cursor.read_u32::<BigEndian>()?,
            cursor.read_u32::<BigEndian>()?,
            cursor.read_u32::<BigEndian>()?,
            cursor.read_u32::<BigEndian>()?,
            cursor.read_u32::<BigEndian>()?,
            cursor.read_u32::<BigEndian>()?,
        )
    } else {
        (
            cursor.read_u32::<LittleEndian>()?,
            cursor.read_u32::<LittleEndian>()?,
            cursor.read_u32::<LittleEndian>()?,
            cursor.read_u32::<LittleEndian>()?,
            cursor.read_u32::<LittleEndian>()?,
            cursor.read_u32::<LittleEndian>()?,
            cursor.read_u32::<LittleEndian>()?,
            cursor.read_u32::<LittleEndian>()?,
        )
    };

    // Skip dummy entries
    if codec_raw == 0xFFFFFFFF || data_size == 0 {
        return Ok(None);
    }

    let codec = ScdCodec::from(codec_raw);

    // Calculate data offset (header size + extra data + aux chunks)
    // Stream header is 0x20 bytes, followed by extra data
    let data_offset = 0x20 + extra_data_size + (aux_chunk_count * 8);

    Ok(Some(ScdStreamInfo {
        index,
        data_size,
        channels,
        sample_rate,
        codec,
        loop_start,
        loop_end,
        extra_data_size,
        aux_chunk_count,
        data_offset,
    }))
}

/// Estimate duration in seconds based on codec and data size.
fn estimate_duration(info: &ScdStreamInfo) -> f32 {
    if info.sample_rate == 0 || info.channels == 0 {
        return 0.0;
    }

    let samples = match info.codec {
        ScdCodec::PcmBe | ScdCodec::PcmLe => {
            // 16-bit PCM: 2 bytes per sample per channel
            info.data_size / (2 * info.channels)
        }
        ScdCodec::MsAdpcm => {
            // MS-ADPCM: roughly 4:1 compression
            // More accurate: block-based, but this is an estimate
            (info.data_size * 2) / info.channels
        }
        ScdCodec::OggVorbis => {
            // Vorbis: variable bitrate, rough estimate at 128kbps
            let bits = info.data_size * 8;
            let bitrate = 128000; // approximate
            return bits as f32 / bitrate as f32;
        }
        _ => {
            // Fallback estimate
            info.data_size / info.channels
        }
    };

    samples as f32 / info.sample_rate as f32
}

/// Extract raw audio stream data from SCD.
pub fn extract_stream_data(data: &[u8], stream_info: &ScdStreamInfo, stream_offset: u64) -> Result<Vec<u8>> {
    let start = stream_offset as usize + stream_info.data_offset as usize;
    let end = start + stream_info.data_size as usize;

    if end > data.len() {
        bail!("Stream data extends beyond file: {} > {}", end, data.len());
    }

    Ok(data[start..end].to_vec())
}

/// Get the offset of a stream in the SCD file.
pub fn get_stream_offset(data: &[u8], header: &ScdHeader, stream_index: u32) -> Result<u64> {
    let mut cursor = Cursor::new(data);

    // Read sub-header
    cursor.seek(SeekFrom::Start(header.tables_offset as u64))?;
    let sub_header = read_sub_header(&mut cursor, header.big_endian)?;

    // Read stream offset from table
    let table_entry_offset = sub_header.stream_info_offset as u64 + (stream_index as u64 * 4);
    cursor.seek(SeekFrom::Start(table_entry_offset))?;

    let stream_offset = if header.big_endian {
        cursor.read_u32::<BigEndian>()?
    } else {
        cursor.read_u32::<LittleEndian>()?
    };

    Ok(stream_offset as u64)
}
