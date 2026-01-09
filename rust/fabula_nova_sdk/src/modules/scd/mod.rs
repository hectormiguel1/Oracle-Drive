//! # SCD Module
//!
//! This module provides parsing and decoding for SCD (Sound Container Data) files.
//!
//! SCD files (`.scd`) are Square Enix proprietary audio containers used in
//! the Final Fantasy XIII trilogy. They contain:
//!
//! - Audio stream metadata (sample rate, channels, codec)
//! - One or more audio streams in various codecs
//! - Loop point information
//!
//! ## Supported Codecs
//!
//! - **PCM** (0x00/0x01): Uncompressed audio (big/little endian)
//! - **MS-ADPCM** (0x0C): Microsoft ADPCM, common in FF13 PC
//! - **Ogg Vorbis** (0x06): Used in FF13-2/LR (may be XOR encrypted)
//!
//! ## Quick Start
//!
//! ```rust,ignore
//! use fabula_nova_sdk::modules::scd;
//!
//! // Get metadata without decoding
//! let meta = scd::parse_scd_metadata("sound.scd")?;
//! println!("Streams: {}, Duration: {:.2}s", meta.streams.len(), meta.duration_seconds);
//!
//! // Decode to WAV bytes (for playback)
//! let wav_bytes = scd::scd_to_wav_bytes("sound.scd")?;
//!
//! // Or decode all streams
//! let result = scd::decode_scd("sound.scd")?;
//! for audio in result.audio_streams {
//!     println!("{}Hz, {} ch, {:.2}s", audio.sample_rate, audio.channels, audio.duration_seconds);
//! }
//! ```

pub mod api;
pub mod decoder;
pub mod reader;
pub mod structs;

// Re-export main API functions
pub use api::{
    decode_scd,
    decode_scd_bytes,
    decode_scd_stream,
    decode_scd_stream_bytes,
    extract_scd_to_wav,
    parse_scd_metadata,
    parse_scd_metadata_bytes,
    scd_bytes_to_wav_bytes,
    scd_to_wav_bytes,
};

// Re-export main types
pub use structs::{
    DecodedAudio,
    ScdCodec,
    ScdExtractResult,
    ScdHeader,
    ScdMetadata,
    ScdStreamInfo,
};

#[cfg(test)]
mod tests {
    use super::*;
    use std::path::Path;

    const SAMPLE_DIR: &str = "/home/hectorr/Development/Flutter/Oracle-Drive/ai_resources/sound";

    #[test]
    fn test_parse_scd_metadata() {
        let path = format!("{}/pack/1500/sh2_m001a.win32/sh2_m001aidle.scd", SAMPLE_DIR);
        if !Path::new(&path).exists() {
            println!("Skipping test: sample file not found at {}", path);
            return;
        }

        let meta = parse_scd_metadata(&path).expect("Failed to parse SCD");

        println!("SCD: {}", meta.name);
        println!("  Version: {}", meta.header.version);
        println!("  Streams: {}", meta.streams.len());
        println!("  Duration: {:.2}s", meta.duration_seconds);

        for stream in &meta.streams {
            println!("  Stream {}:", stream.index);
            println!("    Codec: {:?} ({})", stream.codec, stream.codec.name());
            println!("    Sample Rate: {} Hz", stream.sample_rate);
            println!("    Channels: {}", stream.channels);
            println!("    Data Size: {} bytes", stream.data_size);
        }

        assert!(!meta.streams.is_empty());
    }

    #[test]
    fn test_decode_scd() {
        let path = format!("{}/pack/1500/sh2_m001a.win32/sh2_m001aidle.scd", SAMPLE_DIR);
        if !Path::new(&path).exists() {
            println!("Skipping test: sample file not found at {}", path);
            return;
        }

        let result = decode_scd(&path).expect("Failed to decode SCD");

        println!("Decoded {} audio streams", result.audio_streams.len());

        for (i, audio) in result.audio_streams.iter().enumerate() {
            println!("  Audio {}:", i);
            println!("    Original Codec: {}", audio.original_codec);
            println!("    Sample Rate: {} Hz", audio.sample_rate);
            println!("    Channels: {}", audio.channels);
            println!("    Duration: {:.2}s", audio.duration_seconds);
            println!("    PCM Size: {} bytes", audio.pcm_data.len());
        }

        assert!(!result.audio_streams.is_empty());
    }

    #[test]
    fn test_scd_to_wav() {
        let path = format!("{}/pack/1500/sh2_m001a.win32/sh2_m001aidle.scd", SAMPLE_DIR);
        if !Path::new(&path).exists() {
            println!("Skipping test: sample file not found at {}", path);
            return;
        }

        let wav_bytes = scd_to_wav_bytes(&path).expect("Failed to convert to WAV");

        // Verify WAV header
        assert!(wav_bytes.len() > 44, "WAV too small");
        assert_eq!(&wav_bytes[0..4], b"RIFF", "Invalid WAV magic");
        assert_eq!(&wav_bytes[8..12], b"WAVE", "Invalid WAV format");

        println!("Generated WAV: {} bytes", wav_bytes.len());
    }

    #[test]
    fn test_parse_all_scd_samples() {
        if !Path::new(SAMPLE_DIR).exists() {
            println!("Skipping test: sample directory not found");
            return;
        }

        let mut success = 0;
        let mut failures = Vec::new();

        // Find all .scd files
        for entry in walkdir::WalkDir::new(SAMPLE_DIR)
            .into_iter()
            .filter_map(|e| e.ok())
        {
            let path = entry.path();
            if path.extension().map(|e| e == "scd").unwrap_or(false) {
                match parse_scd_metadata(path) {
                    Ok(meta) => {
                        success += 1;
                        let codecs: Vec<_> = meta.streams.iter()
                            .map(|s| format!("{:?}", s.codec))
                            .collect();
                        println!("OK: {} ({} streams: {})",
                            meta.name, meta.streams.len(), codecs.join(", "));
                    }
                    Err(e) => {
                        failures.push((path.display().to_string(), e.to_string()));
                    }
                }
            }
        }

        println!("\nParsed {} SCD files successfully", success);
        if !failures.is_empty() {
            println!("Failures:");
            for (path, err) in &failures {
                println!("  {}: {}", path, err);
            }
        }

        assert!(success > 0, "Expected at least some SCD files to parse");
    }
}
