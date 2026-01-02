//! # ZTR Text Encoder
//!
//! Converts human-readable text with `{Tag}` placeholders back into the
//! binary format used by ZTR files.
//!
//! ## Supported Tag Formats
//!
//! - **Control Tags**: `{Color White}`, `{Btn A}`, `{Icon Gil}`, etc.
//! - **Hex Tags**: `{XX}` for arbitrary byte values (e.g., `{F9}`)
//! - **Literal Text**: Regular characters encoded as Shift-JIS
//!
//! ## Encoding Process
//!
//! 1. Scan for `{` to find tag start
//! 2. Extract tag content until `}`
//! 3. Look up tag in dictionaries (reverse mappings)
//! 4. If not found, check for hex format `{XX}`
//! 5. If still not found, treat as literal text
//! 6. For regular characters, encode as Shift-JIS
//!
//! ## Note
//! The encoder does NOT add the double-null terminator (0x00 0x00).
//! That is handled by the ZtrWriter.

use super::key_dicts::{
    GameCode, KeyDictionaries, REV_BASE_CHARA_KEYS, REV_EX_CHARA_KEYS, REV_SINGLE_KEYS,
    REV_SPECIAL_KEYS, REV_UNK2_KEYS, REV_UNK_KEYS,
};

/// Encodes a human-readable text string back to ZTR binary format.
///
/// This is the inverse of [`decode_ztr_line`]. It converts `{Tag}` placeholders
/// back to their binary control code representations.
///
/// # Arguments
/// * `text` - Human-readable text with `{Tag}` placeholders
/// * `game_code` - Which FF13 game (affects control code mappings)
/// * `_encoding` - Encoding hint (currently ignored, Shift-JIS assumed)
///
/// # Returns
/// A vector of bytes in ZTR binary format.
///
/// # Example
/// ```rust,ignore
/// use fabula_nova_sdk::modules::ztr::{encode_ztr_line, GameCode};
///
/// let text = "{Color White}Hello";
/// let bytes = encode_ztr_line(text, GameCode::FF13_1, "Shift-JIS");
/// // bytes = [0xF9, 0x40, 0x48, 0x65, 0x6C, 0x6C, 0x6F]
/// ```
///
/// # Tag Resolution Order
/// 1. Single-byte keys (e.g., `{End}` → 0x00)
/// 2. Color keys (game-specific)
/// 3. Icon keys (game-specific)
/// 4. Button keys (game-specific)
/// 5. Base character keys
/// 6. Special keys
/// 7. Extended character keys
/// 8. Unknown keys
/// 9. Hex format `{XX}`
/// 10. Literal text (as Shift-JIS)
pub fn encode_ztr_line(
    text: &str, 
    game_code: GameCode, 
    _encoding: &str
) -> Vec<u8> {
    let dicts = KeyDictionaries::get(game_code);
    let mut result = Vec::new();
    
    // Simple tokenizer: split by '{' and '}'
    // "{Color Red}Hello" -> ["", "Color Red", "Hello"] (if we keep delimiters?)
    // Manual scan is safer.
    
    let mut chars = text.chars().peekable();
    
    while let Some(c) = chars.next() {
        if c == '{' {
            // Potential tag
            let mut tag_content = String::new();
            let mut closed = false;
            
            // Peek ahead to consume tag
            // Note: `chars` is an iterator, we can't easily peek multiple chars or clone it efficiently without consuming.
            // Better to just consume and append to buffer, if we fail to find '}', backtrack? 
            // Or just treat as text.
            // C# logic just looks for known keys.
            
            // We'll accumulate until '}'
            while let Some(&next_c) = chars.peek() {
                chars.next(); // Consume
                if next_c == '}' {
                    closed = true;
                    break;
                }
                tag_content.push(next_c);
            }
            
            if closed {
                // Remove spaces for loose matching? C# keys are specific strings e.g. "{Color White}"
                // My dictionaries have "{Color White}".
                // So I construct the tag "{Color White}".
                let tag_str = format!("{{{}}}", tag_content);
                
                // Try to find in dictionaries
                if let Some(&byte) = REV_SINGLE_KEYS.get(tag_str.as_str()) {
                    result.push(byte);
                } else if let Some(&(b1, b2)) = dicts.rev_color_keys.get(tag_str.as_str()) {
                    result.push(b1);
                    result.push(b2);
                } else if let Some(&(b1, b2)) = dicts.rev_icon_keys.get(tag_str.as_str()) {
                    result.push(b1);
                    result.push(b2);
                } else if let Some(&(b1, b2)) = dicts.rev_btn_keys.get(tag_str.as_str()) {
                    result.push(b1);
                    result.push(b2);
                } else if let Some(&(b1, b2)) = REV_BASE_CHARA_KEYS.get(tag_str.as_str()) {
                    result.push(b1);
                    result.push(b2);
                } else if let Some(&(b1, b2)) = REV_SPECIAL_KEYS.get(tag_str.as_str()) {
                    result.push(b1);
                    result.push(b2);
                } else if let Some(&(b1, b2)) = REV_EX_CHARA_KEYS.get(tag_str.as_str()) {
                    result.push(b1);
                    result.push(b2);
                } else if let Some(&(b1, b2)) = REV_UNK_KEYS.get(tag_str.as_str()) {
                    result.push(b1);
                    result.push(b2);
                } else if let Some(&(b1, b2)) = REV_UNK2_KEYS.get(tag_str.as_str()) {
                    result.push(b1);
                    result.push(b2);
                } else if tag_content.len() == 2 && tag_content.chars().all(|c| c.is_ascii_hexdigit()) {
                    // Hex tag {XX}
                    if let Ok(byte) = u8::from_str_radix(&tag_content, 16) {
                        result.push(byte);
                    } else {
                        result.extend_from_slice(tag_str.as_bytes());
                    }
                } else {
                    // Unknown tag, treat as literal text
                    // "{Unknown}"
                    result.extend_from_slice(tag_str.as_bytes());
                }
            } else {
                // Not closed, treat as text
                result.push(b'{');
                result.extend_from_slice(tag_content.as_bytes());
            }
        } else {
            // Normal char
            // Use shift-jis encoder
            let s = c.to_string();
            let (res, _, _) = encoding_rs::SHIFT_JIS.encode(&s);
            result.extend_from_slice(&res);
        }
    }
    
    // Check if we need to append 0x00 0x00?
    // C# ZTRExtract decodes until 0x00 0x00 or EOF.
    // ZTRConvert appends 0x00 0x00.
    // My Writer does: `processed_lines.push(0); processed_lines.push(0);`
    // So the encoder just returns the content bytes.
    // BUT `SingleKeys` has `{End}` -> 0x00.
    // If the input string has `{End}`, we write 0x00.
    // Users might explicitely write `{End}`.
    // If they don't, Writer appends terminators.
    
    result
}
