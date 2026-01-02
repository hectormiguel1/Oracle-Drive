import 'package:flutter/material.dart';
import '../../components/widgets/crystal_panel.dart';
import '../../components/widgets/style.dart';

/// A shared toolbar component for overlay screens.
///
/// Provides a consistent header with back button and title for
/// screens that are pushed on top of the fullscreen workflow.
class OverlayToolbar extends StatelessWidget {
  /// The title displayed in the toolbar.
  final String title;

  /// Optional subtitle displayed below the title.
  final String? subtitle;

  /// Icon displayed before the title.
  final IconData? icon;

  /// Callback when the back button is pressed.
  final VoidCallback onBack;

  /// Additional actions to display on the right side.
  final List<Widget>? actions;

  const OverlayToolbar({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.onBack,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return CrystalPanel(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: 0,
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white70),
            onPressed: onBack,
            tooltip: 'Back to Workflow',
          ),
          const SizedBox(width: 8),
          // Icon (if provided)
          if (icon != null) ...[
            Icon(icon, color: Colors.cyan, size: 20),
            const SizedBox(width: 8),
          ],
          // Title and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: CrystalStyles.sectionHeader,
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          // Actions
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}
