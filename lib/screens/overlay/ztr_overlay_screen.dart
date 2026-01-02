import 'package:flutter/material.dart';
import '../../components/widgets/crystal_background.dart';
import '../../components/widgets/crystal_panel.dart';
import '../ztr_screen.dart';
import 'overlay_toolbar.dart';

/// Overlay screen for accessing the ZTR (String) editor
/// from fullscreen workflow mode.
class ZtrOverlayScreen extends StatelessWidget {
  const ZtrOverlayScreen({super.key});

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
                  title: 'String Editor',
                  subtitle: 'View and edit ZTR string files',
                  icon: Icons.description,
                  onBack: () => Navigator.of(context).pop(),
                ),
                const Expanded(
                  child: CrystalPanel(
                    child: ZtrScreen(),
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
