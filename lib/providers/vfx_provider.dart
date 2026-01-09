import 'package:fabula_nova_sdk/bridge_generated/modules/vfx/structs.dart'
    as vfx_sdk;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:oracle_drive/src/services/formats/vfx_service.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

final _logger = Logger('VfxProvider');

// ============================================================
// VFX State
// ============================================================

/// Current VFX file path being viewed.
final vfxPathProvider = StateProvider<String?>((ref) => null);

/// Whether VFX is currently loading.
final vfxIsLoadingProvider = StateProvider<bool>((ref) => false);

/// Loaded VFX data.
final vfxDataProvider = StateProvider<vfx_sdk.VfxData?>((ref) => null);

/// Error message if loading failed.
final vfxErrorProvider = StateProvider<String?>((ref) => null);

/// Selected tab index (0=Textures, 1=Models, 2=Animations, 3=Effects).
final vfxSelectedTabProvider = StateProvider<int>((ref) => 0);

/// Selected item index within the current tab.
final vfxSelectedItemProvider = StateProvider<int?>((ref) => null);

// ============================================================
// VFX Notifier
// ============================================================

final vfxNotifierProvider = Provider<VfxNotifier>((ref) => VfxNotifier(ref));

class VfxNotifier {
  final Ref _ref;

  VfxNotifier(this._ref);

  String? get path => _ref.read(vfxPathProvider);
  bool get isLoading => _ref.read(vfxIsLoadingProvider);
  vfx_sdk.VfxData? get data => _ref.read(vfxDataProvider);
  String? get error => _ref.read(vfxErrorProvider);
  int get selectedTab => _ref.read(vfxSelectedTabProvider);
  int? get selectedItem => _ref.read(vfxSelectedItemProvider);

  /// Load a VFX file from the given path.
  Future<void> loadVfx(String filePath) async {
    _ref.read(vfxIsLoadingProvider.notifier).state = true;
    _ref.read(vfxErrorProvider.notifier).state = null;
    _ref.read(vfxDataProvider.notifier).state = null;
    _ref.read(vfxPathProvider.notifier).state = filePath;
    _ref.read(vfxSelectedItemProvider.notifier).state = null;

    try {
      _logger.info("Loading VFX: $filePath");
      final data = await VfxService.instance.parse(filePath);
      _ref.read(vfxDataProvider.notifier).state = data;
      _logger.info(
        "VFX loaded: ${data.textures.length} textures, "
        "${data.models.length} models, "
        "${data.animations.length} animations, "
        "${data.effects.length} effects",
      );
    } catch (e, stack) {
      _logger.severe("Error loading VFX: $e\n$stack");
      _ref.read(vfxErrorProvider.notifier).state = e.toString();
    } finally {
      _ref.read(vfxIsLoadingProvider.notifier).state = false;
    }
  }

  /// Get a quick summary of a VFX file.
  Future<vfx_sdk.VfxSummary?> getSummary(String filePath) async {
    try {
      return await VfxService.instance.getSummary(filePath);
    } catch (e) {
      _logger.severe("Error getting VFX summary: $e");
      return null;
    }
  }

  /// Export VFX data to JSON.
  Future<String?> exportToJson(String filePath) async {
    try {
      return await VfxService.instance.exportJson(filePath);
    } catch (e) {
      _logger.severe("Error exporting VFX to JSON: $e");
      return null;
    }
  }

  /// Extract textures from VFX to DDS files.
  Future<List<String>> extractTextures(String xfvPath, String outputDir) async {
    try {
      _logger.info("Extracting VFX textures to: $outputDir");
      final paths = await VfxService.instance.extractTextures(
        xfvPath,
        outputDir,
      );
      _logger.info("Extracted ${paths.length} textures");
      return paths;
    } catch (e) {
      _logger.severe("Error extracting VFX textures: $e");
      return [];
    }
  }

  /// Set the selected tab.
  void setSelectedTab(int index) {
    _ref.read(vfxSelectedTabProvider.notifier).state = index;
    _ref.read(vfxSelectedItemProvider.notifier).state = null;
  }

  /// Set the selected item within current tab.
  void setSelectedItem(int? index) {
    _ref.read(vfxSelectedItemProvider.notifier).state = index;
  }

  /// Clear the current VFX data.
  void clear() {
    _ref.read(vfxPathProvider.notifier).state = null;
    _ref.read(vfxDataProvider.notifier).state = null;
    _ref.read(vfxErrorProvider.notifier).state = null;
    _ref.read(vfxSelectedTabProvider.notifier).state = 0;
    _ref.read(vfxSelectedItemProvider.notifier).state = null;
  }
}

// ============================================================
// Derived Providers
// ============================================================

/// Display name of the current VFX file.
final vfxDisplayNameProvider = Provider<String>((ref) {
  final path = ref.watch(vfxPathProvider);
  if (path == null) return 'No VFX loaded';
  return p.basename(path);
});

/// Texture count in loaded VFX.
final vfxTextureCountProvider = Provider<int>((ref) {
  final data = ref.watch(vfxDataProvider);
  return data?.textures.length ?? 0;
});

/// Model count in loaded VFX.
final vfxModelCountProvider = Provider<int>((ref) {
  final data = ref.watch(vfxDataProvider);
  return data?.models.length ?? 0;
});

/// Animation count in loaded VFX.
final vfxAnimationCountProvider = Provider<int>((ref) {
  final data = ref.watch(vfxDataProvider);
  return data?.animations.length ?? 0;
});

/// Effect count in loaded VFX.
final vfxEffectCountProvider = Provider<int>((ref) {
  final data = ref.watch(vfxDataProvider);
  return data?.effects.length ?? 0;
});

/// Currently selected texture (if on texture tab and item selected).
final vfxSelectedTextureProvider = Provider<vfx_sdk.VfxTexture?>((ref) {
  final data = ref.watch(vfxDataProvider);
  final tab = ref.watch(vfxSelectedTabProvider);
  final index = ref.watch(vfxSelectedItemProvider);
  if (data == null || tab != 0 || index == null) return null;
  if (index < 0 || index >= data.textures.length) return null;
  return data.textures[index];
});

/// Currently selected model (if on model tab and item selected).
final vfxSelectedModelProvider = Provider<vfx_sdk.VfxModel?>((ref) {
  final data = ref.watch(vfxDataProvider);
  final tab = ref.watch(vfxSelectedTabProvider);
  final index = ref.watch(vfxSelectedItemProvider);
  if (data == null || tab != 1 || index == null) return null;
  if (index < 0 || index >= data.models.length) return null;
  return data.models[index];
});

/// Currently selected animation (if on animation tab and item selected).
final vfxSelectedAnimationProvider = Provider<vfx_sdk.VfxAnimation?>((ref) {
  final data = ref.watch(vfxDataProvider);
  final tab = ref.watch(vfxSelectedTabProvider);
  final index = ref.watch(vfxSelectedItemProvider);
  if (data == null || tab != 2 || index == null) return null;
  if (index < 0 || index >= data.animations.length) return null;
  return data.animations[index];
});

/// Currently selected effect (if on effect tab and item selected).
final vfxSelectedEffectProvider = Provider<vfx_sdk.VfxEffect?>((ref) {
  final data = ref.watch(vfxDataProvider);
  final tab = ref.watch(vfxSelectedTabProvider);
  final index = ref.watch(vfxSelectedItemProvider);
  if (data == null || tab != 3 || index == null) return null;
  if (index < 0 || index >= data.effects.length) return null;
  return data.effects[index];
});
