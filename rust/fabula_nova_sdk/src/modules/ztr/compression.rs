//! # ZTR Compression Module
//!
//! Implements byte-pair encoding (BPE) compression for ZTR text data.
//! This compression scheme replaces frequently occurring two-byte pairs
//! with single-byte references.
//!
//! ## Algorithm Overview
//!
//! 1. Find byte values not used in the data (available "page indices")
//! 2. Find the most frequently occurring two-byte pair
//! 3. If frequency >= 4, replace all occurrences with a page index
//! 4. Record the mapping in the dictionary
//! 5. Repeat until no more beneficial replacements
//!
//! ## Output Format
//!
//! ```text
//! [DictLength: 4 bytes, big-endian]
//! [Dictionary: DictLength bytes]
//!   - Each entry: [PageIndex, Byte1, Byte2] (3 bytes)
//! [Compressed Data]
//! ```
//!
//! ## Decompression
//!
//! When reading, any byte matching a PageIndex is expanded to its
//! two-byte sequence. Expansion can be recursive if those bytes are
//! also PageIndices.
//!
//! ## Compression Ratio
//!
//! Typical compression ratios range from 1.2x to 2x for text data
//! with repetitive patterns. Highly unique text may not compress well.

use std::collections::HashMap;

/// Compresses a chunk of data using byte-pair encoding.
///
/// This function implements the ZTR compression algorithm, which replaces
/// frequently occurring byte pairs with single-byte references stored in
/// a dictionary.
///
/// # Arguments
/// * `data` - The raw byte data to compress
///
/// # Returns
/// A vector containing:
/// - 4 bytes: Dictionary length (big-endian u32)
/// - N bytes: Dictionary entries (3 bytes each)
/// - Remaining: Compressed data
///
/// # Compression Threshold
/// Only byte pairs occurring 4+ times are replaced. This ensures the
/// dictionary overhead doesn't exceed the space savings.
///
/// # Example
/// ```rust,ignore
/// let data = b"ABABABAB";
/// let compressed = compress_chunk(data);
/// // compressed = [0,0,0,3, PageIdx,'A','B', PageIdx,PageIdx,PageIdx,PageIdx]
/// ```
pub fn compress_chunk(data: &[u8]) -> Vec<u8> {
    let mut current_data = data.to_vec();
    let mut page_indices = get_page_numbers(&current_data);
    let mut dict_entries = Vec::new(); // Stores (page_index, b1, b2)

    loop {
        // Optimization: if no page indices left, break early
        if page_indices.is_empty() {
            break;
        }

        let (b1, b2, count) = get_largest_occuring_bytes(&current_data);
        
        // Threshold from C# is < 4
        if count < 4 {
            break;
        }

        let page_index = page_indices.remove(0);
        dict_entries.push(page_index);
        dict_entries.push(b1);
        dict_entries.push(b2);

        // Replace occurrences
        let mut new_data = Vec::with_capacity(current_data.len());
        let mut i = 0;
        while i < current_data.len() {
            if i < current_data.len() - 1 && current_data[i] == b1 && current_data[i+1] == b2 {
                new_data.push(page_index);
                i += 2;
            } else {
                new_data.push(current_data[i]);
                i += 1;
            }
        }
        current_data = new_data;
    }

    // Serialize
    let dict_len = dict_entries.len() as u32;
    let mut result = Vec::new();
    result.extend_from_slice(&dict_len.to_be_bytes()); // Big Endian length
    result.extend_from_slice(&dict_entries);
    result.extend_from_slice(&current_data);
    
    result
}

fn get_page_numbers(data: &[u8]) -> Vec<u8> {
    let mut present = [false; 256];
    for &b in data {
        present[b as usize] = true;
    }
    
    let mut pages = Vec::new();
    for i in 0..=255 {
        // C# specific: "if (b == 8) continue;" (Backspace?)
        if i == 8 { continue; }
        
        if !present[i as usize] {
            pages.push(i as u8);
        }
    }
    pages
}

fn get_largest_occuring_bytes(data: &[u8]) -> (u8, u8, usize) {
    if data.len() < 2 {
        return (0, 0, 0);
    }

    let mut counts: HashMap<(u8, u8), usize> = HashMap::new();
    let mut i = 0;
    while i < data.len() - 1 {
        let pair = (data[i], data[i+1]);
        *counts.entry(pair).or_insert(0) += 1;
        // Optimization: C# code jumps `j++` inside the loop, effectively counting non-overlapping occurrences.
        // But the C# `checkedBytesDict` loop iterates linearly?
        // Let's re-read C# closely.
        // It iterates i from 0 to end.
        // Then inner loop j from i+2.
        // If match, increment count and j++.
        // This implies non-overlapping counting for a SPECIFIC pair starting at i.
        // But since it iterates i, it finds the global max.
        // My simple hashmap count might count overlapping? e.g. AAAA -> (AA, 3) vs (AA, 2).
        // C# logic: for pair at i, count future occurrences.
        // This IS non-overlapping count.
        // I should replicate non-overlapping count.
        
        i += 1; // This is just traversing to finding candidate pairs.
    }
    
    // Correct logic:
    // We need to find the pair with max NON-OVERLAPPING occurrences.
    // Iterating all pairs and counting non-overlapping is O(N^2) or O(N*UniquePairs).
    
    // To be efficient and correct:
    // Collect all unique pairs first?
    // Or just iterate distinct pairs?
    
    // C# implementation is slow O(N^2). We can do better but let's stick to correctness.
    // However, I'll use a slightly optimized approach.
    
    // 1. Get frequencies of all pairs (potentially overlapping) to find candidates.
    // 2. For top candidates, verify non-overlapping count.
    
    // Actually, let's just do it the greedy way for the top pair.
    
    let mut best_count = 0;
    let mut best_pair = (0, 0);
    let mut checked = HashMap::new();

    for i in 0..data.len() - 1 {
        let b1 = data[i];
        let b2 = data[i+1];
        let pair = (b1, b2);
        
        if checked.contains_key(&pair) {
            continue;
        }
        
        // Count non-overlapping for this pair
        let mut count = 1;
        let mut j = i + 2;
        while j < data.len() - 1 {
            if data[j] == b1 && data[j+1] == b2 {
                count += 1;
                j += 2;
            } else {
                j += 1;
            }
        }
        
        checked.insert(pair, count);
        
        if count > best_count {
            best_count = count;
            best_pair = pair;
        }
    }

    (best_pair.0, best_pair.1, best_count)
}
