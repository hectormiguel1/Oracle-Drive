import 'package:oracle_drive/models/wdb_entities/converters.dart';
import 'package:oracle_drive/models/wdb_entities/wdb_entity.dart';
import 'package:oracle_drive/models/wdb_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'battle_ability.g.dart';

@JsonSerializable()
class BattleAbility extends WdbEntity {
  @JsonKey(name: 'sStringResId', defaultValue: '')
  final String stringResId;

  @JsonKey(name: 'sInfoStResId', defaultValue: '')
  final String infoStResId;

  @JsonKey(name: 'sScriptId', defaultValue: '')
  final String scriptId;

  @JsonKey(name: 'sAblArgStr0', defaultValue: '')
  final String ablArgStr0;

  @JsonKey(name: 'sAblArgStr1', defaultValue: '')
  final String ablArgStr1;

  @JsonKey(name: 'sAutoAblStEff0', defaultValue: '')
  final String autoAblStEff0;

  @JsonKey(name: 'fDistanceMin', defaultValue: 0.0)
  final double distanceMin;

  @JsonKey(name: 'fDistanceMax', defaultValue: 0.0)
  final double distanceMax;

  @JsonKey(name: 'fMaxJumpHeight', defaultValue: 0.0)
  final double maxJumpHeight;

  @JsonKey(name: 'fYDistanceMin', defaultValue: 0.0)
  final double yDistanceMin;

  @JsonKey(name: 'fYDistanceMax', defaultValue: 0.0)
  final double yDistanceMax;

  @JsonKey(name: 'fAirJpHeight', defaultValue: 0.0)
  final double airJpHeight;

  @JsonKey(name: 'fAirJpTime', defaultValue: 0.0)
  final double airJpTime;

  @JsonKey(name: 'sReplaceAirAttack', defaultValue: '')
  final String replaceAirAttack;

  @JsonKey(name: 'sReplaceAirAir', defaultValue: '')
  final String replaceAirAir;

  @JsonKey(name: 'sReplaceRangeAtk', defaultValue: '')
  final String replaceRangeAtk;

  @JsonKey(name: 'sReplaceFinAtk', defaultValue: '')
  final String replaceFinAtk;

  @JsonKey(name: 'sReplaceEnAttr', defaultValue: '')
  final String replaceEnAttr;

  @JsonKey(name: 'iExceptionID', defaultValue: 0)
  final int exceptionID;

  @JsonKey(name: 'sActionId0', defaultValue: '')
  final String actionId0;

  @JsonKey(name: 'sActionId1', defaultValue: '')
  final String actionId1;

  @JsonKey(name: 'sActionId2', defaultValue: '')
  final String actionId2;

  @JsonKey(name: 'sActionId3', defaultValue: '')
  final String actionId3;

  @JsonKey(name: 'sRtDamSrc', defaultValue: '')
  final String rtDamSrc;

  @JsonKey(name: 'sRefDamSrc', defaultValue: '')
  final String refDamSrc;

  @JsonKey(name: 'sSubRefDamSrc', defaultValue: '')
  final String subRefDamSrc;

  @JsonKey(name: 'sSlamDamSrc', defaultValue: '')
  final String slamDamSrc;

  @JsonKey(name: 'sCamArtsSeqId0', defaultValue: '')
  final String camArtsSeqId0;

  @JsonKey(name: 'sCamArtsSeqId1', defaultValue: '')
  final String camArtsSeqId1;

  @JsonKey(name: 'sCamArtsSeqId2', defaultValue: '')
  final String camArtsSeqId2;

  @JsonKey(name: 'sCamArtsSeqId3', defaultValue: '')
  final String camArtsSeqId3;

  @JsonKey(name: 'sRedirectAbility0', defaultValue: '')
  final String redirectAbility0;

  @JsonKey(name: 'sRedirectTo0', defaultValue: '')
  final String redirectTo0;

  @JsonKey(name: 'sRedirectAbility1', defaultValue: '')
  final String redirectAbility1;

  @JsonKey(name: 'sRedirectTo1', defaultValue: '')
  final String redirectTo1;

  @JsonKey(name: 'sRedirectAbility2', defaultValue: '')
  final String redirectAbility2;

  @JsonKey(name: 'sRedirectTo2', defaultValue: '')
  final String redirectTo2;

  @JsonKey(name: 'sRedirectAbility3', defaultValue: '')
  final String redirectAbility3;

  @JsonKey(name: 'sRedirectTo3', defaultValue: '')
  final String redirectTo3;

  @JsonKey(name: 'sSysEffId0', defaultValue: '')
  final String sysEffId0;

  @JsonKey(name: 'iSysEffArg0', defaultValue: 0)
  final int sysEffArg0;

  @JsonKey(name: 'sSysSndId0', defaultValue: '')
  final String sysSndId0;

  @JsonKey(name: 'sRtEffId0', defaultValue: '')
  final String rtEffId0;

  @JsonKey(name: 'iRtEffArg0', defaultValue: 0)
  final int rtEffArg0;

  @JsonKey(name: 'sRtSndId0', defaultValue: '')
  final String rtSndId0;

  @JsonKey(name: 'sRtEffId1', defaultValue: '')
  final String rtEffId1;

  @JsonKey(name: 'iRtEffArg1', defaultValue: 0)
  final int rtEffArg1;

  @JsonKey(name: 'sRtSndId1', defaultValue: '')
  final String rtSndId1;

  @JsonKey(name: 'sRtEffId2', defaultValue: '')
  final String rtEffId2;

  @JsonKey(name: 'iRtEffArg2', defaultValue: 0)
  final int rtEffArg2;

  @JsonKey(name: 'sRtSndId2', defaultValue: '')
  final String rtSndId2;

  @JsonKey(name: 'sRtEffId3', defaultValue: '')
  final String rtEffId3;

  @JsonKey(name: 'iRtEffArg3', defaultValue: 0)
  final int rtEffArg3;

  @JsonKey(name: 'sRtSndId3', defaultValue: '')
  final String rtSndId3;

  @JsonKey(name: 'sRtEffId4', defaultValue: '')
  final String rtEffId4;

  @JsonKey(name: 'iRtEffArg4', defaultValue: 0)
  final int rtEffArg4;

  @JsonKey(name: 'sRtSndId4', defaultValue: '')
  final String rtSndId4;

  @JsonKey(name: 'u1ComAbility')
  @BoolIntConverter()
  final bool comAbility;

  @JsonKey(name: 'u1RsvFlag0')
  @BoolIntConverter()
  final bool rsvFlag0;

  @JsonKey(name: 'u1RsvFlag1')
  @BoolIntConverter()
  final bool rsvFlag1;

  @JsonKey(name: 'u1RsvFlag2')
  @BoolIntConverter()
  final bool rsvFlag2;

  @JsonKey(name: 'u1RsvFlag3')
  @BoolIntConverter()
  final bool rsvFlag3;

  @JsonKey(name: 'u1RsvFlag4')
  @BoolIntConverter()
  final bool rsvFlag4;

  @JsonKey(name: 'u1RsvFlag5')
  @BoolIntConverter()
  final bool rsvFlag5;

  @JsonKey(name: 'u1RsvFlag6')
  @BoolIntConverter()
  final bool rsvFlag6;

  @JsonKey(name: 'u4ArtsNameHideKd', defaultValue: 0)
  final int artsNameHideKd;

  @JsonKey(name: 'u16ArtsNameFrame', defaultValue: 0)
  final int artsNameFrame;

  @JsonKey(name: 'u4UseRole', defaultValue: 0)
  final int useRole;

  @JsonKey(name: 'u8AblSndKind', defaultValue: 0)
  final int ablSndKind;

  @JsonKey(name: 'u4MenuCategory', defaultValue: 0)
  final int menuCategory;

  @JsonKey(name: 'i16MenuSortNo', defaultValue: 0)
  final int menuSortNo;

  @JsonKey(name: 'u1NoDespel')
  @BoolIntConverter()
  final bool noDespel;

  @JsonKey(name: 'i16ScriptArg0', defaultValue: 0)
  final int scriptArg0;

  @JsonKey(name: 'i16ScriptArg1', defaultValue: 0)
  final int scriptArg1;

  @JsonKey(name: 'u8AbilityKind', defaultValue: 0)
  final int abilityKind;

  @JsonKey(name: 'u4TargetListKind', defaultValue: 0)
  final int targetListKind;

  @JsonKey(name: 'i16AblArgInt0', defaultValue: 0)
  final int ablArgInt0;

  @JsonKey(name: 'u4UpAblKind', defaultValue: 0)
  final int upAblKind;

  @JsonKey(name: 'i16AblArgInt1', defaultValue: 0)
  final int ablArgInt1;

  @JsonKey(name: 'i16AtbCount', defaultValue: 0)
  final int atbCount;

  @JsonKey(name: 'i16AtRnd', defaultValue: 0)
  final int atRnd;

  @JsonKey(name: 'i16KeepVal', defaultValue: 0)
  final int keepVal;

  @JsonKey(name: 'i16IntRsv0', defaultValue: 0)
  final int intRsv0;

  @JsonKey(name: 'i16IntRsv1', defaultValue: 0)
  final int intRsv1;

  @JsonKey(name: 'u1TgFoge')
  @BoolIntConverter()
  final bool tgFoge;

  @JsonKey(name: 'u1NoBackStep')
  @BoolIntConverter()
  final bool noBackStep;

  @JsonKey(name: 'u1AIWanderFlag')
  @BoolIntConverter()
  final bool aiWanderFlag;

  @JsonKey(name: 'u16TgElemId', defaultValue: 0)
  final int tgElemId;

  @JsonKey(name: 'u10OpProp0', defaultValue: 0)
  final int opProp0;

  @JsonKey(name: 'u1AutoAblStEfEd0')
  @BoolIntConverter()
  final bool autoAblStEfEd0;

  @JsonKey(name: 'u1CheckAutoRpl')
  @BoolIntConverter()
  final bool checkAutoRpl;

  @JsonKey(name: 'u1SeqParts')
  @BoolIntConverter()
  final bool seqParts;

  @JsonKey(name: 'i16AutoAblStEfTi0', defaultValue: 0)
  final int autoAblStEfTi0;

  @JsonKey(name: 'u4YRgCheckType', defaultValue: 0)
  final int yRgCheckType;

  @JsonKey(name: 'u4AtDistKind', defaultValue: 0)
  final int atDistKind;

  @JsonKey(name: 'u4JumpAttackType', defaultValue: 0)
  final int jumpAttackType;

  @JsonKey(name: 'u1SeqTermination')
  @BoolIntConverter()
  final bool seqTermination;

  @JsonKey(name: 'u5ActSelType', defaultValue: 0)
  final int actSelType;

  @JsonKey(name: 'u4LoopFinCond', defaultValue: 0)
  final int loopFinCond;

  @JsonKey(name: 'u16LoopFinArg', defaultValue: 0)
  final int loopFinArg;

  @JsonKey(name: 'u4RedirectMargeNof0', defaultValue: 0)
  final int redirectMargeNof0;

  @JsonKey(name: 'i16RefDamSrcRpt', defaultValue: 0)
  final int refDamSrcRpt;

  @JsonKey(name: 'i16SubRefDamSrcRp', defaultValue: 0)
  final int subRefDamSrcRp;

  @JsonKey(name: 'i8AreaRad', defaultValue: 0)
  final int areaRad;

  @JsonKey(name: 'u8CamArtsSelType', defaultValue: 0)
  final int camArtsSelType;

  @JsonKey(name: 'u4RedirectMargeNof1', defaultValue: 0)
  final int redirectMargeNof1;

  @JsonKey(name: 'u4RedirectMargeNof2', defaultValue: 0)
  final int redirectMargeNof2;

  @JsonKey(name: 'u4RedirectMargeNof3', defaultValue: 0)
  final int redirectMargeNof3;

  @JsonKey(name: 'u16SysEffPos0', defaultValue: 0)
  final int sysEffPos0;

  @JsonKey(name: 'u16RtEffPos0', defaultValue: 0)
  final int rtEffPos0;

  @JsonKey(name: 'u16RtEffPos1', defaultValue: 0)
  final int rtEffPos1;

  @JsonKey(name: 'u16RtEffPos2', defaultValue: 0)
  final int rtEffPos2;

  @JsonKey(name: 'u16RtEffPos3', defaultValue: 0)
  final int rtEffPos3;

  @JsonKey(name: 'u16RtEffPos4', defaultValue: 0)
  final int rtEffPos4;

  BattleAbility({
    required this.stringResId,
    required this.infoStResId,
    required this.scriptId,
    required this.ablArgStr0,
    required this.ablArgStr1,
    required this.autoAblStEff0,
    required this.distanceMin,
    required this.distanceMax,
    required this.maxJumpHeight,
    required this.yDistanceMin,
    required this.yDistanceMax,
    required this.airJpHeight,
    required this.airJpTime,
    required this.replaceAirAttack,
    required this.replaceAirAir,
    required this.replaceRangeAtk,
    required this.replaceFinAtk,
    required this.replaceEnAttr,
    required this.exceptionID,
    required this.actionId0,
    required this.actionId1,
    required this.actionId2,
    required this.actionId3,
    required this.rtDamSrc,
    required this.refDamSrc,
    required this.subRefDamSrc,
    required this.slamDamSrc,
    required this.camArtsSeqId0,
    required this.camArtsSeqId1,
    required this.camArtsSeqId2,
    required this.camArtsSeqId3,
    required this.redirectAbility0,
    required this.redirectTo0,
    required this.redirectAbility1,
    required this.redirectTo1,
    required this.redirectAbility2,
    required this.redirectTo2,
    required this.redirectAbility3,
    required this.redirectTo3,
    required this.sysEffId0,
    required this.sysEffArg0,
    required this.sysSndId0,
    required this.rtEffId0,
    required this.rtEffArg0,
    required this.rtSndId0,
    required this.rtEffId1,
    required this.rtEffArg1,
    required this.rtSndId1,
    required this.rtEffId2,
    required this.rtEffArg2,
    required this.rtSndId2,
    required this.rtEffId3,
    required this.rtEffArg3,
    required this.rtSndId3,
    required this.rtEffId4,
    required this.rtEffArg4,
    required this.rtSndId4,
    required this.comAbility,
    required this.rsvFlag0,
    required this.rsvFlag1,
    required this.rsvFlag2,
    required this.rsvFlag3,
    required this.rsvFlag4,
    required this.rsvFlag5,
    required this.rsvFlag6,
    required this.artsNameHideKd,
    required this.artsNameFrame,
    required this.useRole,
    required this.ablSndKind,
    required this.menuCategory,
    required this.menuSortNo,
    required this.noDespel,
    required this.scriptArg0,
    required this.scriptArg1,
    required this.abilityKind,
    required this.targetListKind,
    required this.ablArgInt0,
    required this.upAblKind,
    required this.ablArgInt1,
    required this.atbCount,
    required this.atRnd,
    required this.keepVal,
    required this.intRsv0,
    required this.intRsv1,
    required this.tgFoge,
    required this.noBackStep,
    required this.aiWanderFlag,
    required this.tgElemId,
    required this.opProp0,
    required this.autoAblStEfEd0,
    required this.checkAutoRpl,
    required this.seqParts,
    required this.autoAblStEfTi0,
    required this.yRgCheckType,
    required this.atDistKind,
    required this.jumpAttackType,
    required this.seqTermination,
    required this.actSelType,
    required this.loopFinCond,
    required this.loopFinArg,
    required this.redirectMargeNof0,
    required this.refDamSrcRpt,
    required this.subRefDamSrcRp,
    required this.areaRad,
    required this.camArtsSelType,
    required this.redirectMargeNof1,
    required this.redirectMargeNof2,
    required this.redirectMargeNof3,
    required this.sysEffPos0,
    required this.rtEffPos0,
    required this.rtEffPos1,
    required this.rtEffPos2,
    required this.rtEffPos3,
    required this.rtEffPos4,
  });

  factory BattleAbility.fromMap(Map<String, dynamic> json) =>
      _$BattleAbilityFromJson(json);

  static List<BattleAbility> fromWdbData(WdbData data) {
    return data.rows.map((e) => BattleAbility.fromMap(e)).toList();
  }

  @override
  Map<String, dynamic> toMap() => _$BattleAbilityToJson(this);

  @override
  Map<LookupType, List<String>>? getLookupKeys() {
    return {
      .direct: ['sStringResId', 'sInfoStResId'],
    };
  }
}
