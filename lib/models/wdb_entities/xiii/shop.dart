import 'package:ff13_mod_resource/models/wdb_entities/wdb_entity.dart';
import 'package:ff13_mod_resource/models/wdb_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'shop.g.dart';

@JsonSerializable()
class Shop extends WdbEntity {
  @JsonKey(name: 'sFlagItemId', defaultValue: '')
  final String flagItemId;

  @JsonKey(name: 'sUnlockEventID', defaultValue: '')
  final String unlockEventID;

  @JsonKey(name: 'sShopNameLabel', defaultValue: '')
  final String shopNameLabel;

  @JsonKey(name: 'sSignId', defaultValue: '')
  final String signId;

  @JsonKey(name: 'sExplanationLabel', defaultValue: '')
  final String explanationLabel;

  @JsonKey(name: 'sUnkStringVal1', defaultValue: '')
  final String unkStringVal1;

  @JsonKey(name: 'sItemLabel1', defaultValue: '')
  final String itemLabel1;

  @JsonKey(name: 'sItemLabel2', defaultValue: '')
  final String itemLabel2;

  @JsonKey(name: 'sItemLabel3', defaultValue: '')
  final String itemLabel3;

  @JsonKey(name: 'sItemLabel4', defaultValue: '')
  final String itemLabel4;

  @JsonKey(name: 'sItemLabel5', defaultValue: '')
  final String itemLabel5;

  @JsonKey(name: 'sItemLabel6', defaultValue: '')
  final String itemLabel6;

  @JsonKey(name: 'sItemLabel7', defaultValue: '')
  final String itemLabel7;

  @JsonKey(name: 'sItemLabel8', defaultValue: '')
  final String itemLabel8;

  @JsonKey(name: 'sItemLabel9', defaultValue: '')
  final String itemLabel9;

  @JsonKey(name: 'sItemLabel10', defaultValue: '')
  final String itemLabel10;

  @JsonKey(name: 'sItemLabel11', defaultValue: '')
  final String itemLabel11;

  @JsonKey(name: 'sItemLabel12', defaultValue: '')
  final String itemLabel12;

  @JsonKey(name: 'sItemLabel13', defaultValue: '')
  final String itemLabel13;

  @JsonKey(name: 'sItemLabel14', defaultValue: '')
  final String itemLabel14;

  @JsonKey(name: 'sItemLabel15', defaultValue: '')
  final String itemLabel15;

  @JsonKey(name: 'sItemLabel16', defaultValue: '')
  final String itemLabel16;

  @JsonKey(name: 'sItemLabel17', defaultValue: '')
  final String itemLabel17;

  @JsonKey(name: 'sItemLabel18', defaultValue: '')
  final String itemLabel18;

  @JsonKey(name: 'sItemLabel19', defaultValue: '')
  final String itemLabel19;

  @JsonKey(name: 'sItemLabel20', defaultValue: '')
  final String itemLabel20;

  @JsonKey(name: 'sItemLabel21', defaultValue: '')
  final String itemLabel21;

  @JsonKey(name: 'sItemLabel22', defaultValue: '')
  final String itemLabel22;

  @JsonKey(name: 'sItemLabel23', defaultValue: '')
  final String itemLabel23;

  @JsonKey(name: 'sItemLabel24', defaultValue: '')
  final String itemLabel24;

  @JsonKey(name: 'sItemLabel25', defaultValue: '')
  final String itemLabel25;

  @JsonKey(name: 'sItemLabel26', defaultValue: '')
  final String itemLabel26;

  @JsonKey(name: 'sItemLabel27', defaultValue: '')
  final String itemLabel27;

  @JsonKey(name: 'sItemLabel28', defaultValue: '')
  final String itemLabel28;

  @JsonKey(name: 'sItemLabel29', defaultValue: '')
  final String itemLabel29;

  @JsonKey(name: 'sItemLabel30', defaultValue: '')
  final String itemLabel30;

  @JsonKey(name: 'sItemLabel31', defaultValue: '')
  final String itemLabel31;

  @JsonKey(name: 'sItemLabel32', defaultValue: '')
  final String itemLabel32;

  @JsonKey(name: 'u4Version', defaultValue: 0)
  final int version;

  @JsonKey(name: 'u13ZoneNum', defaultValue: 0)
  final int zoneNum;

  Shop({
    required this.flagItemId,
    required this.unlockEventID,
    required this.shopNameLabel,
    required this.signId,
    required this.explanationLabel,
    required this.unkStringVal1,
    required this.itemLabel1,
    required this.itemLabel2,
    required this.itemLabel3,
    required this.itemLabel4,
    required this.itemLabel5,
    required this.itemLabel6,
    required this.itemLabel7,
    required this.itemLabel8,
    required this.itemLabel9,
    required this.itemLabel10,
    required this.itemLabel11,
    required this.itemLabel12,
    required this.itemLabel13,
    required this.itemLabel14,
    required this.itemLabel15,
    required this.itemLabel16,
    required this.itemLabel17,
    required this.itemLabel18,
    required this.itemLabel19,
    required this.itemLabel20,
    required this.itemLabel21,
    required this.itemLabel22,
    required this.itemLabel23,
    required this.itemLabel24,
    required this.itemLabel25,
    required this.itemLabel26,
    required this.itemLabel27,
    required this.itemLabel28,
    required this.itemLabel29,
    required this.itemLabel30,
    required this.itemLabel31,
    required this.itemLabel32,
    required this.version,
    required this.zoneNum,
  });

  factory Shop.fromMap(Map<String, dynamic> json) => _$ShopFromJson(json);

  static List<Shop> fromWdbData(WdbData data) {
    return data.rows.map((e) => Shop.fromMap(e)).toList();
  }

  @override
  Map<String, dynamic> toMap() => _$ShopToJson(this);

  @override
  Map<LookupType, List<String>>? getLookupKeys() {
    return {
      .direct: ['sShopNameLabel'],
      .item: [
        'sFlagItemId',
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
    };
  }
}
