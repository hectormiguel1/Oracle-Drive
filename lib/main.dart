import 'package:ff13_mod_resource/providers/app_state_provider.dart';
import 'package:ff13_mod_resource/screens/main_screen.dart';
import 'package:ff13_mod_resource/src/services/app_database.dart';
import 'package:ff13_mod_resource/src/services/native_service.dart';
import 'package:ff13_mod_resource/src/services/navigation_service.dart';
import 'package:ff13_mod_resource/theme/crystal_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logging/logging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDatabase.ensureInitialized();

  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print(
      '${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}',
    );
  });

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
      title: 'Crystal Tools',
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: crystalTheme.accent,
          brightness: Brightness.light,
          surface: const Color(0xFF1E1E1E).withValues(alpha: 0.05),
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.rajdhaniTextTheme(ThemeData.light().textTheme),
        extensions: [crystalTheme],
      ),
      home: const MainScreen(),
    );
  }
}
