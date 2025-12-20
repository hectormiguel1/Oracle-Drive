import 'package:oracle_drive/models/wdb_entities/wdb_entity.dart';

Map<String, Map<LookupType, List<String>>> get sharedLookups => {
  'treasurebox': {
    .item: ['sItemResourceId'],
  },

  "r_fragment": {
    .direct: ['sNameStringId', 'sDetailStringId', 'sKeyId'],
  },
  'r_historia': {
    .direct: ['s7BriefingText1', 's7BriefingText2', 's7BriefingText3'],
  },
  'r_bt_bns_mis': {
    .direct: ["sName"],
  },
  'r_bt_bns_pri': {
    .direct: ["sName"],
  },
  'r_bt_curricu': {
    .direct: ['sNameStringId', 'sTargetStringId'],
  },
  'item_weapon': {
    .direct: ['sAbilityName', 'sOtherItemId'],
  },
};
