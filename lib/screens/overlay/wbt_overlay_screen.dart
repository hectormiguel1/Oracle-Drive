import 'package:flutter/material.dart';
import '../../components/widgets/crystal_background.dart';
import '../../components/widgets/crystal_panel.dart';
import '../wbt_screen.dart';
import 'overlay_toolbar.dart';

/// Overlay screen for accessing the WBT (Archives) editor
/// from fullscreen workflow mode.
class WbtOverlayScreen extends StatelessWidget {
  const WbtOverlayScreen({super.key});

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
                  title: 'Archive Explorer',
                  subtitle: 'Browse and extract WBT archives',
                  icon: Icons.archive,
                  onBack: () => Navigator.of(context).pop(),
                ),
                const Expanded(
                  child: CrystalPanel(
                    child: WhiteBinToolsScreen(),
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
