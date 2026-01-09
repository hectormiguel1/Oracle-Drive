//! Audio decoders for SCD streams.

use anyhow::{Result, bail};
use super::structs::*;

/// MS-ADPCM adaptation table.
const ADAPTATION_TABLE: [i32; 16] = [
    230, 230, 230, 230, 307, 409, 512, 614,
    768, 614, 512, 409, 307, 230, 230, 230,
];

/// MS-ADPCM coefficient pairs.
const ADAPTATION_COEFF: [(i32, i32); 7] = [
    (256, 0),
    (512, -256),
    (0, 0),
    (192, 64),
    (240, 0),
    (460, -208),
    (392, -232),
];

/// Decode audio stream based on codec type.
pub fn decode_stream(
    data: &[u8],
    stream_info: &ScdStreamInfo,
    extra_data: &[u8],
) -> Result<DecodedAudio> {
    match stream_info.codec {
        ScdCodec::PcmLe => decode_pcm_le(data, stream_info),
        ScdCodec::PcmBe => decode_pcm_be(data, stream_info),
        ScdCodec::MsAdpcm => decode_ms_adpcm(data, stream_info, extra_data),
        ScdCodec::OggVorbis => decode_ogg_vorbis(data, stream_info, extra_data),
        codec => bail!("Unsupported codec: {:?} ({})", codec, codec.name()),
    }
}

/// Decode PCM little-endian (pass-through).
fn decode_pcm_le(data: &[u8], info: &ScdStreamInfo) -> Result<DecodedAudio> {
    let sample_count = data.len() / (2 * info.channels as usize);
    let duration = sample_count as f32 / info.sample_rate as f32;

    Ok(DecodedAudio {
        sample_rate: info.sample_rate,
        channels: info.channels as u16,
        bits_per_sample: 16,
        pcm_data: data.to_vec(),
        duration_seconds: duration,
        original_codec: "PCM".to_string(),
    })
}

/// Decode PCM big-endian (swap bytes).
fn decode_pcm_be(data: &[u8], info: &ScdStreamInfo) -> Result<DecodedAudio> {
    let mut output = Vec::with_capacity(data.len());

    // Swap bytes for each 16-bit sample
    for chunk in data.chunks(2) {
        if chunk.len() == 2 {
            output.push(chunk[1]);
            output.push(chunk[0]);
        }
    }

    let sample_count = output.len() / (2 * info.channels as usize);
    let duration = sample_count as f32 / info.sample_rate as f32;

    Ok(DecodedAudio {
        sample_rate: info.sample_rate,
        channels: info.channels as u16,
        bits_per_sample: 16,
        pcm_data: output,
        duration_seconds: duration,
        original_codec: "PCM".to_string(),
    })
}

/// Decode MS-ADPCM audio.
fn decode_ms_adpcm(data: &[u8], info: &ScdStreamInfo, extra_data: &[u8]) -> Result<DecodedAudio> {
    // Extract block align from extra data (WAVE format chunk)
    // Extra data should contain: format(2), channels(2), sample_rate(4), byte_rate(4), block_align(2), bits(2)
    let block_align = if extra_data.len() >= 14 {
        u16::from_le_bytes([extra_data[12], extra_data[13]]) as usize
    } else {
        // Default block size for MS-ADPCM (common values: 256, 512, 1024, 2048)
        // Calculate based on channels: typically 256 for mono, 512 for stereo
        if info.channels == 1 { 256 } else { 512 }
    };

    let channels = info.channels as usize;
    if channels == 0 || channels > 2 {
        bail!("Invalid channel count: {}", channels);
    }

    // MS-ADPCM block structure:
    // For each channel:
    //   - 1 byte: predictor index
    //   - 2 bytes: delta (initial step size)
    //   - 2 bytes: sample1 (first output sample)
    //   - 2 bytes: sample2 (second output sample, one before sample1)
    // Then nibble-packed samples

    let header_size = channels * 7; // 7 bytes per channel header
    let samples_per_block = 2 + ((block_align - header_size) * 2 / channels);

    let mut output: Vec<i16> = Vec::new();
    let mut pos = 0;

    while pos + block_align <= data.len() {
        let block = &data[pos..pos + block_align];
        decode_ms_adpcm_block(block, channels, samples_per_block, &mut output)?;
        pos += block_align;
    }

    // Convert i16 samples to bytes
    let mut pcm_data = Vec::with_capacity(output.len() * 2);
    for sample in output {
        pcm_data.extend_from_slice(&sample.to_le_bytes());
    }

    let sample_count = pcm_data.len() / (2 * channels);
    let duration = sample_count as f32 / info.sample_rate as f32;

    Ok(DecodedAudio {
        sample_rate: info.sample_rate,
        channels: channels as u16,
        bits_per_sample: 16,
        pcm_data,
        duration_seconds: duration,
        original_codec: "MS-ADPCM".to_string(),
    })
}

/// Decode a single MS-ADPCM block.
fn decode_ms_adpcm_block(
    block: &[u8],
    channels: usize,
    samples_per_block: usize,
    output: &mut Vec<i16>,
) -> Result<()> {
    let mut predictors = [0i32; 2];
    let mut deltas = [0i32; 2];
    let mut sample1 = [0i16; 2];
    let mut sample2 = [0i16; 2];

    let mut pos = 0;

    // Read headers for each channel
    for ch in 0..channels {
        let pred_idx = block[pos] as usize;
        if pred_idx >= ADAPTATION_COEFF.len() {
            predictors[ch] = 0;
        } else {
            predictors[ch] = pred_idx as i32;
        }
        pos += 1;
    }

    for ch in 0..channels {
        deltas[ch] = i16::from_le_bytes([block[pos], block[pos + 1]]) as i32;
        pos += 2;
    }

    for ch in 0..channels {
        sample1[ch] = i16::from_le_bytes([block[pos], block[pos + 1]]);
        pos += 2;
    }

    for ch in 0..channels {
        sample2[ch] = i16::from_le_bytes([block[pos], block[pos + 1]]);
        pos += 2;
    }

    // Output the initial samples (sample2 comes before sample1)
    if channels == 1 {
        output.push(sample2[0]);
        output.push(sample1[0]);
    } else {
        output.push(sample2[0]);
        output.push(sample2[1]);
        output.push(sample1[0]);
        output.push(sample1[1]);
    }

    // Decode nibble-packed samples
    let mut samples_decoded = 2;
    let data_bytes = &block[pos..];

    for byte in data_bytes {
        if samples_decoded >= samples_per_block {
            break;
        }

        // High nibble first, then low nibble
        for nibble_idx in 0..2 {
            let ch = if channels == 1 { 0 } else { (samples_decoded * channels + nibble_idx) % channels };

            let nibble = if nibble_idx == 0 {
                (byte >> 4) & 0x0F
            } else {
                byte & 0x0F
            };

            // Sign-extend nibble
            let signed_nibble = if nibble >= 8 {
                nibble as i32 - 16
            } else {
                nibble as i32
            };

            // Get coefficients
            let pred_idx = predictors[ch] as usize;
            let (coeff1, coeff2) = if pred_idx < ADAPTATION_COEFF.len() {
                ADAPTATION_COEFF[pred_idx]
            } else {
                (256, 0)
            };

            // Calculate predicted sample
            let predicted = ((coeff1 as i64 * sample1[ch] as i64
                + coeff2 as i64 * sample2[ch] as i64) >> 8) as i32;

            // Calculate new sample
            let mut new_sample = predicted + (signed_nibble * deltas[ch]);

            // Clamp to 16-bit range
            new_sample = new_sample.clamp(-32768, 32767);

            // Update delta
            deltas[ch] = (deltas[ch] * ADAPTATION_TABLE[nibble as usize]) >> 8;
            if deltas[ch] < 16 {
                deltas[ch] = 16;
            }

            // Update history
            sample2[ch] = sample1[ch];
            sample1[ch] = new_sample as i16;

            output.push(new_sample as i16);

            if nibble_idx == 1 || channels == 1 {
                samples_decoded += 1;
            }
        }
    }

    Ok(())
}

/// Decode Ogg Vorbis audio.
/// Note: FF13-2 and LR have XOR-encrypted Vorbis headers.
fn decode_ogg_vorbis(data: &[u8], info: &ScdStreamInfo, extra_data: &[u8]) -> Result<DecodedAudio> {
    // Check for OggS magic
    let is_raw_ogg = data.len() >= 4 && &data[0..4] == b"OggS";

    let ogg_data = if is_raw_ogg {
        data.to_vec()
    } else {
        // May need to handle XOR encryption or construct OGG header
        // For FF13 (not FF13-2/LR), Vorbis data might need header reconstruction
        decrypt_vorbis_data(data, extra_data)?
    };

    // Use lewton to decode
    #[cfg(feature = "vorbis")]
    {
        use lewton::inside_ogg::OggStreamReader;
        use std::io::Cursor;

        let cursor = Cursor::new(&ogg_data);
        let mut reader = OggStreamReader::new(cursor)
            .map_err(|e| anyhow::anyhow!("Failed to create OGG reader: {}", e))?;

        let channels = reader.ident_hdr.audio_channels as u16;
        let sample_rate = reader.ident_hdr.audio_sample_rate;

        let mut pcm_data: Vec<u8> = Vec::new();

        while let Some(packet) = reader.read_dec_packet_itl()
            .map_err(|e| anyhow::anyhow!("Vorbis decode error: {}", e))?
        {
            for sample in packet {
                // Clamp and convert to i16
                let clamped = sample.clamp(-32768, 32767) as i16;
                pcm_data.extend_from_slice(&clamped.to_le_bytes());
            }
        }

        let sample_count = pcm_data.len() / (2 * channels as usize);
        let duration = sample_count as f32 / sample_rate as f32;

        return Ok(DecodedAudio {
            sample_rate,
            channels,
            bits_per_sample: 16,
            pcm_data,
            duration_seconds: duration,
            original_codec: "Ogg Vorbis".to_string(),
        });
    }

    #[cfg(not(feature = "vorbis"))]
    {
        // Without vorbis feature, return a placeholder or error
        bail!("Vorbis decoding not enabled. Enable the 'vorbis' feature.");
    }
}

/// Decrypt XOR-encrypted Vorbis data (FF13-2/LR).
fn decrypt_vorbis_data(data: &[u8], extra_data: &[u8]) -> Result<Vec<u8>> {
    // XOR key is typically derived from extra_data or is a fixed magic number
    // For FF13-2/LR, the XOR key is in the partial header chunk

    if extra_data.len() < 4 {
        // No XOR needed or not enough data
        return Ok(data.to_vec());
    }

    // Check if this looks like encrypted data
    // Encrypted Vorbis won't start with OggS
    if data.len() >= 4 && &data[0..4] == b"OggS" {
        return Ok(data.to_vec());
    }

    // FF13-2/LR XOR decryption
    // The XOR table is typically 256 bytes derived from the seek table
    // For now, try common patterns

    // First, check if extra_data contains the XOR key/table
    let mut decrypted = data.to_vec();

    // Try simple byte XOR with first few bytes of extra_data
    if extra_data.len() >= 256 {
        for (i, byte) in decrypted.iter_mut().enumerate() {
            *byte ^= extra_data[i % extra_data.len()];
        }
    } else {
        // Simple XOR with repeated key
        for (i, byte) in decrypted.iter_mut().enumerate() {
            *byte ^= extra_data[i % extra_data.len()];
        }
    }

    // Check if decryption worked
    if decrypted.len() >= 4 && &decrypted[0..4] == b"OggS" {
        Ok(decrypted)
    } else {
        // Return original data if decryption didn't produce valid OGG
        Ok(data.to_vec())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_adaptation_table() {
        assert_eq!(ADAPTATION_TABLE.len(), 16);
        assert_eq!(ADAPTATION_COEFF.len(), 7);
    }
}
