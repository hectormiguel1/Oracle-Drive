import 'dart:io';

import 'package:ffigen/ffigen.dart';
import 'package:logging/logging.dart';

final _ignoreCommonStructs = ['^Result\$', '^Error\$'];
final _ignoreCommonUnions = ['^ResultUnion\$'];
final _ignoreCommonEnums = ['^Type\$', '^LogLevel\$'];
final _ignoreCommonTypedefs = ['^LogCallback\$'];

bool Function(dynamic) _makeIncluder(List<String> exclusions) {
  return (decl) {
    for (final pattern in exclusions) {
      if (RegExp(pattern).hasMatch(decl.originalName)) {
        return false;
      }
    }
    return true;
  };
}

final commonImport = LibraryImport(
  "common",
  "package:oracle_drive/src/third_party/common.g.dart",
);
final commonImportedTypes = [
  ImportedType(commonImport, "Result", "Result", "Result"),
  ImportedType(commonImport, "Error", "Error", "Error"),
  ImportedType(commonImport, "ResultUnion", "ResultUnion", "ResultUnion"),
  ImportedType(commonImport, "LogCallback", "LogCallback", "LogCallback"),
];

void main() {
  final packageRoot = Platform.script.resolve('../');
  final logger = Logger('FFIGen')
    ..onRecord.listen((record) => print(record.message));

  final commonGenerator = getCommonGenerator(packageRoot);
  final wbtGenerator = getWhiteBinToolsGenerator(packageRoot);
  final wpdGenerator = getWpdGenerator(packageRoot);
  final wdbGenerator = getWdbGenerator(packageRoot);
  final ztrGenerator = getZtrGenerator(packageRoot);

  commonGenerator.generate(logger: logger);
  wbtGenerator.generate(logger: logger);
  wpdGenerator.generate(logger: logger);
  wdbGenerator.generate(logger: logger);
  ztrGenerator.generate(logger: logger);
}

FfiGenerator getCommonGenerator(Uri packageRoot) {
  return FfiGenerator(
    headers: Headers(
      entryPoints: [packageRoot.resolve('third_party/common.h')],
    ),

    functions: Functions(include: (d) => false),
    structs: Structs.includeAll,
    enums: Enums.includeAll,
    typedefs: Typedefs.includeAll,
    output: Output(
      dartFile: packageRoot.resolve('lib/src/third_party/common.g.dart'),
    ),
  );
}

FfiGenerator getWdbGenerator(Uri packageRoot) {
  return FfiGenerator(
    headers: Headers(
      entryPoints: [packageRoot.resolve('third_party/wdblib/wdb_api.h')],
    ),

    functions: Functions.includeAll,
    structs: Structs(include: _makeIncluder(_ignoreCommonStructs)),
    unions: Unions(include: _makeIncluder(_ignoreCommonUnions)),
    enums: Enums(include: _makeIncluder(_ignoreCommonEnums)),
    typedefs: Typedefs(
      include: _makeIncluder(_ignoreCommonTypedefs),
      imported: commonImportedTypes,
    ),
    output: Output(
      dartFile: packageRoot.resolve('lib/src/third_party/wdb/wdb.g.dart'),
    ),
  );
}

FfiGenerator getWpdGenerator(Uri packageRoot) {
  return FfiGenerator(
    headers: Headers(
      entryPoints: [packageRoot.resolve('third_party/wpdlib/wpd_lib.h')],
    ),
    functions: Functions.includeAll,
    structs: Structs(include: _makeIncluder(_ignoreCommonStructs)),
    unions: Unions(include: _makeIncluder(_ignoreCommonUnions)),
    enums: Enums(include: _makeIncluder(_ignoreCommonEnums)),
    typedefs: Typedefs(
      include: _makeIncluder(_ignoreCommonTypedefs),
      imported: commonImportedTypes,
    ),
    output: Output(
      dartFile: packageRoot.resolve('lib/src/third_party/wpdlib/wpd.g.dart'),
    ),
  );
}

FfiGenerator getZtrGenerator(Uri packageRoot) {
  return FfiGenerator(
    headers: Headers(
      entryPoints: [packageRoot.resolve('third_party/ztrlib/ztrlib.h')],
    ),
    functions: Functions.includeAll,
    structs: Structs(include: _makeIncluder(_ignoreCommonStructs)),
    unions: Unions(include: _makeIncluder(_ignoreCommonUnions)),
    enums: Enums(include: _makeIncluder(_ignoreCommonEnums)),
    typedefs: Typedefs(
      include: _makeIncluder(_ignoreCommonTypedefs),
      imported: commonImportedTypes,
    ),
    output: Output(
      dartFile: packageRoot.resolve('lib/src/third_party/ztrlib/ztr.g.dart'),
    ),
  );
}

FfiGenerator getWhiteBinToolsGenerator(Uri packageRoot) {
  return FfiGenerator(
    headers: Headers(
      entryPoints: [packageRoot.resolve('third_party/wbtlib/wbt_lib.h')],
    ),
    functions: Functions.includeAll,
    structs: Structs(include: _makeIncluder(_ignoreCommonStructs)),
    unions: Unions(include: _makeIncluder(_ignoreCommonUnions)),
    enums: Enums(include: _makeIncluder(_ignoreCommonEnums)),
    typedefs: Typedefs(
      include: _makeIncluder(_ignoreCommonTypedefs),
      imported: [
        ImportedType(LibraryImport("ffi", "dart"), "Bool", "bool", "WBT_BOOL"),
        ...commonImportedTypes,
      ],
    ),

    output: Output(
      dartFile: packageRoot.resolve('lib/src/third_party/wbtlib/wbt.g.dart'),
    ),
  );
}
