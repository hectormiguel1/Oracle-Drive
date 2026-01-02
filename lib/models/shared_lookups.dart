/// Lookup type for string ID resolution
enum LookupType { direct, item, ability }

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
  "BtAbilityGrow": {
    .item: ['sRankupItem2', 'sRankupItem3', 'sRankupItem4', 'sRankupItem5'],
    .ability: [
      'sPasvAbility1',
      'sPasvAbility2',
      'sPasvAbility3',
      'sPasvAbility4',
      'sPasvAbility5',
      'sPasvAbility6',
      'sPasvAbility7',
      'sPasvAbility8',
      'sPasvAbility9',
      'sPasvAbility10',
      'sPasvAbility11',
      'sPasvAbility12',
      'sPasvAbility13',
      'sPasvAbility14',
      'sPasvAbility15',
      'sPasvAbility16',
    ],
  },
  "PassiveAbility": {
    .direct: ['sStringResId', 'sInfoStResId'],
  },
  "SpecialAbility": {
    .ability: ['sAbility'],
  },
  "BtRankedAbility": {
    .item: [
      'sReboot1ItemId',
      'sReboot2ItemId',
      'sReboot3ItemId',
      'sRankUp1ItemId',
      'sRankUp2ItemId',
      'sRankUp3ItemId',
      'sPowItemId',
      'sAtbItemId',
      'sChainItemId',
      'sHqItemId',
      'sDisItem1Id',
      'sDisItem2Id',
      'sDisItem3Id',
    ],
    .ability: ['sAbilityId'],
  },
  'QuestControl': {
    .direct: [
      'sQuestNameLabel',
      'sQuestTextLabel',
      'sClientLabel',
      'sRewardTextLabel',
      'sMissionClientName',
      'sClearTextLabel',
      'sFailureText',
      'sStepText1',
      'sStepText2',
      'sStepText3',
      'sStepText4',
      'sStepText5',
    ],
  },
  'Reward': {
    .item: ["sItemId"],
  },
};
