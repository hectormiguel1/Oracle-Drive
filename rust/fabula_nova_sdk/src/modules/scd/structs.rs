//! SCD (Sound Container Data) structures.
//!
//! Square Enix proprietary audio container format used in the FF13 trilogy.

use serde::{Deserialize, Serialize};

/// Magic bytes for SCD files: "SEDBSSCF"
pub const SCD_MAGIC: &[u8; 8] = b"SEDBSSCF";

/// Audio codec types used in SCD files.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[repr(u32)]
pub enum ScdCodec {
    /// PCM signed 16-bit big-endian
    PcmBe = 0x00,
    /// PCM signed 16-bit little-endian
    PcmLe = 0x01,
    /// PlayStation ADPCM
    PsAdpcm = 0x03,
    /// Ogg Vorbis (may be XOR encrypted in FF13-2/LR)
    OggVorbis = 0x06,
    /// MPEG Audio (MP3, used on PS3)
    Mpeg = 0x07,
    /// MS-ADPCM (common in FF13 PC)
    MsAdpcm = 0x0C,
    /// XMA2 (Xbox 360)
    Xma2 = 0x0B,
    /// ATRAC3/ATRAC3plus
    Atrac = 0x0E,
    /// Unknown codec
    Unknown = 0xFF,
}

impl From<u32> for ScdCodec {
    fn from(value: u32) -> Self {
        match value {
            0x00 => ScdCodec::PcmBe,
            0x01 => ScdCodec::PcmLe,
            0x03 => ScdCodec::PsAdpcm,
            0x06 => ScdCodec::OggVorbis,
            0x07 => ScdCodec::Mpeg,
            0x0B => ScdCodec::Xma2,
            0x0C => ScdCodec::MsAdpcm,
            0x0E => ScdCodec::Atrac,
            _ => ScdCodec::Unknown,
        }
    }
}

impl ScdCodec {
    pub fn name(&self) -> &'static str {
        match self {
            ScdCodec::PcmBe => "PCM (Big Endian)",
            ScdCodec::PcmLe => "PCM (Little Endian)",
            ScdCodec::PsAdpcm => "PS-ADPCM",
            ScdCodec::OggVorbis => "Ogg Vorbis",
            ScdCodec::Mpeg => "MPEG Audio",
            ScdCodec::MsAdpcm => "MS-ADPCM",
            ScdCodec::Xma2 => "XMA2",
            ScdCodec::Atrac => "ATRAC3",
            ScdCodec::Unknown => "Unknown",
        }
    }
}

/// Main SCD file header (SEDBSSCF).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ScdHeader {
    /// File version (usually 3)
    pub version: u32,
    /// Whether file is big-endian
    pub big_endian: bool,
    /// Offset to tables section
    pub tables_offset: u16,
    /// Total file size
    pub file_size: u64,
}

/// Sub-header containing section counts and offsets.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ScdSubHeader {
    /// Number of entries in table 1
    pub table1_count: u16,
    /// Number of entries in table 2
    pub table2_count: u16,
    /// Number of audio streams
    pub stream_count: u16,
    /// Sound folder ID
    pub sound_folder_id: u16,
    /// Offset to table 2
    pub table2_offset: u32,
    /// Offset to stream info table
    pub stream_info_offset: u32,
    /// Offset to table 4
    pub table4_offset: u32,
}

/// Information about a single audio stream.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ScdStreamInfo {
    /// Index of this stream
    pub index: u32,
    /// Size of the audio data in bytes
    pub data_size: u32,
    /// Number of audio channels
    pub channels: u32,
    /// Sample rate in Hz
    pub sample_rate: u32,
    /// Audio codec type
    pub codec: ScdCodec,
    /// Loop start sample (0 if no loop)
    pub loop_start: u32,
    /// Loop end sample (0 if no loop)
    pub loop_end: u32,
    /// Size of extra codec-specific data
    pub extra_data_size: u32,
    /// Number of auxiliary chunks
    pub aux_chunk_count: u32,
    /// Offset to the audio data from stream header
    pub data_offset: u32,
}

/// Metadata for an SCD file.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ScdMetadata {
    /// Source file name
    pub name: String,
    /// File header info
    pub header: ScdHeader,
    /// Stream information
    pub streams: Vec<ScdStreamInfo>,
    /// Total duration in seconds (estimated)
    pub duration_seconds: f32,
}

/// Decoded audio data ready for playback.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DecodedAudio {
    /// Sample rate in Hz
    pub sample_rate: u32,
    /// Number of channels (1=mono, 2=stereo)
    pub channels: u16,
    /// Bits per sample (usually 16)
    pub bits_per_sample: u16,
    /// Raw PCM data as bytes (little-endian signed 16-bit samples)
    pub pcm_data: Vec<u8>,
    /// Duration in seconds
    pub duration_seconds: f32,
    /// Original codec that was decoded
    pub original_codec: String,
}

impl DecodedAudio {
    /// Get the number of samples (per channel)
    pub fn sample_count(&self) -> usize {
        let bytes_per_sample = (self.bits_per_sample / 8) as usize;
        self.pcm_data.len() / (self.channels as usize * bytes_per_sample)
    }

    /// Convert to WAV file bytes
    pub fn to_wav_bytes(&self) -> Vec<u8> {
        let data_size = self.pcm_data.len() as u32;
        let byte_rate = self.sample_rate * self.channels as u32 * (self.bits_per_sample / 8) as u32;
        let block_align = self.channels * (self.bits_per_sample / 8);

        let mut wav = Vec::with_capacity(44 + self.pcm_data.len());

        // RIFF header
        wav.extend_from_slice(b"RIFF");
        wav.extend_from_slice(&(36 + data_size).to_le_bytes());
        wav.extend_from_slice(b"WAVE");

        // fmt chunk
        wav.extend_from_slice(b"fmt ");
        wav.extend_from_slice(&16u32.to_le_bytes()); // chunk size
        wav.extend_from_slice(&1u16.to_le_bytes()); // PCM format
        wav.extend_from_slice(&self.channels.to_le_bytes());
        wav.extend_from_slice(&self.sample_rate.to_le_bytes());
        wav.extend_from_slice(&byte_rate.to_le_bytes());
        wav.extend_from_slice(&block_align.to_le_bytes());
        wav.extend_from_slice(&self.bits_per_sample.to_le_bytes());

        // data chunk
        wav.extend_from_slice(b"data");
        wav.extend_from_slice(&data_size.to_le_bytes());
        wav.extend_from_slice(&self.pcm_data);

        wav
    }
}

/// Result of extracting audio from an SCD file.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ScdExtractResult {
    /// Metadata about the SCD file
    pub metadata: ScdMetadata,
    /// Decoded audio streams (one per stream in the SCD)
    pub audio_streams: Vec<DecodedAudio>,
}
