//! # ZTR Text Decoder
//!
//! Converts raw binary text data from ZTR files into human-readable strings
//! with control codes represented as `{Tag}` placeholders.
//!
//! ## Control Code Categories
//!
//! | Category      | Byte Range    | Example                      |
//! |---------------|---------------|------------------------------|
//! | Single Keys   | 0x00-0x05     | `{End}`, `{Escape}`          |
//! | Color Keys    | 0xF9 XX       | `{Color White}`, `{Color Gold}` |
//! | Icon Keys     | 0xF0/0xF2 XX  | `{Icon Gil}`, `{Icon Sword}` |
//! | Button Keys   | 0xF1 XX       | `{Btn A}`, `{Btn Start}`     |
//! | Special Keys  | 0xF4-0xF7 XX  | `{Entity 1}`, `{Text NewLine}` |
//! | Character Keys| 0x85 XX       | Extended Latin characters    |
//!
//! ## Shift-JIS Handling
//!
//! Non-control bytes are decoded as Shift-JIS (Japanese encoding).
//! The decoder automatically detects Shift-JIS lead bytes and decodes
//! two-byte sequences appropriately.

use super::key_dicts::{
    GameCode, KeyDictionaries, BASE_CHARA_KEYS, EX_CHARA_KEYS, SINGLE_KEYS, SPECIAL_KEYS,
    UNK2_KEYS, UNK_KEYS,
};

/// Decodes raw binary text data into a human-readable string.
///
/// This function converts the raw bytes from a ZTR text entry into a
/// UTF-8 string where control codes are represented as `{Tag}` placeholders.
///
/// # Arguments
/// * `data` - Raw binary text data from ZTR file
/// * `game_code` - Which FF13 game (affects color/icon dictionaries)
/// * `_encoding` - Encoding hint (currently ignored, Shift-JIS assumed)
///
/// # Returns
/// A UTF-8 string with control codes as `{Tag}` placeholders.
///
/// # Example
/// ```rust,ignore
/// use fabula_nova_sdk::modules::ztr::{decode_ztr_line, GameCode};
///
/// let raw = vec![0xF9, 0x40, 0x48, 0x69, 0x00, 0x00];
/// let text = decode_ztr_line(&raw, GameCode::FF13_1, "Shift-JIS");
/// assert_eq!(text, "{Color White}Hi");
/// ```
///
/// # Algorithm
/// 1. Check if current byte is a single-byte control code
/// 2. Check if current + next byte form a two-byte control code
/// 3. Check if bytes are valid Shift-JIS sequence
/// 4. Fall back to hex representation `{XX}` for unknown bytes
pub fn decode_ztr_line(
    data: &[u8], 
    game_code: GameCode, 
    _encoding: &str // "Shift-JIS", etc. For now we assume Shift-JIS / UTF-8 hybrid as per C# logic
) -> String {
    let dicts = KeyDictionaries::get(game_code);
    let mut result = Vec::new();
    let mut i = 0;
    
    while i < data.len() {
        let b1 = data[i];
        
        // Single Key Check
        if let Some(key) = SINGLE_KEYS.get(&b1) {
            if b1 == 0 {
                if i + 1 < data.len() && data[i+1] == 0 {
                     // Terminator 00 00, skip both, emit nothing
                     i += 2;
                     continue;
                }
            }
            
            result.extend_from_slice(key.as_bytes());
            i += 1;
            continue;
        }
        
        // Double Byte Check
        if i + 1 < data.len() {
            let b2 = data[i+1];
            let pair = (b1, b2);
            
            if let Some(key) = dicts.color_keys.get(&pair) {
                result.extend_from_slice(key.as_bytes());
                i += 2;
                continue;
            }
            if let Some(key) = dicts.icon_keys.get(&pair) {
                result.extend_from_slice(key.as_bytes());
                i += 2;
                continue;
            }
            if let Some(key) = dicts.btn_keys.get(&pair) {
                result.extend_from_slice(key.as_bytes());
                i += 2;
                continue;
            }
            if let Some(key) = BASE_CHARA_KEYS.get(&pair) {
                result.extend_from_slice(key.as_bytes());
                i += 2;
                continue;
            }
            if let Some(key) = SPECIAL_KEYS.get(&pair) {
                result.extend_from_slice(key.as_bytes());
                i += 2;
                continue;
            }
            if let Some(key) = EX_CHARA_KEYS.get(&pair) {
                result.extend_from_slice(key.as_bytes());
                i += 2;
                continue;
            }
            if let Some(key) = UNK_KEYS.get(&pair) {
                result.extend_from_slice(key.as_bytes());
                i += 2;
                continue;
            }
            if let Some(key) = UNK2_KEYS.get(&pair) {
                result.extend_from_slice(key.as_bytes());
                i += 2;
                continue;
            }
        }
        
        // Default Decoding
        // In C#, it checks for ShiftJIS range.
        // Rust's encoding_rs can handle ShiftJIS.
        // But we need to handle mixed content.
        
        // Simple fallback: if valid ASCII, write it. If not, write as byte?
        // Or strictly follow C# ShiftJISCharaCheck.
        
        if is_shift_jis_start(b1) && i + 1 < data.len() {
             // Let encoding_rs handle the pair?
             // Or just pass raw bytes for now?
             // result.push(b1);
             // result.push(data[i+1]);
             
             // Decoding Shift-JIS to UTF-8
             let chunk = &data[i..i+2];
             let (res, _, _) = encoding_rs::SHIFT_JIS.decode(chunk);
             result.extend_from_slice(res.as_bytes());
             i += 2;
        } else if b1 < 0x80 {
             result.push(b1);
             i += 1;
        } else {
             // Unknown or unmapped control code
             let hex = format!("{{{:02X}}}", b1);
             result.extend_from_slice(hex.as_bytes());
             i += 1;
        }
    }
    
    String::from_utf8_lossy(&result).into_owned()
}

fn is_shift_jis_start(b: u8) -> bool {
    // C# Logic from KeysDecoderLJ.cs (ShiftJISCharaCheck)
    // It only allows specific ranges.
    // Range 1: 0x81 .. 0x84, 0x87, 0x88, 0x98, 0xEA, 0xFA..0xFC
    // Range 2: 0x89..0x97
    // Range 3: 0x99..0x9F
    // Range 4: 0xE0..0xE9
    
    // Notably, it DOES NOT include 0xF0..0xF9 (except specific cases?)
    // ColorKeys: 0xF9
    // IconKeys: 0xF0, 0xF2
    // BtnKeys: 0xF1
    // SpecialKeys: 0xF4, 0xF6, 0xF7
    // BaseCharaKeys: 0x85
    // UnkKeys: 0xFF, 0x81, 0xFA
    
    // My previous check `(b >= 0xE0 && b <= 0xFC)` included F0-FC.
    // I need to exclude the key ranges.
    
    match b {
        0x81..=0x84 => true,
        0x87 => true,
        0x88 => true,
        0x98 => true,
        0xEA => true,
        0xFA..=0xFC => true, // Wait, 0xFA is used for UnkKeys? But also SJIS? C# checks ranges of 2nd byte.
        0x89..=0x97 => true,
        0x99..=0x9F => true,
        0xE0..=0xE9 => true,
        _ => false,
    }
}
