import 'package:oracle_drive/components/game_selector.dart';
import 'package:oracle_drive/components/widgets/crystal_background.dart';
import 'package:oracle_drive/components/widgets/crystal_button.dart';
import 'package:oracle_drive/components/widgets/crystal_console.dart';
import 'package:oracle_drive/components/widgets/crystal_divider.dart';
import 'package:oracle_drive/components/widgets/crystal_dropdowns.dart';
import 'package:oracle_drive/components/widgets/crystal_panel.dart';
import 'package:oracle_drive/models/app_game_code.dart';
import 'package:oracle_drive/providers/app_state_provider.dart';
import 'package:oracle_drive/screens/crystalium_screen.dart';
import 'package:oracle_drive/screens/wbt_screen.dart';
import 'package:oracle_drive/screens/wdb_screen.dart';
import 'package:oracle_drive/screens/workflow_screen.dart';
import 'package:oracle_drive/screens/wpd_screen.dart';
import 'package:oracle_drive/screens/ztr_screen.dart';
import 'package:oracle_drive/screens/vfx_screen.dart';
import 'package:oracle_drive/screens/event_screen.dart';
import 'package:oracle_drive/screens/settings_screen.dart';
import 'package:oracle_drive/theme/crystal_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen>
    with SingleTickerProviderStateMixin {
  bool _isConsoleOpen = false;
  late AnimationController _consoleController;
  late Animation<Offset> _consoleAnimation;
  late Animation<double> _paddingAnimation;

  @override
  void initState() {
    super.initState();
    _consoleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    final curve = CurvedAnimation(
      parent: _consoleController,
      curve: Curves.easeOutCubic,
    );
    _consoleAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(curve);
    _paddingAnimation = Tween<double>(begin: 0.0, end: 300.0).animate(curve);
  }

  @override
  void dispose() {
    _consoleController.dispose();
    super.dispose();
  }

  void _toggleConsole() {
    setState(() {
      _isConsoleOpen = !_isConsoleOpen;
      if (_isConsoleOpen) {
        _consoleController.forward();
      } else {
        _consoleController.reverse();
      }
    });
  }

  List<Widget> _buildScreens(AppGameCode selectedGame) {
    return [
      const WhiteBinToolsScreen(),
      const WpdScreen(),
      const WdbScreen(),
      const ZtrScreen(),
      const WorkflowScreen(),
      const VfxScreen(),
      const EventScreen(),
      if (selectedGame == AppGameCode.ff13_1) const CrystaliumScreen(),
      const SettingsScreen(),
    ];
  }

  /// Get the settings screen index based on game selection.
  int _settingsIndex(AppGameCode game) {
    return game == AppGameCode.ff13_1 ? 8 : 7;
  }

  @override
  Widget build(BuildContext context) {
    // Cache theme extension to avoid repeated lookups
    final theme = Theme.of(context).extension<CrystalTheme>()!;
    final selectedGame = ref.watch(selectedGameProvider);
    final selectedIndex = ref.watch(navigationIndexProvider);
    final screens = _buildScreens(selectedGame);
    // Clamp index to valid range to prevent out-of-bounds during game transitions
    final safeIndex = selectedIndex.clamp(0, screens.length - 1);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const Positioned.fill(child: CrystalBackgroundGrid()),
          AnimatedBuilder(
            animation: _paddingAnimation,
            builder: (context, child) {
              return Padding(
                padding: EdgeInsets.only(bottom: _paddingAnimation.value),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: child,
                ),
              );
            },
            child: Row(
              children: [
                SizedBox(
                  width: 270,
                  child: CrystalPanel(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 10,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.diamond,
                          color: theme.accent,
                          size: 32,
                        ),
                        const SizedBox(height: 20),
                        _buildGameDropdown(selectedGame),
                        const SizedBox(height: 150),
                        _buildNavButton(0, "Archives", Icons.archive),
                        const SizedBox(height: 10),
                        _buildNavButton(1, "Workspace", Icons.folder_zip),
                        const SizedBox(height: 10),
                        _buildNavButton(2, "Database(s)", Icons.table_chart),
                        const SizedBox(height: 10),
                        _buildNavButton(3, "ZTR", Icons.description),
                        const SizedBox(height: 10),
                        _buildNavButton(4, "Workflows", Icons.account_tree),
                        const SizedBox(height: 10),
                        _buildNavButton(5, "VFX Viewer", Icons.auto_awesome),
                        const SizedBox(height: 10),
                        _buildNavButton(6, "Events", Icons.movie_outlined),
                        if (selectedGame == AppGameCode.ff13_1) ...[
                          const SizedBox(height: 10),
                          _buildNavButton(7, "Crystalium", Icons.auto_graph),
                        ],
                        const Spacer(),
                        const CrystalDivider.subtle(),
                        const SizedBox(height: 12),
                        _buildNavButton(
                          _settingsIndex(selectedGame),
                          "Settings",
                          Icons.settings,
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: CrystalButton(
                            label: _isConsoleOpen ? "Hide Console" : "Console",
                            icon: _isConsoleOpen
                                ? Icons.terminal_rounded
                                : Icons.terminal_outlined,
                            isPrimary: _isConsoleOpen,
                            onPressed: _toggleConsole,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const CrystalVerticalDivider.subtle(width: 1),
                Expanded(
                  child: GameSelector(
                    selectedGame: selectedGame,
                    onGameChanged: (g) {
                      final previousGame = ref.read(selectedGameProvider);
                      final currentIdx = ref.read(navigationIndexProvider);
                      final wasOnSettings = currentIdx == _settingsIndex(previousGame);

                      // Update navigation index BEFORE changing game to avoid out-of-bounds
                      if (wasOnSettings) {
                        // Stay on Settings when switching games
                        ref.read(navigationIndexProvider.notifier).state = _settingsIndex(g);
                      } else if (g != AppGameCode.ff13_1 && currentIdx == 7) {
                        // Crystalium (index 7) only exists for FF13 - go to first screen
                        ref.read(navigationIndexProvider.notifier).state = 0;
                      } else if (g != AppGameCode.ff13_1 && currentIdx > 7) {
                        // Index out of bounds for non-FF13 games - go to first screen
                        ref.read(navigationIndexProvider.notifier).state = 0;
                      }

                      ref.read(selectedGameProvider.notifier).state = g;
                    },
                    child: IndexedStack(
                      index: safeIndex,
                      children: screens,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Console Panel
          Align(
            alignment: Alignment.bottomCenter,
            child: SlideTransition(
              position: _consoleAnimation,
              child: SizedBox(
                height: 300,
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 270,
                  ), // Offset for Sidebar (250 + 20) ? No sidebar is 270.
                  child: CrystalConsole(onClose: _toggleConsole),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameDropdown(AppGameCode current) {
    return SizedBox(
      width: double.infinity,
      child: CrystalDropdown<AppGameCode>(
        value: current,
        items: AppGameCode.values,
        itemLabelBuilder: (g) => g.displayName,
        onChanged: (val) {
          ref.read(selectedGameProvider.notifier).state = val;
        },
      ),
    );
  }

  Widget _buildNavButton(int index, String label, IconData icon) {
    return _NavButton(index: index, label: label, icon: icon);
  }
}

/// Extracted navigation button widget for better performance.
/// Each button only rebuilds when its selection state changes.
class _NavButton extends ConsumerWidget {
  final int index;
  final String label;
  final IconData icon;

  const _NavButton({
    required this.index,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only watch if THIS button is selected, not the entire index
    final isSelected = ref.watch(
      navigationIndexProvider.select((idx) => idx == index),
    );

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(left: isSelected ? 16.0 : 0.0),
      child: SizedBox(
        width: double.infinity,
        child: CrystalButton(
          label: label,
          icon: icon,
          isPrimary: isSelected,
          onPressed: () =>
              ref.read(navigationIndexProvider.notifier).state = index,
        ),
      ),
    );
  }
}
