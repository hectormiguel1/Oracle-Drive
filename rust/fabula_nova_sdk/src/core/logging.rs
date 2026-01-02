//! # Logging Module
//!
//! This module provides a comprehensive logging system designed specifically for
//! Flutter/Dart integration with hot-reload support.
//!
//! ## Features
//!
//! - **Ring Buffer Storage**: Logs are stored in a fixed-size ring buffer (500 entries)
//!   that persists across Flutter hot restarts. This ensures no logs are lost during
//!   development when hot reload is frequently used.
//!
//! - **Dual Retrieval Modes**:
//!   - **Callback-based**: Register a callback function to receive logs in real-time
//!   - **Polling-based**: Fetch new logs on demand using [`fetch_logs()`]
//!
//! - **Hot-Reload Safety**: The [`clear_log_callback()`] function prevents dangling
//!   references to dead Dart isolates after hot restart.
//!
//! - **Configurable Log Levels**: Supports Off, Error, Warn, Info, Debug, and Trace levels
//!
//! ## Log Format
//!
//! Logs are formatted as:
//! ```text
//! HH:MM:SS.mmm [MODULE_NAME] [LEVEL  ] filename@line: message
//! ```
//!
//! Example:
//! ```text
//! 14:32:15.123 [ZTR] [INFO  ] reader@45: Parsing ZTR file header
//! ```
//!
//! ## Usage
//!
//! ### Initialization
//! ```rust,ignore
//! use fabula_nova_sdk::core::logging;
//!
//! // Initialize the logger (call once at app startup)
//! logging::init_logger().expect("Failed to initialize logger");
//!
//! // Optionally set a callback for real-time log streaming
//! logging::set_log_callback(|msg| {
//!     println!("Log: {}", msg);
//! });
//! ```
//!
//! ### Polling for Logs (Recommended for Flutter)
//! ```rust,ignore
//! // Fetch only new logs since last fetch
//! let new_logs = logging::fetch_logs();
//!
//! // Or get all buffered logs (useful after hot restart)
//! let all_logs = logging::get_all_buffered_logs();
//! ```
//!
//! ### Hot-Reload Handling
//! ```rust,ignore
//! // Call this before reinitializing Dart side
//! logging::clear_log_callback();
//! logging::reset_log_read_index();
//! ```

use chrono::Local;
use log::{Level, Metadata, Record, SetLoggerError};
use once_cell::sync::Lazy;
use std::collections::VecDeque;
use std::sync::{Mutex, RwLock};

// =============================================================================
// Static Logger Instance
// =============================================================================

/// The global logger instance. This is a zero-sized struct that implements
/// the `log::Log` trait. Rust's logging facade requires a static logger.
static LOGGER: FabulaLogger = FabulaLogger;

/// Type alias for the log callback function to reduce type complexity.
type LogCallback = Box<dyn Fn(String) + Send + Sync>;

/// Optional callback function for real-time log streaming.
/// Wrapped in RwLock for thread-safe read/write access.
/// Set to None to disable callback-based logging (e.g., during hot reload).
static LOG_CALLBACK: Lazy<RwLock<Option<LogCallback>>> =
    Lazy::new(|| RwLock::new(None));

// =============================================================================
// Ring Buffer for Log Persistence
// =============================================================================

/// Maximum number of log entries to retain in the ring buffer.
/// When the buffer is full, the oldest entries are discarded (FIFO).
/// 500 entries provides a good balance between memory usage and log history.
const LOG_BUFFER_SIZE: usize = 500;

/// The ring buffer storing formatted log messages.
/// Uses VecDeque for efficient push_back/pop_front operations.
/// Protected by Mutex for thread-safe access from multiple logging sources.
static LOG_BUFFER: Lazy<Mutex<VecDeque<String>>> =
    Lazy::new(|| Mutex::new(VecDeque::with_capacity(LOG_BUFFER_SIZE)));

/// Tracks how many logs have been read by the consumer (Dart side).
/// Used by [`fetch_logs()`] to return only new, unread logs.
static LOG_READ_INDEX: Lazy<Mutex<usize>> = Lazy::new(|| Mutex::new(0));

/// Tracks total number of logs written to the buffer.
/// Compared against `LOG_READ_INDEX` to determine if new logs are available.
/// Uses wrapping arithmetic to handle overflow gracefully.
static LOG_WRITE_INDEX: Lazy<Mutex<usize>> = Lazy::new(|| Mutex::new(0));

// =============================================================================
// FabulaLogger - Custom Log Implementation
// =============================================================================

/// The Fabula Nova SDK logger implementation.
///
/// This is a zero-sized struct that implements the [`log::Log`] trait.
/// It formats log messages with timestamps, level tags, and source location,
/// then stores them in a ring buffer and optionally sends them to a callback.
///
/// # Thread Safety
///
/// The logger is fully thread-safe. Multiple threads can log simultaneously
/// without data races. The ring buffer and callback are protected by appropriate
/// synchronization primitives (Mutex and RwLock).
pub struct FabulaLogger;

impl log::Log for FabulaLogger {
    /// Checks if a log record should be processed based on the current max level.
    ///
    /// # Arguments
    /// * `metadata` - The metadata of the log record containing the log level
    ///
    /// # Returns
    /// `true` if the log level is at or below the configured maximum level
    fn enabled(&self, metadata: &Metadata) -> bool {
        metadata.level() <= log::max_level()
    }

    /// Processes a log record by formatting it and storing/dispatching it.
    ///
    /// This method performs the following steps:
    /// 1. Check if logging is enabled for this level
    /// 2. Format the message with timestamp, module, level, and source location
    /// 3. Add the formatted message to the ring buffer
    /// 4. Send to callback if one is registered
    ///
    /// # Log Level Tags
    /// The level tags are formatted to align with Java-style logging:
    /// - `Error` → `[FATAL ]` - Critical errors that may cause termination
    /// - `Warn`  → `[WARNING]` - Potential issues that don't prevent operation
    /// - `Info`  → `[INFO  ]` - General informational messages
    /// - `Debug` → `[FINE  ]` - Detailed debugging information
    /// - `Trace` → `[FINEST]` - Most verbose tracing information
    ///
    /// # Arguments
    /// * `record` - The log record containing the message and metadata
    fn log(&self, record: &Record) {
        if self.enabled(record.metadata()) {
            // Format timestamp as HH:MM:SS.mmm (24-hour format with milliseconds)
            let timestamp = Local::now().format("%H:%M:%S.%3f");

            // Map Rust log levels to Java-style level tags for consistency
            // with logging output that developers may be familiar with
            let level_tag = match record.level() {
                Level::Error => "[FATAL ]",
                Level::Warn => "[WARNING]",
                Level::Info => "[INFO  ]",
                Level::Debug => "[FINE  ]",
                Level::Trace => "[FINEST]",
            };

            // Convert module path to uppercase for visibility in logs
            // e.g., "fabula_nova_sdk::modules::ztr" becomes "FABULA_NOVA_SDK::MODULES::ZTR"
            let module = record.target().to_uppercase();

            // Extract just the filename (without extension) from the full path
            // This keeps log lines concise while still showing source location
            let file_name = record
                .file()
                .map(|f| {
                    std::path::Path::new(f)
                        .file_stem()
                        .and_then(|s| s.to_str())
                        .unwrap_or("Unknown")
                })
                .unwrap_or("Unknown");

            // Get line number, defaulting to 0 if not available
            let line = record.line().unwrap_or(0);

            // Construct the final formatted log message
            // Format: "HH:MM:SS.mmm [MODULE] [LEVEL] filename@line: message"
            let message = format!(
                "{} [{}] {} {}@{}: {}",
                timestamp,
                module,
                level_tag,
                file_name,
                line,
                record.args()
            );

            // Always add to ring buffer for polling-based retrieval
            // This ensures logs persist even if no callback is registered
            add_to_buffer(&message);

            // Attempt to send to callback if one is registered
            // Using read() lock since we're only reading the callback reference
            if let Ok(guard) = LOG_CALLBACK.read() {
                if let Some(cb) = guard.as_ref() {
                    cb(message.clone());
                }
            }
        }
    }

    /// Flushes any buffered log records.
    ///
    /// This implementation is a no-op since we write directly to the ring buffer
    /// and callback without any intermediate buffering.
    fn flush(&self) {}
}

// =============================================================================
// Logger Initialization and Configuration
// =============================================================================

/// Initializes the global logger for the Fabula Nova SDK.
///
/// This function registers [`FabulaLogger`] as the global logger and sets the
/// maximum log level to `Trace` (most verbose). Should be called once at
/// application startup, typically in the `init_app()` function.
///
/// # Returns
/// - `Ok(())` - Logger was successfully initialized
/// - `Err(SetLoggerError)` - A logger was already registered (harmless, level is still set)
///
/// # Notes
/// - It's safe to call this multiple times; subsequent calls will log a warning
///   but still ensure the max level is set correctly
/// - The log level can be adjusted later using [`set_log_level()`]
///
/// # Example
/// ```rust,ignore
/// if let Err(e) = init_logger() {
///     eprintln!("Logger already initialized: {}", e);
/// }
/// ```
pub fn init_logger() -> Result<(), SetLoggerError> {
    let res = log::set_logger(&LOGGER);
    log::set_max_level(log::LevelFilter::Trace);

    if res.is_err() {
        eprintln!(
            "FabulaLogger: log::set_logger failed (already set). Ensuring max_level is Trace."
        );
    }

    res
}

/// Registers a callback function to receive log messages in real-time.
///
/// When set, the callback will be invoked for every log message in addition
/// to storing it in the ring buffer. This enables real-time log streaming
/// to the Dart/Flutter side.
///
/// # Type Parameters
/// * `F` - A function or closure that takes a `String` and is thread-safe
///
/// # Arguments
/// * `callback` - The function to call with each formatted log message
///
/// # Thread Safety
/// The callback must be `Send + Sync` to ensure it can be safely called
/// from any thread. The callback is stored behind an `RwLock` for safe access.
///
/// # Warning
/// Before Flutter hot restart, call [`clear_log_callback()`] to prevent
/// calling a closure that references a dead Dart isolate.
///
/// # Example
/// ```rust,ignore
/// set_log_callback(|msg| {
///     // Send to Dart via FFI
///     dart_send_log(msg);
/// });
/// ```
pub fn set_log_callback<F>(callback: F)
where
    F: Fn(String) + Send + Sync + 'static,
{
    if let Ok(mut guard) = LOG_CALLBACK.write() {
        *guard = Some(Box::new(callback));
    }
}

/// Clears the log callback to prevent dangling references on hot reload.
///
/// **IMPORTANT**: Call this before reinitializing the Dart side to avoid
/// invoking closures that reference a dead Dart isolate. Failing to do so
/// can cause undefined behavior or crashes.
///
/// # When to Call
/// - Before Flutter hot restart
/// - When disposing of the logging connection
/// - When switching between Dart isolates
///
/// # Example
/// ```rust,ignore
/// // In Flutter's dispose or before hot restart
/// clear_log_callback();
/// reset_log_read_index(); // Also reset read index for fresh start
/// ```
pub fn clear_log_callback() {
    if let Ok(mut guard) = LOG_CALLBACK.write() {
        *guard = None;
    }
}

// =============================================================================
// Ring Buffer Functions (for polling-based log retrieval)
// =============================================================================

/// Adds a log message to the ring buffer.
///
/// This is an internal function called by the logger. It maintains the ring
/// buffer at a maximum of [`LOG_BUFFER_SIZE`] entries using FIFO eviction.
///
/// # Arguments
/// * `message` - The formatted log message to store
///
/// # Behavior
/// 1. If buffer is at capacity, removes the oldest message
/// 2. Appends the new message to the end
/// 3. Increments the write index (with wrapping for overflow)
///
/// # Thread Safety
/// Protected by a Mutex to ensure atomic buffer operations.
fn add_to_buffer(message: &str) {
    if let Ok(mut buffer) = LOG_BUFFER.lock() {
        // Evict oldest entry if buffer is full (FIFO)
        if buffer.len() >= LOG_BUFFER_SIZE {
            buffer.pop_front();
        }
        buffer.push_back(message.to_string());

        // Increment write index with wrapping to handle overflow
        // This allows the index to wrap around without panicking
        if let Ok(mut idx) = LOG_WRITE_INDEX.lock() {
            *idx = idx.wrapping_add(1);
        }
    }
}

/// Fetches all new logs since the last fetch.
///
/// This is the primary function for polling-based log retrieval, recommended
/// for Flutter integration. It returns only logs that haven't been fetched
/// before and updates the read index automatically.
///
/// # Returns
/// A vector of formatted log messages. Empty if no new logs are available.
///
/// # Hot Restart Safety
/// This function is safe to call after Flutter hot restart because:
/// - The ring buffer persists in Rust memory
/// - The read index can be reset with [`reset_log_read_index()`]
/// - No Dart references are held
///
/// # Algorithm
/// 1. Compare read index with write index to detect new logs
/// 2. Calculate how many new logs exist (handles wrapping)
/// 3. Extract the newest `n` logs from the buffer
/// 4. Update read index to match write index
///
/// # Example
/// ```rust,ignore
/// // Call periodically from Dart (e.g., every 100ms)
/// let new_logs = fetch_logs();
/// for log in new_logs {
///     display_in_console(log);
/// }
/// ```
pub fn fetch_logs() -> Vec<String> {
    // Get current indices - default to 0 if lock fails
    let read_idx = LOG_READ_INDEX.lock().map(|g| *g).unwrap_or(0);
    let write_idx = LOG_WRITE_INDEX.lock().map(|g| *g).unwrap_or(0);

    // Early return if no new logs (indices match)
    if read_idx == write_idx {
        return Vec::new();
    }

    let mut result = Vec::new();
    if let Ok(buffer) = LOG_BUFFER.lock() {
        // Calculate how many new logs we need to fetch
        // Using wrapping_sub handles the case where write_idx has wrapped around
        let total_logs = buffer.len();
        let new_count = write_idx.wrapping_sub(read_idx).min(total_logs);

        // Get the last `new_count` logs from the buffer
        // These are the newest logs that haven't been read yet
        let start = total_logs.saturating_sub(new_count);
        for i in start..total_logs {
            if let Some(msg) = buffer.get(i) {
                result.push(msg.clone());
            }
        }
    }

    // Update read index to current write position
    // This marks all current logs as "read"
    if let Ok(mut idx) = LOG_READ_INDEX.lock() {
        *idx = write_idx;
    }

    result
}

/// Gets all logs currently in the ring buffer.
///
/// Unlike [`fetch_logs()`], this function returns ALL buffered logs regardless
/// of whether they've been fetched before. Useful for:
/// - Initial load after Flutter hot restart
/// - Displaying complete log history
/// - Debugging the logging system itself
///
/// # Returns
/// A vector of all formatted log messages in the buffer, ordered from oldest
/// to newest.
///
/// # Note
/// This does NOT update the read index. Call [`reset_log_read_index()`]
/// before using this if you want subsequent [`fetch_logs()`] calls to
/// return fresh data.
///
/// # Example
/// ```rust,ignore
/// // After hot restart, get all historical logs
/// reset_log_read_index();
/// let all_logs = get_all_buffered_logs();
/// populate_console(all_logs);
/// ```
pub fn get_all_buffered_logs() -> Vec<String> {
    if let Ok(buffer) = LOG_BUFFER.lock() {
        buffer.iter().cloned().collect()
    } else {
        Vec::new()
    }
}

/// Resets the read index to zero, allowing all buffered logs to be re-fetched.
///
/// Call this after Flutter hot restart to ensure [`fetch_logs()`] returns
/// all historical logs on the next call.
///
/// # Use Cases
/// - After Flutter hot restart
/// - When reinitializing the logging display
/// - To replay all buffered logs
///
/// # Example
/// ```rust,ignore
/// // After hot restart
/// clear_log_callback();  // Clear old callback
/// reset_log_read_index(); // Reset read position
/// // Now fetch_logs() will return all buffered logs
/// ```
pub fn reset_log_read_index() {
    if let Ok(mut idx) = LOG_READ_INDEX.lock() {
        *idx = 0;
    }
}

// =============================================================================
// Log Level Configuration
// =============================================================================

/// Log level enumeration for FFI compatibility and runtime configuration.
///
/// This enum provides a simple integer-based representation of log levels
/// that can be easily passed across the FFI boundary (Dart ↔ Rust).
/// Each variant has an explicit discriminant for stable ABI.
///
/// # Level Hierarchy (least to most verbose)
///
/// | Level | Value | Description                                    |
/// |-------|-------|------------------------------------------------|
/// | Off   | 0     | Disables all logging                           |
/// | Error | 1     | Only critical errors (may cause termination)   |
/// | Warn  | 2     | Warnings + errors                              |
/// | Info  | 3     | General info + warnings + errors (recommended) |
/// | Debug | 4     | Debugging details + all above                  |
/// | Trace | 5     | Most verbose, includes everything              |
///
/// # FFI Usage
/// ```dart
/// // From Dart
/// setLogLevel(3); // Info level
/// ```
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum LogLevel {
    /// Disables all logging output
    Off = 0,
    /// Critical errors that may cause termination or data loss
    Error = 1,
    /// Warning conditions that don't prevent operation
    Warn = 2,
    /// General informational messages (default recommended level)
    Info = 3,
    /// Detailed debugging information for development
    Debug = 4,
    /// Most verbose level, traces execution flow
    Trace = 5,
}

impl From<i32> for LogLevel {
    /// Converts an integer to a LogLevel.
    ///
    /// # Arguments
    /// * `value` - Integer value (0-5)
    ///
    /// # Returns
    /// The corresponding LogLevel. Invalid values default to `Info`.
    ///
    /// # Example
    /// ```rust,ignore
    /// let level: LogLevel = 3.into(); // LogLevel::Info
    /// let invalid: LogLevel = 99.into(); // LogLevel::Info (default)
    /// ```
    fn from(value: i32) -> Self {
        match value {
            0 => LogLevel::Off,
            1 => LogLevel::Error,
            2 => LogLevel::Warn,
            3 => LogLevel::Info,
            4 => LogLevel::Debug,
            5 => LogLevel::Trace,
            _ => LogLevel::Info, // Default to Info for invalid values
        }
    }
}

impl From<LogLevel> for log::LevelFilter {
    /// Converts a LogLevel to the standard `log::LevelFilter`.
    ///
    /// This enables seamless integration with Rust's standard logging facade.
    fn from(level: LogLevel) -> Self {
        match level {
            LogLevel::Off => log::LevelFilter::Off,
            LogLevel::Error => log::LevelFilter::Error,
            LogLevel::Warn => log::LevelFilter::Warn,
            LogLevel::Info => log::LevelFilter::Info,
            LogLevel::Debug => log::LevelFilter::Debug,
            LogLevel::Trace => log::LevelFilter::Trace,
        }
    }
}

/// Sets the maximum log level for the logger.
///
/// Messages at levels more verbose than the set level will be filtered out.
/// For example, setting `LogLevel::Warn` will show only Warn and Error messages.
///
/// # Arguments
/// * `level` - The desired log level
///
/// # Log Level Values
/// - 0 = Off (no logging)
/// - 1 = Error
/// - 2 = Warn
/// - 3 = Info (recommended for production)
/// - 4 = Debug
/// - 5 = Trace (most verbose)
///
/// # Side Effects
/// Prints a message to stderr confirming the level change. Uses stderr
/// instead of the logger to avoid recursion if called during logging.
///
/// # Example
/// ```rust,ignore
/// // Set to Info level (recommended for production)
/// set_log_level(LogLevel::Info);
///
/// // Enable all logs for debugging
/// set_log_level(LogLevel::Trace);
///
/// // Disable all logging
/// set_log_level(LogLevel::Off);
/// ```
pub fn set_log_level(level: LogLevel) {
    let filter: log::LevelFilter = level.into();
    log::set_max_level(filter);
    // Use eprintln to avoid recursion if called during logging
    // This ensures the confirmation message is always visible
    eprintln!("FabulaLogger: Log level set to {:?}", filter);
}

/// Gets the current maximum log level.
///
/// # Returns
/// The current [`LogLevel`] setting.
///
/// # Example
/// ```rust,ignore
/// let current = get_log_level();
/// if current == LogLevel::Trace {
///     println!("Verbose logging is enabled");
/// }
/// ```
pub fn get_log_level() -> LogLevel {
    match log::max_level() {
        log::LevelFilter::Off => LogLevel::Off,
        log::LevelFilter::Error => LogLevel::Error,
        log::LevelFilter::Warn => LogLevel::Warn,
        log::LevelFilter::Info => LogLevel::Info,
        log::LevelFilter::Debug => LogLevel::Debug,
        log::LevelFilter::Trace => LogLevel::Trace,
    }
}
