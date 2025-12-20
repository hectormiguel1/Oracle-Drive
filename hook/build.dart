import 'dart:io';
import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:logging/logging.dart';

Future<void> main(List<String> args) async {
  final logger = Logger('build.dart');

  await build(args, (input, output) async {
    if (input.config.buildCodeAssets) {
      // FIX: Use input.packageRoot to resolve the path reliably
      final wbtLibPath = input.packageRoot.resolve(
        'third_party/wbtlib/linux/WhiteBinTools.so',
      );
      final wpdLibPath = input.packageRoot.resolve(
        'third_party/wpdlib/linux/WPD.Lib.so',
      );
      final wdbLibPath = input.packageRoot.resolve(
        'third_party/wdblib/linux/WDBJsonTool.so',
      );

      final ztrLibPath = input.packageRoot.resolve(
        'third_party/ztrlib/linux/ZTRLib.so',
      );

      // Helper to add code asset with optional PDB
      void addAssetWithPdb(Uri libPath, String assetName) {
        output.assets.code.add(
          CodeAsset(
            package: 'ff13_mod_resource',
            name: assetName,
            linkMode: DynamicLoadingBundled(),
            file: libPath,
          ),
        );

        // Check for PDB and add if it exists
        final pdbPath = libPath.resolve(
          libPath.pathSegments.last.replaceAll('.so', '.pdb'),
        );
        final pdbFile = File.fromUri(pdbPath);
        if (pdbFile.existsSync()) {
          output.assets.code.add(
            CodeAsset(
              package: 'ff13_mod_resource',
              name: assetName.replaceAll('.g.dart', '.pdb'),
              linkMode: DynamicLoadingBundled(),
              file: pdbPath,
            ),
          );
          logger.info('Bundling PDB: $pdbPath');
        }
      }

      addAssetWithPdb(wbtLibPath, 'src/third_party/wbtlib/wbt.g.dart');
      addAssetWithPdb(wpdLibPath, 'src/third_party/wpdlib/wpd.g.dart');
      addAssetWithPdb(wdbLibPath, 'src/third_party/wdb/wdb.g.dart');
      addAssetWithPdb(ztrLibPath, 'src/third_party/ztrlib/ztr.g.dart');

      // Verify the file actually exists before adding it to avoid confusion
      // (Note: input.packageRoot returns a file:// URI)
      logger.info('Linking native asset from: $wbtLibPath');
    }
  });
}
