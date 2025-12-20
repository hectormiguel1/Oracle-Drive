import 'package:oracle_drive/models/wdb_entities/wdb_entity.dart';
import 'package:isar_plus/isar_plus.dart';

class IsarUpsertSpec<T> {
  final IsarCollection<int, T> Function(Isar) getCollection;
  final T Function(String, WdbEntity) map;

  const IsarUpsertSpec({required this.getCollection, required this.map});

  void upsertEntities(Isar isar, Map<String, WdbEntity> entities) async {
    final records = await Future.microtask(() {
      return entities.entries
          .map((entry) => map(entry.key, entry.value))
          .toList();
    });
    isar.write((isar) {
      final collection = getCollection(isar);
      collection.putAll(records);
    });
  }
}
