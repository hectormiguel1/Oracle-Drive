//! # Event Data Structures
//!
//! This module defines the data structures for Event files (cutscene schedules).
//!
//! ## File Format
//!
//! Event files (`.white.win32.xwb`) are WPD containers containing:
//! - `!!cutreslist` (txt) - External asset references with hashes
//! - `!!cutsch` (scb) - Main schedule in SEDBSCB format
//! - `!!cutsndrsinf` (srb) - Sound resource info
//! - `ev_xxxx_xxx_##` (txt) - Optional dialogue entries
//!
//! ## SEDBSCB Format
//!
//! The main schedule uses SEDB (Square Enix Data Block) format with sections:
//! - @CRST - Resource structure table
//! - @CACT - Actor definitions
//! - @CBLK - Block definitions
//! - @CRES - Resource references

use serde::{Deserialize, Serialize};

/// Parsed event file metadata.
///
/// This is the main output structure containing all extracted metadata
/// from an event file without loading animation curves or keyframes.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EventMetadata {
    /// Event name (derived from filename)
    pub name: String,
    /// Source file path
    pub source_path: String,
    /// Total file size in bytes
    pub file_size: u64,
    /// Number of WPD records
    pub record_count: usize,
    /// WPD record list with names and sizes
    pub wpd_records: Vec<WpdRecordInfo>,
    /// Schedule header info
    pub schedule_header: Option<ScheduleHeader>,
    /// Section counts from SEDBSCB
    pub section_counts: SectionCounts,
    /// External resource references from cutreslist
    pub external_resources: Vec<ExternalResource>,
    /// Actors participating in the cutscene
    pub actors: Vec<EventActor>,
    /// Execution blocks
    pub blocks: Vec<EventBlock>,
    /// Resource references
    pub resources: Vec<EventResource>,
    /// Sound block info
    pub sound_blocks: Vec<SoundBlock>,
    /// Sound references (music, sfx, voice IDs)
    pub sound_references: Vec<SoundReference>,
    /// Dialogue entries (record names, not resolved text)
    pub dialogue_entries: Vec<DialogueEntry>,
    /// DataSet contents (if DataSet directory exists)
    pub dataset: Option<EventDataSet>,
}

impl Default for EventMetadata {
    fn default() -> Self {
        Self {
            name: String::new(),
            source_path: String::new(),
            file_size: 0,
            record_count: 0,
            wpd_records: Vec::new(),
            schedule_header: None,
            section_counts: SectionCounts::default(),
            external_resources: Vec::new(),
            actors: Vec::new(),
            blocks: Vec::new(),
            resources: Vec::new(),
            sound_blocks: Vec::new(),
            sound_references: Vec::new(),
            dialogue_entries: Vec::new(),
            dataset: None,
        }
    }
}

/// WPD record info for display.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WpdRecordInfo {
    /// Record name
    pub name: String,
    /// File extension
    pub extension: String,
    /// Offset in file
    pub offset: u32,
    /// Size in bytes
    pub size: u32,
}

/// SEDBSCB schedule header info.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ScheduleHeader {
    /// Magic string (should be "SEDBSCB")
    pub magic: String,
    /// Version number
    pub version: u32,
    /// Header size in bytes
    pub header_size: u32,
    /// Data size in bytes
    pub data_size: u32,
}

/// Counts of each section type in SEDBSCB.
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct SectionCounts {
    /// @CRST - Resource Structure Table
    pub crst: u32,
    /// @CRES - Resources
    pub cres: u32,
    /// @CATT - Attributes
    pub catt: u32,
    /// @CCPT - Control Points
    pub ccpt: u32,
    /// @CACT - Actors
    pub cact: u32,
    /// @CDPT - Data Points
    pub cdpt: u32,
    /// @CTRK - Tracks
    pub ctrk: u32,
    /// @CBKT - Block Table
    pub cbkt: u32,
    /// @CBLK - Blocks
    pub cblk: u32,
}

/// External resource reference from cutreslist.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExternalResource {
    /// Resource name (e.g., "c206ddaa080_01")
    pub name: String,
    /// External hash (e.g., "Ee1f7a3fa43b982")
    pub hash: String,
    /// Resource category (derived from name prefix)
    pub category: ResourceCategory,
}

/// Category of external resource.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum ResourceCategory {
    /// Event file (ev_xxx)
    Event,
    /// Camera animation (c### prefix)
    Camera,
    /// World/environment (w### prefix)
    World,
    /// Facial animation (f### prefix)
    Facial,
    /// Normal/generic animation (n### prefix)
    Normal,
    /// Block animation (b### prefix)
    Block,
    /// Cutscene camera (ddaa###_c##)
    CutsceneCamera,
    /// Unknown category
    Unknown,
}

impl ResourceCategory {
    /// Classify from resource name.
    pub fn from_name(name: &str) -> Self {
        if name.starts_with("ev_") {
            ResourceCategory::Event
        } else if name.starts_with("c") && name.chars().nth(1).map(|c| c.is_ascii_digit()).unwrap_or(false) {
            ResourceCategory::Camera
        } else if name.starts_with("w") && name.chars().nth(1).map(|c| c.is_ascii_digit()).unwrap_or(false) {
            ResourceCategory::World
        } else if name.starts_with("f") && name.chars().nth(1).map(|c| c.is_ascii_digit()).unwrap_or(false) {
            ResourceCategory::Facial
        } else if name.starts_with("n") && name.chars().nth(1).map(|c| c.is_ascii_digit()).unwrap_or(false) {
            ResourceCategory::Normal
        } else if name.starts_with("b") && name.chars().nth(1).map(|c| c.is_ascii_digit()).unwrap_or(false) {
            ResourceCategory::Block
        } else if name.contains("_c") && name.chars().filter(|c| c.is_ascii_digit()).count() > 2 {
            ResourceCategory::CutsceneCamera
        } else {
            ResourceCategory::Unknown
        }
    }

    /// Display name for the category.
    pub fn display_name(&self) -> &'static str {
        match self {
            ResourceCategory::Event => "Event",
            ResourceCategory::Camera => "Camera",
            ResourceCategory::World => "World",
            ResourceCategory::Facial => "Facial",
            ResourceCategory::Normal => "Normal",
            ResourceCategory::Block => "Block",
            ResourceCategory::CutsceneCamera => "Cutscene Camera",
            ResourceCategory::Unknown => "Unknown",
        }
    }
}

/// Sound reference from SRB.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SoundReference {
    /// Block name this sound belongs to
    pub block_name: String,
    /// Sound identifier
    pub sound_id: String,
    /// Sound type
    pub sound_type: SoundType,
}

/// Type of sound reference.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum SoundType {
    /// Background music (music_xxx)
    Music,
    /// Ambient/attribute sound (atb_xxx)
    Ambient,
    /// Character voice/dialogue
    Voice,
    /// Sound effect
    SoundEffect,
    /// Unknown type
    Unknown,
}

impl SoundType {
    /// Classify from sound ID.
    pub fn from_id(id: &str) -> Self {
        if id.starts_with("music_") {
            SoundType::Music
        } else if id.starts_with("atb_") {
            SoundType::Ambient
        } else if id.contains("voice") || id.contains("vo_") {
            SoundType::Voice
        } else if id.starts_with("se_") || id.starts_with("sfx_") {
            SoundType::SoundEffect
        } else {
            SoundType::Unknown
        }
    }

    /// Display name.
    pub fn display_name(&self) -> &'static str {
        match self {
            SoundType::Music => "Music",
            SoundType::Ambient => "Ambient",
            SoundType::Voice => "Voice",
            SoundType::SoundEffect => "SFX",
            SoundType::Unknown => "Unknown",
        }
    }
}

/// Actor type classification.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum ActorType {
    /// Camera actor (CameraActor_###)
    Camera,
    /// Sound emitter (SoundActor_###)
    Sound,
    /// Visual effect (EffectActor_###)
    Effect,
    /// Background music (BgmActor_###)
    Bgm,
    /// Character proxy (ProxyActor_####)
    Proxy,
    /// System/utility actor (System_####)
    System,
    /// Named character (e.g., "lightning", "p_lt")
    Character(String),
    /// Unknown actor type
    Unknown(String),
}

impl ActorType {
    /// Get a display-friendly name for the actor type.
    pub fn display_name(&self) -> String {
        match self {
            ActorType::Camera => "Camera".to_string(),
            ActorType::Sound => "Sound".to_string(),
            ActorType::Effect => "Effect".to_string(),
            ActorType::Bgm => "BGM".to_string(),
            ActorType::Proxy => "Proxy".to_string(),
            ActorType::System => "System".to_string(),
            ActorType::Character(name) => format!("Character ({})", name),
            ActorType::Unknown(name) => format!("Unknown ({})", name),
        }
    }
}

/// Actor participating in the cutscene.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EventActor {
    /// Actor name (e.g., "CameraActor_001", "lightning")
    pub name: String,
    /// Actor type classification
    pub actor_type: ActorType,
    /// Actor index in the cutscene
    pub index: u16,
    /// Raw flags from @CACT section
    pub flags: u32,
}

/// Execution block in the cutscene.
///
/// Each block is like a scene in a video editor, containing multiple
/// timeline tracks that control different aspects (camera, motion, sound, etc.)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EventBlock {
    /// Block name (e.g., "c01", "Block000")
    pub name: String,
    /// Block ID
    pub id: u16,
    /// Duration in frames (typically 30fps)
    pub duration_frames: u32,
    /// Duration in seconds (calculated from frames @ 30fps)
    pub duration_seconds: f32,
    /// Number of track entries in this block
    pub track_count: u32,
    /// Timeline track entries (commands/actions within this block)
    pub tracks: Vec<BlockTrack>,
}

/// Track type within a block.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum TrackType {
    /// Motion set reference (type 0x0a02) - contains mset_xxx strings
    MotionSet,
    /// Character set reference - contains chset_xxx strings
    CharacterSet,
    /// Camera control (types 0x0c0c, 0x0e0c, 0x0f0c, 0x100c, etc.)
    Camera,
    /// Sound/audio event (type 0x080a)
    Sound,
    /// Music bus reference (type 0x6000) - contains music_bus_xxx strings
    MusicBus,
    /// Dialogue reference (type 0x140a) - contains $event_xxx strings
    Dialogue,
    /// Effect trigger
    Effect,
    /// Event definition reference
    EventDef,
    /// Actor control/activation
    ActorControl,
    /// Unknown track type with raw type code
    Unknown(u16),
}

impl TrackType {
    /// Classify a track type from its raw type code (little-endian).
    ///
    /// Type codes are read as little-endian u16 from track data.
    pub fn from_code(code: u16) -> Self {
        match code {
            // Motion set reference (contains mset_xxx strings)
            0x020a => TrackType::MotionSet,
            // Camera control types
            0x000c | 0x0c0c | 0x0c0e | 0x0c0f | 0x0c10 | 0x0c11 => TrackType::Camera,
            // Sound/audio event
            0x0a08 => TrackType::Sound,
            // Music bus reference (contains music_bus_xxx strings)
            0x0060 | 0x0260 => TrackType::MusicBus,
            // Dialogue reference (contains $eXXXXXX_XXXmX strings)
            0x0a14 => TrackType::Dialogue,
            // Actor control/activation
            0x0801 | 0x0802 | 0x0803 => TrackType::ActorControl,
            // Event definition reference
            0x0b01 => TrackType::EventDef,
            _ => TrackType::Unknown(code),
        }
    }

    /// Get a display-friendly name.
    pub fn display_name(&self) -> &'static str {
        match self {
            TrackType::MotionSet => "Motion Set",
            TrackType::CharacterSet => "Character Set",
            TrackType::Camera => "Camera",
            TrackType::Sound => "Sound",
            TrackType::MusicBus => "Music",
            TrackType::Dialogue => "Dialogue",
            TrackType::Effect => "Effect",
            TrackType::EventDef => "Event Def",
            TrackType::ActorControl => "Actor",
            TrackType::Unknown(_) => "Unknown",
        }
    }
}

/// A single track entry within a block.
///
/// Represents one action/command in the block's timeline.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BlockTrack {
    /// Entry size in bytes
    pub size: u16,
    /// Track type
    pub track_type: TrackType,
    /// Raw type code
    pub type_code: u16,
    /// Entry flags
    pub flags: u32,
    /// Entry index within the block
    pub index: u32,
    /// Reference string (if any) - e.g., motion set name, dialogue key
    pub reference: Option<String>,
    /// Start frame (if detected)
    pub start_frame: Option<u32>,
    /// Duration in frames (if detected)
    pub duration_frames: Option<u32>,
    /// Float values (for camera tracks with position/rotation)
    pub float_values: Vec<f32>,
}

/// Resource reference from @CRES section.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EventResource {
    /// Resource name
    pub name: String,
    /// Resource type (e.g., "schedul", "RIDTBL", "Effect", "String")
    pub resource_type: String,
    /// External hash if present (E-prefixed)
    pub external_hash: Option<String>,
}

/// Sound block info from SRB section.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SoundBlock {
    /// Block name (e.g., "Block000")
    pub name: String,
    /// Duration in samples
    pub duration_samples: u32,
    /// Duration in seconds (assuming 44100Hz sample rate)
    pub duration_seconds: f32,
}

/// Dialogue entry reference.
///
/// Contains the record name which can be used to look up
/// the actual text in ZTR files.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DialogueEntry {
    /// Record name (e.g., "ev_ddaa_080_01")
    pub record_name: String,
    /// Raw content from the record (typically timing labels like "a00")
    pub raw_content: String,
    /// ZTR key for lookup (typically "$" + record_name)
    pub ztr_key: String,
}

/// Result of extracting an event file.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExtractedEvent {
    /// Output directory path
    pub output_dir: String,
    /// Parsed metadata
    pub metadata: EventMetadata,
    /// List of extracted file paths
    pub extracted_files: Vec<String>,
}

/// Summary of event file for quick display.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EventSummary {
    /// Event name
    pub name: String,
    /// Number of actors
    pub actor_count: usize,
    /// Number of blocks
    pub block_count: usize,
    /// Number of resources
    pub resource_count: usize,
    /// Number of dialogue entries
    pub dialogue_count: usize,
    /// Number of sound blocks
    pub sound_block_count: usize,
    /// Total duration in seconds (sum of blocks)
    pub total_duration_seconds: f32,
    /// Whether DataSet is available
    pub has_dataset: bool,
    /// Number of motion control blocks in DataSet
    pub motion_block_count: usize,
    /// Number of camera control blocks in DataSet
    pub camera_block_count: usize,
}

impl From<&EventMetadata> for EventSummary {
    fn from(meta: &EventMetadata) -> Self {
        let total_duration = meta.blocks.iter()
            .map(|b| b.duration_seconds)
            .sum();

        Self {
            name: meta.name.clone(),
            actor_count: meta.actors.len(),
            block_count: meta.blocks.len(),
            resource_count: meta.resources.len(),
            dialogue_count: meta.dialogue_entries.len(),
            sound_block_count: meta.sound_blocks.len(),
            total_duration_seconds: total_duration,
            has_dataset: meta.dataset.is_some(),
            motion_block_count: meta.dataset.as_ref().map(|d| d.motion_blocks.len()).unwrap_or(0),
            camera_block_count: meta.dataset.as_ref().map(|d| d.camera_blocks.len()).unwrap_or(0),
        }
    }
}

// ============================================================
// DataSet Structures
// ============================================================

/// DataSet contents (animation and camera data from DataSet/*.bin files).
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct EventDataSet {
    /// Motion control blocks (from mcb records)
    pub motion_blocks: Vec<MotionControlBlock>,
    /// Camera control blocks (from ccb records)
    pub camera_blocks: Vec<CameraControlBlock>,
    /// Source files that were loaded
    pub source_files: Vec<String>,
}

/// Motion Control Block (SEDBMCB format).
///
/// Contains animation/motion data for characters.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MotionControlBlock {
    /// Record name (from WPD, typically a hash like "E4395e03ada853f")
    pub name: String,
    /// Source file this was loaded from
    pub source_file: String,
    /// Header size
    pub header_size: u32,
    /// Data size
    pub data_size: u32,
    /// Version
    pub version: u16,
    /// Flags
    pub flags: u16,
}

/// Camera Control Block (SEDBCCB format).
///
/// Contains camera animation data.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CameraControlBlock {
    /// Record name (from WPD, typically a hash like "E2a11b449e4656c")
    pub name: String,
    /// Source file this was loaded from
    pub source_file: String,
    /// Header size
    pub header_size: u32,
    /// Data size
    pub data_size: u32,
    /// Flags
    pub flags: u32,
}
