import 'package:flutter/material.dart';
import '../../components/widgets/crystal_background.dart';
import '../../components/widgets/crystal_panel.dart';
import '../wdb_screen.dart';
import 'overlay_toolbar.dart';

/// Overlay screen for accessing the WDB (Database) editor
/// from fullscreen workflow mode.
class WdbOverlayScreen extends StatelessWidget {
  const WdbOverlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const Positioned.fill(child: CrystalBackgroundGrid()),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                OverlayToolbar(
                  title: 'Database Editor',
                  subtitle: 'View and edit WDB files',
                  icon: Icons.table_chart,
                  onBack: () => Navigator.of(context).pop(),
                ),
                const Expanded(
                  child: CrystalPanel(
                    child: WdbScreen(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
