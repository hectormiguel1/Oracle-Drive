import 'package:oracle_drive/src/isar/common/models.dart' show fastHash;
import 'package:isar_plus/isar_plus.dart';
import 'package:oracle_drive/models/wdb_entities/xiii/mission.dart'
    as wdb_entity;

part 'mission.g.dart';

@Collection()
class Mission {
  @Index()
  String record; // Primary key from WDB
  String missionTitleStringId;
  String missionExplanationStringId;
  String missionTargetStringId;
  String missionPosStringId;
  String missionMarkPosStringId;

  Mission({
    required this.record,
    required this.missionTitleStringId,
    required this.missionExplanationStringId,
    required this.missionTargetStringId,
    required this.missionPosStringId,
    required this.missionMarkPosStringId,
  });

  factory Mission.fromWdbEntity(String record, wdb_entity.Mission wdbMission) {
    return Mission(
      record: record,
      missionTitleStringId: wdbMission.missionTitleStringId,
      missionExplanationStringId: wdbMission.missionExplanationStringId,
      missionTargetStringId: wdbMission.missionTargetStringId,
      missionPosStringId: wdbMission.missionPosStringId,
      missionMarkPosStringId: wdbMission.missionMarkPosStringId,
    );
  }

  int get id => fastHash(record);
}
