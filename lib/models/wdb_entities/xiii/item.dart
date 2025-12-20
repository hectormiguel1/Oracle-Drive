import 'package:ff13_mod_resource/models/wdb_entities/converters.dart';
import 'package:ff13_mod_resource/models/wdb_entities/wdb_entity.dart';
import 'package:ff13_mod_resource/models/wdb_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'item.g.dart';

@JsonSerializable()
class Item extends WdbEntity {
  @JsonKey(name: 'sItemNameStringId', defaultValue: '')
  final String itemNameStringId;

  @JsonKey(name: 'sHelpStringId', defaultValue: '')
  final String helpStringId;

  @JsonKey(name: 'sScriptId', defaultValue: '')
  final String scriptId;

  @JsonKey(name: 'uPurchasePrice', defaultValue: 0)
  final int purchasePrice;

  @JsonKey(name: 'uSellPrice', defaultValue: 0)
  final int sellPrice;

  @JsonKey(name: 'u8MenuIcon', defaultValue: 0)
  final int menuIcon;

  @JsonKey(name: 'u8ItemCategory', defaultValue: 0)
  final int itemCategory;

  @JsonKey(name: 'i16ScriptArg0', defaultValue: 0)
  final int scriptArg0;

  @JsonKey(name: 'i16ScriptArg1', defaultValue: 0)
  final int scriptArg1;

  @JsonKey(name: 'u1IsUseBattleMenu')
  @BoolIntConverter()
  final bool isUseBattleMenu;

  @JsonKey(name: 'u1IsUseMenu')
  @BoolIntConverter()
  final bool isUseMenu;

  @JsonKey(name: 'u1IsDisposable')
  @BoolIntConverter()
  final bool isDisposable;

  @JsonKey(name: 'u1IsSellable')
  @BoolIntConverter()
  final bool isSellable;

  @JsonKey(name: 'u5Rank', defaultValue: 0)
  final int rank;

  @JsonKey(name: 'u6Genre', defaultValue: 0)
  final int genre;

  @JsonKey(name: 'u1IsIgnoreGenre')
  @BoolIntConverter()
  final bool isIgnoreGenre;

  @JsonKey(name: 'u16SortAllByKCategory', defaultValue: 0)
  final int sortAllByKCategory;

  @JsonKey(name: 'u16SortCategoryByCategory', defaultValue: 0)
  final int sortCategoryByCategory;

  @JsonKey(name: 'u16Experience', defaultValue: 0)
  final int experience;

  @JsonKey(name: 'i8Mulitplier', defaultValue: 0)
  final int multiplier;

  @JsonKey(name: 'u1IsUseItemChange')
  @BoolIntConverter()
  final bool isUseItemChange;

  Item({
    required this.itemNameStringId,
    required this.helpStringId,
    required this.scriptId,
    required this.purchasePrice,
    required this.sellPrice,
    required this.menuIcon,
    required this.itemCategory,
    required this.scriptArg0,
    required this.scriptArg1,
    required this.isUseBattleMenu,
    required this.isUseMenu,
    required this.isDisposable,
    required this.isSellable,
    required this.rank,
    required this.genre,
    required this.isIgnoreGenre,
    required this.sortAllByKCategory,
    required this.sortCategoryByCategory,
    required this.experience,
    required this.multiplier,
    required this.isUseItemChange,
  });

  factory Item.fromMap(Map<String, dynamic> json) => _$ItemFromJson(json);

  static List<Item> fromWdbData(WdbData data) {
    return data.rows.map((e) => Item.fromMap(e)).toList();
  }

  @override
  Map<String, dynamic> toMap() => _$ItemToJson(this);

  @override
  Map<LookupType, List<String>>? getLookupKeys() {
    return {
      LookupType.direct: ['sItemNameStringId', 'sHelpStringId'],
    };
  }
}
