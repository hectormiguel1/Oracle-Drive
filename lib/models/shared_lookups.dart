/// Lookup type for string ID resolution
enum LookupType { direct, item, ability }

Map<String, Map<LookupType, List<String>>> get sharedLookups => {
  'Item': {
    .direct: ['sItemNameStringId', 'sHelpStringId'],
    .item: ['sRequiredItem', 'sNextItem'],
  },
  'ItemMaterial': {
    .item: ['record'],
  },
  'ItemAbility': {
    .ability: ['record', 'sAbilityId', 'sPasvAbility'],
  },
  'ItemWeapon': {
    .direct: ['sDefStyleName'],
    .ability: [
      'sAbility',
      'sAbility2',
      'sAbility3',
      'sAbilityName',
      'sCosAbilityCir',
      'sCosAbilityCro',
      'sCosAbilityTri',
      'sCosAbilitySqu',
    ],
    .item: [
      'sOtherItemId',
      'sNextItemId',
      'sRankupItem1',
      'sRankupItem2',
      'sRankupItem3',
      'sUpgradeId',
    ],
  },
  'BtAbilityLot': {
    .ability: ['record'],
  },
  'BattleAbility': {
    .direct: ['sStringResId', 'sInfoStResId'],
  },
  'BattleAutoAbility': {
    .direct: ['sStringResId', 'sInfoStResId'],
  },
  'AutoClip': {
    .direct: ['sTitle', 'sTarget', 'sText'],
  },
  'BattleCharaProp': {
    .direct: ['sInfoStrId'],
  },
  'BattleCharaSpec': {
    .direct: ['sNameStrResID'],
    .ability: [
      'sAbility0',
      'sAbility1',
      'sAbility2',
      'sAbility3',
      'sAbility4',
      'sAbility5',
      'sAbility6',
      'sAbility7',
      's12Ability8',
      's12Ability9',
      's12Ability10',
      's8Ability17',
      's12Ability11',
      's12Ability12',
      's8Ability18',
      's12Ability13',
      's12Ability14',
      's8Ability19',
      's12Ability15',
      's8Ability20',
      's8Ability21',
      's8Ability22',
      's8Ability23',
      's8Ability24',
      's8Ability25',
      's8Ability26',
      's8Ability27',
      's8Ability28',
      's8Ability29',
      's8Ability30',
      's8Ability31',
    ],
    .item: [
      'sDropCndItem0',
      'sDropCndItem1',
      'sDropCndItem2',
      's10DropItem0',
      's10DropItem1',
    ],
  },
  'BattleConstants': {
    .ability: ['ssVal'],
  },
  'LocationName': {
    .direct: ['sLocationSimpleName', 'sLocationDetailName'],
  },
  'PlaceName': {
    .direct: ['sNameId'],
  },
  'NoticePoint': {
    .direct: ['sTextResourceId'],
  },
  'PostList': {
    .direct: ['sTitleText', 'sPictureCaption', 'sPictureDescription'],
  },
  'NpcDef': {
    .direct: ['sNameTextLabel', 'sNameTextLabel2'],
  },
  'FragmentPrivilege': {
    .direct: ['sNameStrId', 'sHelpStrId', 'sOptionStrId0', 'sOptionStrId1'],
  },
  'GateTable': {
    .item: [
      'sGateRelationItem0',
      'sGateRelationItem1',
      'sGateRelationItem2',
      'sGateRelationItem3',
      'sGateRelationItem4',
    ],
  },
  'SearchItem': {
    .item: [
      's12ItemName0',
      's12ItemName1',
      's12ItemName2',
      's12ItemName3',
      's12ItemName4',
      's12ItemName5',
      's12ItemName6',
      's12ItemName7',
    ],
  },
  'Shop': {
    .direct: ['sShopNameLabel'],
    .item: [
      'sItemLabel1',
      'sItemLabel2',
      'sItemLabel3',
      'sItemLabel4',
      'sItemLabel5',
      'sItemLabel6',
      'sItemLabel7',
      'sItemLabel8',
      'sItemLabel9',
      'sItemLabel10',
      'sItemLabel11',
      'sItemLabel12',
      'sItemLabel13',
      'sItemLabel14',
      'sItemLabel15',
      'sItemLabel16',
      'sItemLabel17',
      'sItemLabel18',
      'sItemLabel19',
      'sItemLabel20',
      'sItemLabel21',
      'sItemLabel22',
      'sItemLabel23',
      'sItemLabel24',
      'sItemLabel25',
      'sItemLabel26',
      'sItemLabel27',
      'sItemLabel28',
      'sItemLabel29',
      'sItemLabel30',
      'sItemLabel31',
      'sItemLabel32',
    ],
  },
  'MapAreaInfo': {
    .direct: ['sAreaNameId'],
  },
  'Resident': {
    .direct: ['sResourceName'],
  },
  'TreasureBox': {
    .item: ['s11ItemResourceId'],
  },
  'treasurebox': {
    .item: ['sItemResourceId'],
  },
  'MonsterBook': {
    .item: ['sLibraOpenItem'],
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
  'BtUpgrade': {
    .item: [
      'sPhyAtkItemId',
      'sMagAtkItemId',
      'sBrkBonusItemId',
      'sMaxHpItemId',
      'sAtbSpdItemId',
      'sGuardItemId',
      'sAbi1ItemId',
      'sAbi2ItemId',
    ],
    .ability: ['sAbi1Id', 'sAbi2Id'],
  },
  'DownloadContents': {
    .direct: ['s8NameStrResId', 's8HelpStrResId'],
    .item: [
      's8TargetItemId0',
      's8TargetItemId1',
      's8TargetItemId2',
      's8TargetItemId3',
      's8TargetItemId4',
      's8TargetItemId5',
      's8TargetItemId6',
      's8TargetItemId7',
    ],
  },
  'FaObjDef': {
    .direct: ['sLockItemId'],
  },
  'FragmentMission': {
    .direct: ['sNameStringId', 'sDetailStringId'],
  },
  'FaObjStyle': {
    .direct: ['sLabelId'],
  },
  'ColorCustom': {
    .direct: [
      'sNode06_NameStringId',
      'sNode07_NameStringId',
      'sNode08_NameStringId',
      'sNode09_NameStringId',
      'sNode10_NameStringId',
    ],
  },
  'DestPoint': {
    .direct: ['sTextId'],
  },
  'BtCurriculum': {
    .direct: ['sNameStringId', 'sTargetStringId', 'sTalkId0', 'sTalkId1'],
  },
  "PassiveAbility": {
    .direct: ['sStringResId', 'sInfoStResId'],
  },
  "SpecialAbility": {
    .ability: ['sAbility'],
  },
  'SecretAbility': {
    .ability: ['sAbilityId'],
  },
  'BattleScoreResult': {
    .direct: ['sTitleId'],
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
    .item: ['s9ClearItem', 's9ClearItem2', 's9ClearItem3'],
  },
  'Reward': {
    .item: ["sItemId"],
  },
  'Select': {
    .direct: [
      'sCircleText',
      'sCrossText',
      'sTriangleText',
      'sSquareText',
      'sL1Text',
      'sR1Text',
      'sHelpText',
    ],
    .item: [
      's11CircleItemResourceId',
      's11CrossItemResourceId',
      's11TriangleItemResourceId',
      's11SquareItemResourceId',
      's11L1ItemResourceId',
      's11R1ItemResourceId',
    ],
  },
  'TelepoPoint': {
    .direct: ['sTextLabel', 'sHelpLabel'],
  },
  'TextOption': {
    .direct: ['record'],
  },
  'YusColosseum': {
    .direct: ['sRankTextId'],
  },
  'Zone': {
    .direct: ['sName0', 'sName1'],
  },
};
