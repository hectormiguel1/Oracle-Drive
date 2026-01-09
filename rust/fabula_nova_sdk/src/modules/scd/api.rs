//! Public API for SCD parsing and decoding.

use std::path::Path;
use std::fs;
use anyhow::{Result, Context};

use super::structs::*;
use super::reader;
use super::decoder;

/// Parse SCD file and return metadata (without decoding audio).
pub fn parse_scd_metadata<P: AsRef<Path>>(path: P) -> Result<ScdMetadata> {
    let path = path.as_ref();
    let name = path.file_name()
        .and_then(|n| n.to_str())
        .unwrap_or("unknown.scd");

    let data = fs::read(path)
        .with_context(|| format!("Failed to read SCD file: {}", path.display()))?;

    reader::parse_scd(&data, name)
}

/// Parse SCD from bytes and return metadata.
pub fn parse_scd_metadata_bytes(data: &[u8], name: &str) -> Result<ScdMetadata> {
    reader::parse_scd(data, name)
}

/// Parse and decode all audio streams from an SCD file.
pub fn decode_scd<P: AsRef<Path>>(path: P) -> Result<ScdExtractResult> {
    let path = path.as_ref();
    let name = path.file_name()
        .and_then(|n| n.to_str())
        .unwrap_or("unknown.scd");

    let data = fs::read(path)
        .with_context(|| format!("Failed to read SCD file: {}", path.display()))?;

    decode_scd_bytes(&data, name)
}

/// Parse and decode all audio streams from SCD bytes.
pub fn decode_scd_bytes(data: &[u8], name: &str) -> Result<ScdExtractResult> {
    let metadata = reader::parse_scd(data, name)?;
    let mut audio_streams = Vec::new();

    for stream in &metadata.streams {
        // Get stream offset
        let stream_offset = reader::get_stream_offset(data, &metadata.header, stream.index)?;

        // Extract extra data (codec-specific header)
        let extra_start = stream_offset as usize + 0x20; // After stream info header
        let extra_end = extra_start + stream.extra_data_size as usize;
        let extra_data = if extra_end <= data.len() {
            &data[extra_start..extra_end]
        } else {
            &[]
        };

        // Extract raw stream data
        let stream_data = reader::extract_stream_data(data, stream, stream_offset)?;

        // Decode the stream
        match decoder::decode_stream(&stream_data, stream, extra_data) {
            Ok(decoded) => audio_streams.push(decoded),
            Err(e) => {
                eprintln!("Warning: Failed to decode stream {}: {}", stream.index, e);
                // Continue with other streams
            }
        }
    }

    Ok(ScdExtractResult {
        metadata,
        audio_streams,
    })
}

/// Decode a specific stream from an SCD file.
pub fn decode_scd_stream<P: AsRef<Path>>(path: P, stream_index: u32) -> Result<DecodedAudio> {
    let path = path.as_ref();
    let name = path.file_name()
        .and_then(|n| n.to_str())
        .unwrap_or("unknown.scd");

    let data = fs::read(path)
        .with_context(|| format!("Failed to read SCD file: {}", path.display()))?;

    decode_scd_stream_bytes(&data, name, stream_index)
}

/// Decode a specific stream from SCD bytes.
pub fn decode_scd_stream_bytes(data: &[u8], name: &str, stream_index: u32) -> Result<DecodedAudio> {
    let metadata = reader::parse_scd(data, name)?;

    let stream = metadata.streams.iter()
        .find(|s| s.index == stream_index)
        .ok_or_else(|| anyhow::anyhow!("Stream {} not found in SCD", stream_index))?;

    // Get stream offset
    let stream_offset = reader::get_stream_offset(data, &metadata.header, stream.index)?;

    // Extract extra data
    let extra_start = stream_offset as usize + 0x20;
    let extra_end = extra_start + stream.extra_data_size as usize;
    let extra_data = if extra_end <= data.len() {
        &data[extra_start..extra_end]
    } else {
        &[]
    };

    // Extract and decode
    let stream_data = reader::extract_stream_data(data, stream, stream_offset)?;
    decoder::decode_stream(&stream_data, stream, extra_data)
}

/// Convert SCD file to WAV bytes (first stream).
pub fn scd_to_wav_bytes<P: AsRef<Path>>(path: P) -> Result<Vec<u8>> {
    let result = decode_scd(path)?;

    if result.audio_streams.is_empty() {
        anyhow::bail!("No audio streams found in SCD file");
    }

    Ok(result.audio_streams[0].to_wav_bytes())
}

/// Convert SCD bytes to WAV bytes (first stream).
pub fn scd_bytes_to_wav_bytes(data: &[u8], name: &str) -> Result<Vec<u8>> {
    let result = decode_scd_bytes(data, name)?;

    if result.audio_streams.is_empty() {
        anyhow::bail!("No audio streams found in SCD file");
    }

    Ok(result.audio_streams[0].to_wav_bytes())
}

/// Extract SCD to WAV file.
pub fn extract_scd_to_wav<P: AsRef<Path>>(scd_path: P, wav_path: P) -> Result<()> {
    let wav_bytes = scd_to_wav_bytes(&scd_path)?;
    fs::write(wav_path.as_ref(), &wav_bytes)
        .with_context(|| format!("Failed to write WAV file: {}", wav_path.as_ref().display()))?;
    Ok(())
}

/// Convert WAV file to SCD format.
///
/// Creates an SCD container with PCM audio (codec 0x01).
/// This is the simplest format and most compatible.
pub fn wav_to_scd<P: AsRef<Path>>(wav_path: P, scd_path: P) -> Result<()> {
    use std::io::{Cursor, Write};
    use byteorder::{LittleEndian, BigEndian, WriteBytesExt};

    // Read WAV file
    let wav_data = fs::read(wav_path.as_ref())?;

    // Parse WAV header to get audio info
    if wav_data.len() < 44 || &wav_data[0..4] != b"RIFF" || &wav_data[8..12] != b"WAVE" {
        anyhow::bail!("Invalid WAV file");
    }

    // Find fmt chunk
    let mut pos = 12;
    let mut sample_rate = 0u32;
    let mut channels = 0u16;
    let mut bits_per_sample = 0u16;
    let mut audio_data: &[u8] = &[];

    while pos + 8 <= wav_data.len() {
        let chunk_id = &wav_data[pos..pos + 4];
        let chunk_size = u32::from_le_bytes([wav_data[pos + 4], wav_data[pos + 5], wav_data[pos + 6], wav_data[pos + 7]]) as usize;

        if chunk_id == b"fmt " {
            channels = u16::from_le_bytes([wav_data[pos + 10], wav_data[pos + 11]]);
            sample_rate = u32::from_le_bytes([wav_data[pos + 12], wav_data[pos + 13], wav_data[pos + 14], wav_data[pos + 15]]);
            bits_per_sample = u16::from_le_bytes([wav_data[pos + 22], wav_data[pos + 23]]);
        }

        if chunk_id == b"data" {
            audio_data = &wav_data[pos + 8..pos + 8 + chunk_size.min(wav_data.len() - pos - 8)];
            break;
        }

        pos += 8 + chunk_size;
        if chunk_size % 2 == 1 {
            pos += 1;
        }
    }

    if audio_data.is_empty() {
        anyhow::bail!("No audio data found in WAV");
    }

    // Build SCD file
    let mut scd = Cursor::new(Vec::new());

    // SEDBSSCF header (big endian)
    scd.write_all(b"SEDBSSCF")?;                    // Magic
    scd.write_u32::<BigEndian>(3)?;                 // Version
    scd.write_u8(1)?;                               // Big endian flag
    scd.write_u8(0)?;                               // SSCF version
    scd.write_u16::<BigEndian>(0x30)?;              // Header size
    scd.write_u32::<BigEndian>(audio_data.len() as u32 + 0x60)?; // Total size

    // Padding to 0x30
    scd.write_all(&[0u8; 0x30 - 0x14])?;

    // Offsets table (simplified - just one stream)
    let stream_info_offset = 0x40u16;
    let stream_data_offset = 0x60u32;

    scd.write_u16::<BigEndian>(1)?;                 // Table count
    scd.write_u16::<BigEndian>(0)?;                 // Padding
    scd.write_u16::<BigEndian>(stream_info_offset)?; // Stream info offset
    scd.write_u16::<BigEndian>(0)?;                 // Padding

    // Padding to stream info
    let current_pos = scd.position() as usize;
    scd.write_all(&vec![0u8; stream_info_offset as usize - current_pos])?;

    // Stream info header (0x20 bytes)
    scd.write_u32::<LittleEndian>(audio_data.len() as u32)?; // Stream size
    scd.write_u32::<LittleEndian>(channels as u32)?;         // Channels
    scd.write_u32::<LittleEndian>(sample_rate)?;             // Sample rate
    scd.write_u32::<LittleEndian>(0x01)?;                    // Codec: PCM LE
    scd.write_u32::<LittleEndian>(audio_data.len() as u32 / (channels as u32 * bits_per_sample as u32 / 8))?; // Loop start
    scd.write_u32::<LittleEndian>(0)?;                       // Loop end
    scd.write_u32::<LittleEndian>(0)?;                       // Extra data size
    scd.write_u32::<LittleEndian>(0)?;                       // Aux chunk count

    // Padding to stream data
    let current_pos = scd.position() as usize;
    scd.write_all(&vec![0u8; stream_data_offset as usize - current_pos])?;

    // Audio data
    scd.write_all(audio_data)?;

    // Write to file
    fs::write(scd_path.as_ref(), scd.into_inner())?;

    Ok(())
}
