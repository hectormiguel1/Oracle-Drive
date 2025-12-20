import 'package:ff13_mod_resource/src/isar/common/models.dart' show fastHash;
import 'package:isar_plus/isar_plus.dart';
import 'package:ff13_mod_resource/models/wdb_entities/xiii/shop.dart'
    as wdb_entity;

part 'shop.g.dart';

@Collection()
class ShopTable {
  @Index()
  String record; // Primary key from WDB
  String flagItemId;
  String shopNameLabel;
  List<String>
  itemLabels; // Consolidating itemLabel1 to itemLabel32 into a List

  ShopTable({
    required this.record,
    required this.flagItemId,
    required this.shopNameLabel,
    required this.itemLabels,
  });

  int get id => fastHash(record);

  factory ShopTable.fromWdbEntity(String record, wdb_entity.Shop wdbShop) {
    final itemLabels = <String>[];
    if (wdbShop.itemLabel1.isNotEmpty) itemLabels.add(wdbShop.itemLabel1);
    if (wdbShop.itemLabel2.isNotEmpty) itemLabels.add(wdbShop.itemLabel2);
    if (wdbShop.itemLabel3.isNotEmpty) itemLabels.add(wdbShop.itemLabel3);
    if (wdbShop.itemLabel4.isNotEmpty) itemLabels.add(wdbShop.itemLabel4);
    if (wdbShop.itemLabel5.isNotEmpty) itemLabels.add(wdbShop.itemLabel5);
    if (wdbShop.itemLabel6.isNotEmpty) itemLabels.add(wdbShop.itemLabel6);
    if (wdbShop.itemLabel7.isNotEmpty) itemLabels.add(wdbShop.itemLabel7);
    if (wdbShop.itemLabel8.isNotEmpty) itemLabels.add(wdbShop.itemLabel8);
    if (wdbShop.itemLabel9.isNotEmpty) itemLabels.add(wdbShop.itemLabel9);
    if (wdbShop.itemLabel10.isNotEmpty) itemLabels.add(wdbShop.itemLabel10);
    if (wdbShop.itemLabel11.isNotEmpty) itemLabels.add(wdbShop.itemLabel11);
    if (wdbShop.itemLabel12.isNotEmpty) itemLabels.add(wdbShop.itemLabel12);
    if (wdbShop.itemLabel13.isNotEmpty) itemLabels.add(wdbShop.itemLabel13);
    if (wdbShop.itemLabel14.isNotEmpty) itemLabels.add(wdbShop.itemLabel14);
    if (wdbShop.itemLabel15.isNotEmpty) itemLabels.add(wdbShop.itemLabel15);
    if (wdbShop.itemLabel16.isNotEmpty) itemLabels.add(wdbShop.itemLabel16);
    if (wdbShop.itemLabel17.isNotEmpty) itemLabels.add(wdbShop.itemLabel17);
    if (wdbShop.itemLabel18.isNotEmpty) itemLabels.add(wdbShop.itemLabel18);
    if (wdbShop.itemLabel19.isNotEmpty) itemLabels.add(wdbShop.itemLabel19);
    if (wdbShop.itemLabel20.isNotEmpty) itemLabels.add(wdbShop.itemLabel20);
    if (wdbShop.itemLabel21.isNotEmpty) itemLabels.add(wdbShop.itemLabel21);
    if (wdbShop.itemLabel22.isNotEmpty) itemLabels.add(wdbShop.itemLabel22);
    if (wdbShop.itemLabel23.isNotEmpty) itemLabels.add(wdbShop.itemLabel23);
    if (wdbShop.itemLabel24.isNotEmpty) itemLabels.add(wdbShop.itemLabel24);
    if (wdbShop.itemLabel25.isNotEmpty) itemLabels.add(wdbShop.itemLabel25);
    if (wdbShop.itemLabel26.isNotEmpty) itemLabels.add(wdbShop.itemLabel26);
    if (wdbShop.itemLabel27.isNotEmpty) itemLabels.add(wdbShop.itemLabel27);
    if (wdbShop.itemLabel28.isNotEmpty) itemLabels.add(wdbShop.itemLabel28);
    if (wdbShop.itemLabel29.isNotEmpty) itemLabels.add(wdbShop.itemLabel29);
    if (wdbShop.itemLabel30.isNotEmpty) itemLabels.add(wdbShop.itemLabel30);
    if (wdbShop.itemLabel31.isNotEmpty) itemLabels.add(wdbShop.itemLabel31);
    if (wdbShop.itemLabel32.isNotEmpty) itemLabels.add(wdbShop.itemLabel32);

    return ShopTable(
      record: record,
      flagItemId: wdbShop.flagItemId,
      shopNameLabel: wdbShop.shopNameLabel,
      itemLabels: itemLabels,
    );
  }
}
