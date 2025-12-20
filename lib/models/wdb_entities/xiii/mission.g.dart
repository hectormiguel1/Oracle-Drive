// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mission.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Mission _$MissionFromJson(Map<String, dynamic> json) => Mission(
  missionTitleStringId: json['sMissionTitleStringId'] as String? ?? '',
  missionExplanationStringId:
      json['sMissionExplanationStringId'] as String? ?? '',
  missionTargetStringId: json['sMissionTargetStringId'] as String? ?? '',
  missionPosStringId: json['sMissionPosStringId'] as String? ?? '',
  missionMarkPosStringId: json['sMissionMarkPosStringId'] as String? ?? '',
  posMarkerName: json['sPosMarkerName'] as String? ?? '',
  treasureBoxId0: json['sTreasureBoxId0'] as String? ?? '',
  treasureBoxId1: json['sTreasureBoxId1'] as String? ?? '',
  treasureBoxId2: json['sTreasureBoxId2'] as String? ?? '',
  charasetId0: json['sCharasetId0'] as String? ?? '',
  charasetId1: json['sCharasetId1'] as String? ?? '',
  charasetId2: json['sCharasetId2'] as String? ?? '',
  charasetId3: json['sCharasetId3'] as String? ?? '',
  charaspecId0: json['sCharaspecId0'] as String? ?? '',
  charaspecId1: json['sCharaspecId1'] as String? ?? '',
  charaspecId2: json['sCharaspecId2'] as String? ?? '',
  charaspecId3: json['sCharaspecId3'] as String? ?? '',
  charaspecId4: json['sCharaspecId4'] as String? ?? '',
  areaActivationName: json['sAreaActivationName'] as String? ?? '',
  battleSceneNum: (json['iBattleSceneNum'] as num?)?.toInt() ?? 0,
  zoneNum: (json['u8ZoneNum'] as num?)?.toInt() ?? 0,
  indexInMapMenu: (json['u6IndexInMapMenu'] as num?)?.toInt() ?? 0,
  missionClass: (json['u4Class'] as num?)?.toInt() ?? 0,
  missionPictureId: (json['u6MissionPictureId'] as num?)?.toInt() ?? 0,
  unkBool1: const BoolIntConverter().fromJson(json['u1UnkBool1']),
  unkBool2: const BoolIntConverter().fromJson(json['u1UnkBool2']),
  unkBool3: const BoolIntConverter().fromJson(json['u1UnkBool3']),
);

Map<String, dynamic> _$MissionToJson(Mission instance) => <String, dynamic>{
  'sMissionTitleStringId': instance.missionTitleStringId,
  'sMissionExplanationStringId': instance.missionExplanationStringId,
  'sMissionTargetStringId': instance.missionTargetStringId,
  'sMissionPosStringId': instance.missionPosStringId,
  'sMissionMarkPosStringId': instance.missionMarkPosStringId,
  'sPosMarkerName': instance.posMarkerName,
  'sTreasureBoxId0': instance.treasureBoxId0,
  'sTreasureBoxId1': instance.treasureBoxId1,
  'sTreasureBoxId2': instance.treasureBoxId2,
  'sCharasetId0': instance.charasetId0,
  'sCharasetId1': instance.charasetId1,
  'sCharasetId2': instance.charasetId2,
  'sCharasetId3': instance.charasetId3,
  'sCharaspecId0': instance.charaspecId0,
  'sCharaspecId1': instance.charaspecId1,
  'sCharaspecId2': instance.charaspecId2,
  'sCharaspecId3': instance.charaspecId3,
  'sCharaspecId4': instance.charaspecId4,
  'sAreaActivationName': instance.areaActivationName,
  'iBattleSceneNum': instance.battleSceneNum,
  'u8ZoneNum': instance.zoneNum,
  'u6IndexInMapMenu': instance.indexInMapMenu,
  'u4Class': instance.missionClass,
  'u6MissionPictureId': instance.missionPictureId,
  'u1UnkBool1': const BoolIntConverter().toJson(instance.unkBool1),
  'u1UnkBool2': const BoolIntConverter().toJson(instance.unkBool2),
  'u1UnkBool3': const BoolIntConverter().toJson(instance.unkBool3),
};
