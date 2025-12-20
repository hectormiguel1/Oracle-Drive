import 'package:oracle_drive/components/game_selector.dart';
import 'package:oracle_drive/components/widgets/crystal_background.dart';
import 'package:oracle_drive/components/widgets/crystal_button.dart';
import 'package:oracle_drive/components/widgets/crystal_console.dart';
import 'package:oracle_drive/components/widgets/crystal_dropdowns.dart';
import 'package:oracle_drive/components/widgets/crystal_icon_button.dart';
import 'package:oracle_drive/components/widgets/crystal_panel.dart';
import 'package:oracle_drive/models/app_game_code.dart';
import 'package:oracle_drive/providers/app_state_provider.dart';
import 'package:oracle_drive/screens/crystalium_screen.dart';
import 'package:oracle_drive/screens/wbt_screen.dart';
import 'package:oracle_drive/screens/wdb_screen.dart';
import 'package:oracle_drive/screens/wpd_screen.dart';
import 'package:oracle_drive/screens/ztr_screen.dart';
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
      ZtrScreen(selectedGame: selectedGame),
      if (selectedGame == AppGameCode.ff13_1) const CrystaliumScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final selectedGame = ref.watch(selectedGameProvider);
    final selectedIndex = ref.watch(navigationIndexProvider);

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
                          color: Theme.of(
                            context,
                          ).extension<CrystalTheme>()!.accent,
                          size: 32,
                        ),
                        const SizedBox(height: 20),
                        _buildGameDropdown(selectedGame),
                        const SizedBox(height: 150),
                        _buildNavButton(0, "Archives", Icons.archive),
                        const SizedBox(height: 10),
                        _buildNavButton(1, "WPD", Icons.folder_zip),
                        const SizedBox(height: 10),
                        _buildNavButton(2, "WDB", Icons.table_chart),
                        const SizedBox(height: 10),
                        _buildNavButton(3, "ZTR", Icons.description),
                        if (selectedGame == AppGameCode.ff13_1) ...[
                          const SizedBox(height: 10),
                          _buildNavButton(4, "Crystalium", Icons.auto_graph),
                        ],
                      ],
                    ),
                  ),
                ),
                const VerticalDivider(
                  thickness: 1,
                  width: 1,
                  color: Colors.white10,
                ),
                Expanded(
                  child: GameSelector(
                    selectedGame: selectedGame,
                    onGameChanged: (g) {
                      ref.read(selectedGameProvider.notifier).state = g;
                      // Reset navigation index if it's out of bounds for the new game
                      final currentIdx = ref.read(navigationIndexProvider);
                      if (g != AppGameCode.ff13_1 && currentIdx == 4) {
                        ref.read(navigationIndexProvider.notifier).state = 0;
                      }
                    },
                    child: IndexedStack(
                      index: selectedIndex,
                      children: _buildScreens(selectedGame),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Console Toggle
          AnimatedBuilder(
            animation: _paddingAnimation,
            builder: (context, child) {
              return Positioned(
                right: 20,
                bottom: 20 + _paddingAnimation.value,
                child: child!,
              );
            },
            child: CrystalIconButton(
              onPressed: _toggleConsole,
              icon: _isConsoleOpen
                  ? Icons.terminal_rounded
                  : Icons.terminal_outlined,
              tooltip: _isConsoleOpen ? "Close Console" : "Open Console",
              isSelected: _isConsoleOpen,
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
    final selectedIndex = ref.watch(navigationIndexProvider);
    final isSelected = selectedIndex == index;
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
