import 'package:hooks/hooks.dart';
import 'package:native_toolchain_rust/native_toolchain_rust.dart';

void main(List<String> args) async {
  await build(args, (config, output) async {
    await RustBuilder(
      cratePath: './',
      assetName: 'package:fabula_nova_sdk/bridge_generated/frb_generated.dart',
      buildMode: BuildMode.release,
    ).run(
      input: config,
      output: output,
    );
  });
}
