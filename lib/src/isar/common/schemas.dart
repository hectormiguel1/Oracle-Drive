import 'package:oracle_drive/src/isar/common/models.dart';
import 'package:isar_plus/isar_plus.dart';

final List<IsarGeneratedSchema> schemas = [
  StringsSchema,
  EntityLookupSchema,
];

final Map<String, IsarGeneratedSchema> schemaByName = {
  'Strings': StringsSchema,
  'EntityLookup': EntityLookupSchema,
};
