import 'package:oracle_drive/providers/app_state_provider.dart';
import 'package:oracle_drive/screens/main_screen.dart';
import 'package:oracle_drive/src/services/app_database.dart';
import 'package:oracle_drive/src/services/native_service.dart';
import 'package:oracle_drive/src/services/navigation_service.dart';
import 'package:oracle_drive/theme/crystal_theme.dart';
import 'package:oracle_drive/components/widgets/style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fabula_nova_sdk/bridge_generated/frb_generated.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'dart:io';

/// Track if RustLib has been initialized (survives hot restart)
bool _rustLibInitialized = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDatabase.ensureInitialized();

  // Reset NativeService for hot reload/restart support in debug mode
  if (kDebugMode) {
    await NativeService.reset();
  }

  // Only initialize RustLib once - it persists across hot restarts
  if (!_rustLibInitialized) {
    // Robust loading for development
    ExternalLibrary? externalLibrary;
    if (kDebugMode) {
      // Determine the correct library extension for the current platform
      final libraryExtension = switch (Platform.operatingSystem) {
        'windows' => 'fabula_nova_sdk.dll',
        'macos' => 'libfabula_nova_sdk.dylib',
        'linux' => 'libfabula_nova_sdk.so',
        _ => throw UnsupportedError(
          'Unsupported platform: ${Platform.operatingSystem}',
        ),
      };

      // Try to find the library in the project structure
      final possiblePaths = [
        '${Directory.current.path}/rust/fabula_nova_sdk/target/release/$libraryExtension',
      ];

      for (final path in possiblePaths) {
        if (File(path).existsSync()) {
          // ignore: avoid_print
          print('Found native library at: $path');
          externalLibrary = ExternalLibrary.open(path);
          break;
        }
      }

      if (externalLibrary == null) {
        // ignore: avoid_print
        print('Warning: Could not find native library in development paths.');
        // ignore: avoid_print
        print('Current directory: ${Directory.current.path}');
      }
    }

    try {
      await RustLib.init(externalLibrary: externalLibrary);
      _rustLibInitialized = true;
    } catch (e) {
      // RustLib might already be initialized from a previous hot restart
      // Check if it's actually initialized before marking as done
      if (e.toString().contains('already been initialized')) {
        _rustLibInitialized = true;
      } else {
        // ignore: avoid_print
        print('Error initializing RustLib: $e');
        rethrow;
      }
    }
  }
  await NativeService.instance.initialize();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedGame = ref.watch(selectedGameProvider);
    final crystalTheme = CrystalTheme.fromGame(selectedGame);

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Oracle Drive',
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: crystalTheme.accent,
          brightness: Brightness.light,
          surface: const Color(0xFF1E1E1E).withValues(alpha: 0.05),
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.rajdhaniTextTheme(ThemeData.light().textTheme),
        tooltipTheme: TooltipThemeData(
          decoration: BoxDecoration(
            color: CrystalColors.panelBackground.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: crystalTheme.accent.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 12,
              ),
              BoxShadow(
                color: crystalTheme.accent.withValues(alpha: 0.1),
                blurRadius: 8,
              ),
            ],
          ),
          textStyle: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w400,
            shadows: [
              Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 2),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          waitDuration: const Duration(milliseconds: 500),
        ),
        extensions: [crystalTheme],
      ),
      home: const MainScreen(),
    );
  }
}
