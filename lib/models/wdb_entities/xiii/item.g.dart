// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Item _$ItemFromJson(Map<String, dynamic> json) => Item(
  itemNameStringId: json['sItemNameStringId'] as String? ?? '',
  helpStringId: json['sHelpStringId'] as String? ?? '',
  scriptId: json['sScriptId'] as String? ?? '',
  purchasePrice: (json['uPurchasePrice'] as num?)?.toInt() ?? 0,
  sellPrice: (json['uSellPrice'] as num?)?.toInt() ?? 0,
  menuIcon: (json['u8MenuIcon'] as num?)?.toInt() ?? 0,
  itemCategory: (json['u8ItemCategory'] as num?)?.toInt() ?? 0,
  scriptArg0: (json['i16ScriptArg0'] as num?)?.toInt() ?? 0,
  scriptArg1: (json['i16ScriptArg1'] as num?)?.toInt() ?? 0,
  isUseBattleMenu: const BoolIntConverter().fromJson(json['u1IsUseBattleMenu']),
  isUseMenu: const BoolIntConverter().fromJson(json['u1IsUseMenu']),
  isDisposable: const BoolIntConverter().fromJson(json['u1IsDisposable']),
  isSellable: const BoolIntConverter().fromJson(json['u1IsSellable']),
  rank: (json['u5Rank'] as num?)?.toInt() ?? 0,
  genre: (json['u6Genre'] as num?)?.toInt() ?? 0,
  isIgnoreGenre: const BoolIntConverter().fromJson(json['u1IsIgnoreGenre']),
  sortAllByKCategory: (json['u16SortAllByKCategory'] as num?)?.toInt() ?? 0,
  sortCategoryByCategory:
      (json['u16SortCategoryByCategory'] as num?)?.toInt() ?? 0,
  experience: (json['u16Experience'] as num?)?.toInt() ?? 0,
  multiplier: (json['i8Mulitplier'] as num?)?.toInt() ?? 0,
  isUseItemChange: const BoolIntConverter().fromJson(json['u1IsUseItemChange']),
);

Map<String, dynamic> _$ItemToJson(Item instance) => <String, dynamic>{
  'sItemNameStringId': instance.itemNameStringId,
  'sHelpStringId': instance.helpStringId,
  'sScriptId': instance.scriptId,
  'uPurchasePrice': instance.purchasePrice,
  'uSellPrice': instance.sellPrice,
  'u8MenuIcon': instance.menuIcon,
  'u8ItemCategory': instance.itemCategory,
  'i16ScriptArg0': instance.scriptArg0,
  'i16ScriptArg1': instance.scriptArg1,
  'u1IsUseBattleMenu': const BoolIntConverter().toJson(
    instance.isUseBattleMenu,
  ),
  'u1IsUseMenu': const BoolIntConverter().toJson(instance.isUseMenu),
  'u1IsDisposable': const BoolIntConverter().toJson(instance.isDisposable),
  'u1IsSellable': const BoolIntConverter().toJson(instance.isSellable),
  'u5Rank': instance.rank,
  'u6Genre': instance.genre,
  'u1IsIgnoreGenre': const BoolIntConverter().toJson(instance.isIgnoreGenre),
  'u16SortAllByKCategory': instance.sortAllByKCategory,
  'u16SortCategoryByCategory': instance.sortCategoryByCategory,
  'u16Experience': instance.experience,
  'i8Mulitplier': instance.multiplier,
  'u1IsUseItemChange': const BoolIntConverter().toJson(
    instance.isUseItemChange,
  ),
};
