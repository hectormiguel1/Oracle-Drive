import 'package:ff13_mod_resource/models/wdb_entities/converters.dart';
import 'package:ff13_mod_resource/models/wdb_entities/wdb_entity.dart';
import 'package:ff13_mod_resource/models/wdb_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'mission.g.dart';

@JsonSerializable()
class Mission extends WdbEntity {
  @JsonKey(name: 'sMissionTitleStringId', defaultValue: '')
  final String missionTitleStringId;

  @JsonKey(name: 'sMissionExplanationStringId', defaultValue: '')
  final String missionExplanationStringId;

  @JsonKey(name: 'sMissionTargetStringId', defaultValue: '')
  final String missionTargetStringId;

  @JsonKey(name: 'sMissionPosStringId', defaultValue: '')
  final String missionPosStringId;

  @JsonKey(name: 'sMissionMarkPosStringId', defaultValue: '')
  final String missionMarkPosStringId;

  @JsonKey(name: 'sPosMarkerName', defaultValue: '')
  final String posMarkerName;

  @JsonKey(name: 'sTreasureBoxId0', defaultValue: '')
  final String treasureBoxId0;

  @JsonKey(name: 'sTreasureBoxId1', defaultValue: '')
  final String treasureBoxId1;

  @JsonKey(name: 'sTreasureBoxId2', defaultValue: '')
  final String treasureBoxId2;

  @JsonKey(name: 'sCharasetId0', defaultValue: '')
  final String charasetId0;

  @JsonKey(name: 'sCharasetId1', defaultValue: '')
  final String charasetId1;

  @JsonKey(name: 'sCharasetId2', defaultValue: '')
  final String charasetId2;

  @JsonKey(name: 'sCharasetId3', defaultValue: '')
  final String charasetId3;

  @JsonKey(name: 'sCharaspecId0', defaultValue: '')
  final String charaspecId0;

  @JsonKey(name: 'sCharaspecId1', defaultValue: '')
  final String charaspecId1;

  @JsonKey(name: 'sCharaspecId2', defaultValue: '')
  final String charaspecId2;

  @JsonKey(name: 'sCharaspecId3', defaultValue: '')
  final String charaspecId3;

  @JsonKey(name: 'sCharaspecId4', defaultValue: '')
  final String charaspecId4;

  @JsonKey(name: 'sAreaActivationName', defaultValue: '')
  final String areaActivationName;

  @JsonKey(name: 'iBattleSceneNum', defaultValue: 0)
  final int battleSceneNum;

  @JsonKey(name: 'u8ZoneNum', defaultValue: 0)
  final int zoneNum;

  @JsonKey(name: 'u6IndexInMapMenu', defaultValue: 0)
  final int indexInMapMenu;

  @JsonKey(name: 'u4Class', defaultValue: 0)
  final int missionClass;

  @JsonKey(name: 'u6MissionPictureId', defaultValue: 0)
  final int missionPictureId;

  @JsonKey(name: 'u1UnkBool1')
  @BoolIntConverter()
  final bool unkBool1;

  @JsonKey(name: 'u1UnkBool2')
  @BoolIntConverter()
  final bool unkBool2;

  @JsonKey(name: 'u1UnkBool3')
  @BoolIntConverter()
  final bool unkBool3;

  Mission({
    required this.missionTitleStringId,
    required this.missionExplanationStringId,
    required this.missionTargetStringId,
    required this.missionPosStringId,
    required this.missionMarkPosStringId,
    required this.posMarkerName,
    required this.treasureBoxId0,
    required this.treasureBoxId1,
    required this.treasureBoxId2,
    required this.charasetId0,
    required this.charasetId1,
    required this.charasetId2,
    required this.charasetId3,
    required this.charaspecId0,
    required this.charaspecId1,
    required this.charaspecId2,
    required this.charaspecId3,
    required this.charaspecId4,
    required this.areaActivationName,
    required this.battleSceneNum,
    required this.zoneNum,
    required this.indexInMapMenu,
    required this.missionClass,
    required this.missionPictureId,
    required this.unkBool1,
    required this.unkBool2,
    required this.unkBool3,
  });

  factory Mission.fromMap(Map<String, dynamic> json) => _$MissionFromJson(json);

  static List<Mission> fromWdbData(WdbData data) {
    return data.rows.map((e) => Mission.fromMap(e)).toList();
  }

  @override
  Map<String, dynamic> toMap() => _$MissionToJson(this);

  @override
  Map<LookupType, List<String>>? getLookupKeys() {
    return {
      LookupType.direct: [
        'sMissionTitleStringId',
        'sMissionExplanationStringId',
        'sMissionTargetStringId',
        'sMissionPosStringId',
        'sMissionMarkPosStringId',
      ],
    };
  }
}
