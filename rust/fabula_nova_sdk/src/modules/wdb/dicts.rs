//! # WDB Dictionary Lookups
//!
//! This module provides static dictionaries for WDB file processing.
//! These map WDB file names to their internal schema identifiers and
//! define expected field structures.
//!
//! ## Record ID Mapping
//!
//! WDB files are named by content (e.g., `item.wdb`, `crystal_fang.wdb`)
//! but use different internal record type names. [`RECORD_IDS`] maps
//! file base names to their schema identifiers.
//!
//! ## Field Name Lookup
//!
//! When WDB files lack embedded `!structitem` sections (common in XIII),
//! [`FIELD_NAMES`] provides the expected field list based on record type.
//!
//! ## Platform Variants
//!
//! Some WDB files have platform-specific variants (win32, ps3, x360).
//! The mappings handle these with suffix-aware keys.

use std::collections::HashMap;
use once_cell::sync::Lazy;

/// Maps WDB file base names to internal record type identifiers.
///
/// # Example
///
/// ```rust,ignore
/// let record_type = RECORD_IDS.get("item").unwrap(); // "Item"
/// let fields = FIELD_NAMES.get(record_type).unwrap();
/// ```
pub static RECORD_IDS: Lazy<HashMap<&'static str, &'static str>> = Lazy::new(|| {
    let mut m = HashMap::new();
    m.insert("auto_clip", "AutoClip");
    m.insert("white", "Resident");
    m.insert("sound_fileid_dic", "SoundFileIdDic");
    m.insert("sound_fileid_dic_us", "SoundFileIdDic");
    m.insert("sound_filename_dic", "SoundFileNameDic");
    m.insert("sound_filename_dic_us", "SoundFileNameDic");
    m.insert("treasurebox", "TreasureBox");
    m.insert("zonelist", "ZoneList");
    m.insert("monster_book", "MonsterBook");
    m.insert("savepoint", "savepoint");
    m.insert("script", "Script");
    m.insert("bt_chainbonus", "bt_chainbonus");
    m.insert("bt_chara_prop", "BattleCharaProp");
    m.insert("bt_constants", "BattleConstants");
    m.insert("item", "Item");
    m.insert("item_consume", "item_consume");
    m.insert("special_ability", "SpecialAbility");
    m.insert("item_weapon", "ItemWeapon");
    m.insert("party", "Party");
    m.insert("succession", "Succession");
    m.insert("bt_summon", "bt_summon");
    m.insert("movie", "movie");
    m.insert("actioneffect", "ActionEffect");
    m.insert("attreffect", "AttributeEffectResource");
    m.insert("attreffectstate", "AttributeEffectStateResource");
    m.insert("bt_ability", "BattleAbility");
    m.insert("mapset", "MapSet");
    m.insert("emotion_voice", "EmotionVoice");
    m.insert("eventflag", "EventFlag");
    m.insert("shop", "Shop");
    m.insert("bt_auto_ability", "BattleAutoAbility");
    m.insert("charaset", "CharaSet");
    m.insert("mission", "mission");
    m.insert("fieldcamera", "FieldCamera");

    // win32
    m.insert("movie_items.win32", "movie_items");
    m.insert("movie_items_us.win32", "movie_items");

    // ps3
    m.insert("movie_items.ps3", "movie_items_ps3");
    m.insert("movie_items_us.ps3", "movie_items_ps3");

    // x360
    m.insert("movie_items.x360", "movie_items");
    m.insert("movie_items_us.x360", "movie_items");

    // crystal
    m.insert("crystal_fang", "crystal");
    m.insert("crystal_hope", "crystal");
    m.insert("crystal_lightning", "crystal");
    m.insert("crystal_sazh", "crystal");
    m.insert("crystal_snow", "crystal");
    m.insert("crystal_vanille", "crystal");

    m
});

/// Maps record type identifiers to their field definitions.
///
/// Field names encode type and bit width information:
/// - `s*` - String (offset into !!string section)
/// - `u*` - Unsigned integer (number indicates bit width)
/// - `i*` - Signed integer (number indicates bit width)
/// - `f*` - Float (32-bit IEEE 754)
///
/// # Example Field Names
///
/// - `u4Role` - 4-bit unsigned field named "Role"
/// - `i16Value` - 16-bit signed field named "Value"
/// - `sItemName` - String field named "ItemName"
/// - `fDamage` - Float field named "Damage"
pub static FIELD_NAMES: Lazy<HashMap<&'static str, Vec<&'static str>>> = Lazy::new(|| {
    let mut m = HashMap::new();
    m.insert("AutoClip", vec!["sTitle", "sTarget", "sTarget2", "sText", "sPicture", "u4Category", "u7Sort", "u4Chapter"]);
    m.insert("Resident", vec!["fVal", "iVal1", "sResourceName", "fPosX", "fPosY", "fPosZ"]);
    m.insert("SoundFileIdDic", vec!["i31FileId", "u1IsStream"]);
    m.insert("SoundFileNameDic", vec!["sResourceName"]);
    m.insert("TreasureBox", vec!["sItemResourceId", "iItemCount", "sNextTreasureBoxResourceId"]);
    m.insert("movie_items", vec!["sZoneNumber", "uCinemaSize", "uReserved", "uCinemaStart"]);
    m.insert("movie_items_ps3", vec!["sZoneNumber", "uCinemaSize", "u64CinemaStart"]);
    m.insert("ZoneList", vec![
        "fMovieTotalTimeSec", "iImageSize", "u8RefZoneNum0", "u8RefZoneNum1", "u8RefZoneNum2",
        "u8RefZoneNum3", "u8RefZoneNum4", "u8RefZoneNum5", "u8RefZoneNum6", "u8RefZoneNum7",
        "u8RefZoneNum8", "u8RefZoneNum9", "u8RefZoneNum10", "u1OnDisk0", "u1OnDisk1", "u1OnDisk2",
        "u1OnDisk3", "u1On1stLayerPS3", "u1On2ndtLayerPS3"
    ]);
    m.insert("MonsterBook", vec!["u6MbookId", "u9SortId", "u9PictureId", "u1UnkBool"]);
    m.insert("Zone", vec!["iBaseNum", "sName0", "sName1"]);
    m.insert("savepoint", vec!["sLoadScriptId", "i17PartyPositionMarkerGroupIndex", "u15SaveIconBackgroundImageIndex", "i16SaveIconOverrideImageIndex"]);
    m.insert("Script", vec!["sClassName", "sMethodName", "iAdditionalArgCount", "iAdditionalArg0", "iAdditionalArg1", "iAdditionalArg2", "iAdditionalArg3", "iAdditionalStringArgCount", "sAdditionalStringArg0", "sAdditionalStringArg1", "sAdditionalStringArg2"]);
    m.insert("bt_chainbonus", vec!["u6WhoFrom", "u6When0", "u6When1", "u6When2", "u6WhatState", "u6WhoTo", "u6DoWhat", "u6Where", "u6How", "u16Bonus"]);
    m.insert("BattleCharaProp", vec!["sInfoStrId", "sOpenCondArgS0", "u1NoLibra", "u8OpenCond", "u8AiOrderEn", "u8AiOrderJm", "u4FlavorAtk", "u4FlavorBla", "u4FlavorDef"]);
    m.insert("BattleConstants", vec!["iiVal", "ffVal", "ssVal"]);
    m.insert("Item", vec![
        "sItemNameStringId", "sHelpStringId", "sScriptId", "uPurchasePrice", "uSellPrice",
        "u8MenuIcon", "u8ItemCategory", "i16ScriptArg0", "i16ScriptArg1", "u1IsUseBattleMenu",
        "u1IsUseMenu", "u1IsDisposable", "u1IsSellable", "u5Rank", "u6Genre", "u1IsIgnoreGenre",
        "u16SortAllByKCategory", "u16SortCategoryByCategory", "u16Experience", "i8Mulitplier",
        "u1IsUseItemChange"
    ]);
    m.insert("item_consume", vec!["sAbilityId", "sLearnAbilityId", "u1IsUseRemodel", "u1IsUseGrow", "u16ConsumeAP"]);
    m.insert("SpecialAbility", vec!["sAbility", "u6Genre", "u3Count"]);
    m.insert("ItemWeapon", vec![
        "sWeaponCharaSpecId", "sWeaponCharaSpecId2", "sAbility", "sAbility2", "sAbility3",
        "sUpgradeAbility", "sAbilityHelpStringId", "uBuyPriceIncrement", "uSellPriceIncrement",
        "sDisasItem1", "sDisasItem2", "sDisasItem3", "sDisasItem4", "sDisasItem5", "u8UnkVal1",
        "u8UnkVal2", "u2UnkVal3", "u7MaxLvl", "u4UnkVal4", "u1LightCanWear", "u1SazCanWear", "u1SnowCanWear",
        "i10ExpRate1", "i10ExpRate2", "i10ExpRate3", "u1UnkBool4", "u1HopeCanWear", "u8StatusModKind0",
        "u8StatusModKind1", "u4StatusModType", "u1FangCanWear", "u1VanilleCanWear", "u16UnkVal5",
        "i16StatusModVal", "u16UnkVal6", "i16AttackModVal", "u16UnkVal7", "i16MagicModVal",
        "i16AtbModVal", "u16UnkVal8", "u16UnkVal9", "u16UnkVal10", "u14DisasRate1", "u7UnkVal11",
        "u7UnkVal12", "u14DisasRate2", "u14DisasRate3", "u7UnkVal13", "u14DisasRate4",
        "u7UnkVal14", "u14DisasRate5"
    ]);
    m.insert("Party", vec![
        "sCharaSpecId", "sSubCharaSpecId0", "sSubCharaSpecId1", "sSubCharaSpecId2",
        "sSubCharaSpecId3", "sSubCharaSpecId4", "sSubCharaSpecId5", "sSubCharaSpecId6",
        "sSubCharaSpecId7", "sSubCharaSpecId8", "sRideObjectCharaSpecId0",
        "sRideObjectCharaSpecId1", "sFieldFreeCameraSettingResourceId", "sIconResourceId",
        "sScriptIdOnPartyCharaAIStarted", "sScriptIdOnIdle", "sBattleCharaSpecId", "sSummonId",
        "fStopDistance", "fWalkDistance", "fPlayerRestraint", "u1IsEnableUserControl",
        "u5OrderNumForCrest", "u8OrderNumForTool", "u7Expresspower", "u7Willpower",
        "u7Brightness", "u7Cognition"
    ]);
    m.insert("Succession", vec![
        "u1RideOffChocobo", "i2NaviMapMode", "i2PartyCharaAIMode", "i2UserControlMode",
        "i9ZoneStateChangeTriggerOnEnter", "i9ZoneStateWait", "u1EventSkipAble",
        "u1FieldCommonObjectHide", "u1EnablePause", "u1SuspendFieldObject",
        "u1DisableTalk", "i9ZoneStateChangeTriggerOnExit", "i9ZoneStateExit",
        "u13CameraInterporationTimeOnEnter", "u1FieldActiveFlag",
        "u13CameraInterporationTimeOnExit", "u1HighModelEventFlag",
        "u1ApplyFieldCameraByPlayerMatrix"
    ]);
    m.insert("bt_summon", vec![
        "iSummonKind", "sCharaSet", "sBtChSpec0", "sBtChSpec1", "sSummonInEv", "sDriveInEv",
        "sFinishArtsEv", "iMaxSp0", "iMaxSp1", "iMaxSp2", "iMaxSp3", "iMaxSp4", "iMaxSp5",
        "iMaxSp6", "iMaxSp7", "iMaxSp8", "iMaxSp9", "iMaxSp10", "iMaxSp11", "iMaxSp12",
        "iMaxSp13", "iMaxSp14", "iMaxSp15", "iMaxSp16", "u16Str0", "u16Str1", "u16Str2",
        "u16Str3", "u16Str4", "u16Str5", "u16Str6", "u16Str7", "u16Str8", "u16Str9", "u16Str10",
        "u16Str11", "u16Str12", "u16Str13", "u16Str14", "u16Str15", "u16Str16", "u16Mag0",
        "u16Mag1", "u16Mag2", "u16Mag3", "u16Mag4", "u16Mag5", "u16Mag6", "u16Mag7", "u16Mag8",
        "u16Mag9", "u16Mag10", "u16Mag11", "u16Mag12", "u16Mag13", "u16Mag14", "u16Mag15",
        "u16Mag16"
    ]);
    m.insert("crystal", vec!["uCPCost", "sAbilityID", "u4Role", "u4CrystalStage", "u8NodeType", "u16NodeVal"]);
    m.insert("movie", vec!["sZone0", "sZone1"]);
    m.insert("ActionEffect", vec!["sEffectId", "iEffectArg1", "sSoundId"]);
    m.insert("AttributeEffectResource", vec![
        "sFootSoundResourceNameDefaultAttr", "sFootSoundResourceNameDrySoilAttr",
        "sFootSoundResourceNameDampSoilAttr", "sFootSoundResourceNameGrassAttr",
        "sFootSoundResourceNameBushAttr", "sFootSoundResourceNameSandAttr",
        "sFootSoundResourceNameWoodAttr", "sFootSoundResourceNameBoardAttr",
        "sFootSoundResourceNameFlooringAttr", "sFootSoundResourceNameStoneAttr",
        "sFootSoundResourceNameGravelAttr", "sFootSoundResourceNameIronAttr",
        "sFootSoundResourceNameThinIronAttr", "sFootSoundResourceNameClothAttr",
        "sFootSoundResourceNameEartenwareAttr", "sFootSoundResourceNameCrystalAttr",
        "sFootSoundResourceNameGlassAttr", "sFootSoundResourceNameIceAttr",
        "sFootSoundResourceNameWaterAttr", "sFootSoundResourceNameAsphaltAttr",
        "sFootSoundResourceNameNoneAttr", "sFootSoundResourceNameWireNetAttr",
        "sFootSoundResourceNameBranchOfMachineAttr", "sFootSoundResourceNameBranchOfNatureAttr",
        "sFootSoundResourceNameCorkAttr", "sFootSoundResourceNameMarbleAttr",
        "sFootSoundResourceNameHologramAttr", "sFootVfxResourceNameDefaultAttr",
        "sFootVfxResourceNameDrySoilAttr", "sFootVfxResourceNameDampSoilAttr",
        "sFootVfxResourceNameGrassAttr", "sFootVfxResourceNameBushAttr",
        "sFootVfxResourceNameSandAttr", "sFootVfxResourceNameWoodAttr",
        "sFootVfxResourceNameBoardAttr", "sFootVfxResourceNameFlooringAttr",
        "sFootVfxResourceNameStoneAttr", "sFootVfxResourceNameGravelAttr",
        "sFootVfxResourceNameIronAttr", "sFootVfxResourceNameThinIronAttr",
        "sFootVfxResourceNameClothAttr", "sFootVfxResourceNameEartenwareAttr",
        "sFootVfxResourceNameCrystalAttr", "sFootVfxResourceNameGlassAttr",
        "sFootVfxResourceNameIceAttr", "sFootVfxResourceNameWaterAttr",
        "sFootVfxResourceNameAsphaltAttr", "sFootVfxResourceNameNoneAttr",
        "sFootVfxResourceNameWireNetAttr", "sFootVfxResourceNameBranchOfMachineAttr",
        "sFootVfxResourceNameBranchOfNatureAttr", "sFootVfxResourceNameCorkAttr",
        "sFootVfxResourceNameMarbleAttr", "sFootVfxResourceNameHologramAttr"
    ]);
    m.insert("AttributeEffectStateResource", vec!["sWalk", "sRun", "sJump", "sRetreat", "sLanding", "sSliding", "sSquat", "sStand", "sFly"]);
    m.insert("BattleAbility", vec![
        "sStringResId", "sInfoStResId", "sScriptId", "sAblArgStr0", "sAblArgStr1",
        "sAutoAblStEff0", "fDistanceMin", "fDistanceMax", "fMaxJumpHeight", "fYDistanceMin",
        "fYDistanceMax", "fAirJpHeight", "fAirJpTime", "sReplaceAirAttack", "sReplaceAirAir",
        "sReplaceRangeAtk", "sReplaceFinAtk", "sReplaceEnAttr", "iExceptionID", "sActionId0",
        "sActionId1", "sActionId2", "sActionId3", "sRtDamSrc", "sRefDamSrc", "sSubRefDamSrc",
        "sSlamDamSrc", "sCamArtsSeqId0", "sCamArtsSeqId1", "sCamArtsSeqId2", "sCamArtsSeqId3",
        "sRedirectAbility0", "sRedirectTo0", "sRedirectAbility1", "sRedirectTo1",
        "sRedirectAbility2", "sRedirectTo2", "sRedirectAbility3", "sRedirectTo3", "sSysEffId0",
        "iSysEffArg0", "sSysSndId0", "sRtEffId0", "iRtEffArg0", "sRtSndId0", "sRtEffId1",
        "iRtEffArg1", "sRtSndId1", "sRtEffId2", "iRtEffArg2", "sRtSndId2", "sRtEffId3",
        "iRtEffArg3", "sRtSndId3", "sRtEffId4", "iRtEffArg4", "sRtSndId4", "u1ComAbility",
        "u1RsvFlag0", "u1RsvFlag1", "u1RsvFlag2", "u1RsvFlag3", "u1RsvFlag4", "u1RsvFlag5",
        "u1RsvFlag6", "u4ArtsNameHideKd", "u16ArtsNameFrame", "u4UseRole", "u8AblSndKind",
        "u4MenuCategory", "i16MenuSortNo", "u1NoDespel", "i16ScriptArg0", "i16ScriptArg1",
        "u8AbilityKind", "u4TargetListKind", "i16AblArgInt0", "u4UpAblKind", "i16AblArgInt1",
        "i16AtbCount", "i16AtRnd", "i16KeepVal", "i16IntRsv0", "i16IntRsv1", "u1TgFoge",
        "u1NoBackStep", "u1AIWanderFlag", "u16TgElemId", "u10OpProp0", "u1AutoAblStEfEd0",
        "u1CheckAutoRpl", "u1SeqParts", "i16AutoAblStEfTi0", "u4YRgCheckType", "u4AtDistKind",
        "u4JumpAttackType", "u1SeqTermination", "u5ActSelType", "u4LoopFinCond", "u16LoopFinArg",
        "u4RedirectMargeNof0", "i16RefDamSrcRpt", "i16SubRefDamSrcRp", "i8AreaRad",
        "u8CamArtsSelType", "u4RedirectMargeNof1", "u4RedirectMargeNof2", "u4RedirectMargeNof3",
        "u16SysEffPos0", "u16RtEffPos0", "u16RtEffPos1", "u16RtEffPos2", "u16RtEffPos3",
        "u16RtEffPos4"
    ]);
    m.insert("MapSet", vec![
        "iMemorySizeLimit", "iVideoMemoryLimit", "sScriptIdOnLoaded", "sMapNameResourceId",
        "sBattleFreeSpaceResourceId", "i20LoadingTime", "i11LocationNum", "i16FieldSceneDataNum",
        "i16BattleSceneDataNum", "i12PartyPositionMarkerGroup", "i10FieldMapNum0", "i10FieldMapNum1",
        "i10FieldMapNum2", "i10FieldMapNum3", "i10FieldMapNum4", "i10FieldMapNum5", "i10FieldMapNum6",
        "i10FieldMapNum7", "i10FieldMapNum8", "i10FieldMapNum9", "i10FieldMapNum10",
        "i10FieldMapNum11", "i10FieldMapNum12", "i10FieldMapNum13", "i10FieldMapNum14",
        "i10FieldMapNum15", "i10FieldMapNum16", "i10FieldMapNum17", "i10FieldMapNum18",
        "i10FieldMapNum19", "i10VfxMapNum0", "i10VfxMapNum1", "i10VfxMapNum2", "i10VfxMapNum3",
        "i10BattleMapNum0", "i10BattleMapNum1", "i10BattleMapNum2", "i10BattleMapNum3",
        "i10BattleMapNum4", "i10BattleMapNum5"
    ]);
    m.insert("EmotionVoice", vec![
        "u4RandomMax0", "u4RandomMax1", "u4RandomMax2", "u4RandomMax3", "u4RandomMax4",
        "u4RandomMax5", "u4RandomMax6", "u4RandomMax7", "u4RandomMax8", "u4RandomMax9",
        "u4AIRandomMax0", "u4AIRandomMax1", "u4AIRandomMax2", "u4AIRandomMax3", "u4AIRandomMax4",
        "u4AIRandomMax5", "u4AIRandomMax6", "u4AIRandomMax7", "u4AIRandomMax8", "u4AIRandomMax9"
    ]);
    m.insert("EventFlag", vec!["iFlagIndex"]);
    m.insert("Shop", vec![
        "sFlagItemId", "sUnlockEventID", "sShopNameLabel", "sSignId", "sExplanationLabel",
        "sUnkStringVal1", "sItemLabel1", "sItemLabel2", "sItemLabel3", "sItemLabel4",
        "sItemLabel5", "sItemLabel6", "sItemLabel7", "sItemLabel8", "sItemLabel9", "sItemLabel10",
        "sItemLabel11", "sItemLabel12", "sItemLabel13", "sItemLabel14", "sItemLabel15",
        "sItemLabel16", "sItemLabel17", "sItemLabel18", "sItemLabel19", "sItemLabel20",
        "sItemLabel21", "sItemLabel22", "sItemLabel23", "sItemLabel24", "sItemLabel25",
        "sItemLabel26", "sItemLabel27", "sItemLabel28", "sItemLabel29", "sItemLabel30",
        "sItemLabel31", "sItemLabel32", "u4Version", "u13ZoneNum"
    ]);
    m.insert("BattleAutoAbility", vec![
        "sStringResId", "sInfoStResId", "sScriptId", "sAutoAblArgStr0", "sAutoAblArgStr1",
        "u1RsvFlag0", "u1RsvFlag1", "u1RsvFlag2", "u1RsvFlag3", "u4UseRole", "u4MenuCategory",
        "i16MenuSortNo", "i16ScriptArg0", "i16ScriptArg1", "u8AutoAblKind", "i16AutoAblArgInt0",
        "i16AutoAblArgInt1", "i16WepLvArg0", "i16WepLvArg1"
    ]);
    m.insert("CharaSet", vec![
        "iMemorySizeLimit", "iVideoMemorySizeLimit", "sCharaSpecId0", "sCharaSpecId1",
        "sCharaSpecId2", "sCharaSpecId3", "sCharaSpecId4", "sCharaSpecId5", "sCharaSpecId6",
        "sCharaSpecId7", "sCharaSpecId8", "sCharaSpecId9", "sCharaSpecId10", "sCharaSpecId11",
        "sCharaSpecId12", "sCharaSpecId13", "sCharaSpecId14", "sCharaSpecId15", "sCharaSpecId16",
        "sCharaSpecId17", "sCharaSpecId18", "sCharaSpecId19", "sCharaSpecId20", "sCharaSpecId21",
        "sCharaSpecId22", "sCharaSpecId23", "sCharaSpecId24", "sCharaSpecId25", "sCharaSpecId26",
        "sCharaSpecId27", "sCharaSpecId28", "sCharaSpecId29", "sCharaSpecId30", "sCharaSpecId31",
        "sCharaSpecId32", "sCharaSpecId33", "sCharaSpecId34", "sCharaSpecId35", "sCharaSpecId36",
        "sCharaSpecId37", "sCharaSpecId38", "sCharaSpecId39", "sCharaSpecId40", "sCharaSpecId41",
        "sCharaSpecId42", "sCharaSpecId43", "sCharaSpecId44", "sCharaSpecId45", "sCharaSpecId46",
        "sCharaSpecId47", "sCharaSpecId48", "sCharaSpecId49", "sCharaSpecId50", "sCharaSpecId51",
        "sCharaSpecId52", "sCharaSpecId53", "sCharaSpecId54", "sCharaSpecId55", "sCharaSpecId56",
        "sCharaSpecId57", "sCharaSpecId58", "sCharaSpecId59", "sCharaSpecId60", "sCharaSpecId61",
        "sCharaSpecId62", "sCharaSpecId63", "u1PartyLoadRequestIndex0", "u1PartyLoadRequestIndex1",
        "u1PartyLoadRequestIndex2", "u1PartyLoadRequestIndex3", "u1PartyLoadRequestIndex4",
        "u1PartyLoadRequestIndex5"
    ]);
    m.insert("mission", vec![
        "sMissionTitleStringId", "sMissionExplanationStringId", "sMissionTargetStringId",
        "sMissionPosStringId", "sMissionMarkPosStringId", "sPosMarkerName", "sTreasureBoxId0",
        "sTreasureBoxId1", "sTreasureBoxId2", "sCharasetId0", "sCharasetId1", "sCharasetId2",
        "sCharasetId3", "sCharaspecId0", "sCharaspecId1", "sCharaspecId2", "sCharaspecId3",
        "sCharaspecId4", "sAreaActivationName", "iBattleSceneNum", "u8ZoneNum", "u6IndexInMapMenu",
        "u4Class", "u6MissionPictureId", "u1UnkBool1", "u1UnkBool2", "u1UnkBool3"
    ]);
    m.insert("FieldCamera", vec![
        "fFreeCameraRotationInterporationSpeedAdjustMode", "fFreeCameraRunStopMoveSpeed",
        "fFreeCameraAimRotationSpeedAtMoving", "fFreeCameraCompositionAimRate",
        "fFreeCameraAimHeight", "fFreeCameraAimHeightDuringWatchingFoot",
        "fCollisionSolveInterporationRateX", "fCollisionSolveInterporationRateY",
        "fCollisionSolveInterporationRateZ", "fInterporationRateAtForward",
        "fInterporationRateAtBack", "fInterporationRateAtForwardRunning",
        "fInterporationRateAtBackRunning", "fFreeCameraYAxisRotateAttenuationRateRunning",
        "fFreeCameraXAxisRotateAttenuationRateRunning", "fFreeCameraYAxisRotateAttenuationRate",
        "fFreeCameraXAxisRotateAttenuationRate", "fFreeCameraYaxisRotationSpeedRate",
        "fFreeCameraYaxisRotationSpeedRateAtIdle", "fFreeCameraXaxisRotationSpeedRate",
        "fFreeCameraXaxisRotationSpeedRateAtIdle", "fFreeCameraFollowingSpeedRate",
        "fCharacterChangingAlphaTime", "fRailCameraFollowingDistance",
        "fRailCameraFollowingRate", "fRailCameraYOffset", "fCameraNearZDefault",
        "fCameraFarZDefault", "fAspectRateDefault", "f9FreeCameraEyeHeight",
        "f1eyeAimDistanceAtMoving", "f1eyeAimDistanceDuringWatchingFoot",
        "f1eyeAimDistanceAtStop", "f14FreeCameraeFov", "f14CompositAimChangeAngleThrreshold",
        "f16DelayTimeBetweenPlayerAndCamera", "f18CharacterChangingAlphaDistanceMax",
        "f14FreeCameraXaxisRotationLimitAngle", "f18CharacterChangingAlphaDistanceMax_PC",
        "f14FreeRailSwitchAngle", "f18CharacterChangingAlphaDistanceMin", "f14CameraRadius",
        "f18CharacterChangingAlphaDistanceMin_PC", "f14FreeCameraPullupLimitAngle",
        "f19CameraInterporationTimeDefault", "f18CharacterChangingAlphaLosen",
        "f18FreeCameraPullupTimeAtJump"
    ]);

    m
});
