import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oracle_drive/components/widgets/crystal_button.dart';
import 'package:oracle_drive/providers/crystalium_provider.dart';
import 'package:oracle_drive/theme/crystal_theme.dart';

/// Header toolbar for the Crystalium screen.
class CrystaliumHeader extends ConsumerWidget {
  final VoidCallback onLoadFile;
  final VoidCallback onSaveFile;
  final VoidCallback onAddOffshoot;
  final VoidCallback onResetCamera;

  const CrystaliumHeader({
    super.key,
    required this.onLoadFile,
    required this.onSaveFile,
    required this.onAddOffshoot,
    required this.onResetCamera,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(crystaliumProvider);
    final theme = Theme.of(context).extension<CrystalTheme>()!;

    return Row(
      children: [
        CrystalButton(
          label: "Load File",
          icon: Icons.file_open,
          onPressed: onLoadFile,
        ),
        if (state.viewMode == CrystaliumViewMode.cgt && state.cgtFile != null) ...[
          const SizedBox(width: 8),
          CrystalButton(
            label: state.hasUnsavedChanges ? "Save*" : "Save",
            icon: Icons.save,
            onPressed: onSaveFile,
          ),
          const SizedBox(width: 8),
          CrystalButton(
            label: "Add Offshoot",
            icon: Icons.add_circle_outline,
            onPressed: onAddOffshoot,
          ),
        ],
        const SizedBox(width: 16),
        CrystalButton(
          label: "Reset Cam",
          icon: Icons.center_focus_strong,
          onPressed: onResetCamera,
        ),
        const SizedBox(width: 24),
        _ModeToggle(theme: theme),
        if (state.viewMode == CrystaliumViewMode.mcp && state.mcpFile != null) ...[
          const SizedBox(width: 24),
          _InfoLabel(label: "MCP Patterns", value: state.mcpFile!.patternCount.toString(), theme: theme),
        ],
        if (state.viewMode == CrystaliumViewMode.cgt && state.cgtFile != null) ...[
          const SizedBox(width: 24),
          _InfoLabel(label: "CGT Entries", value: state.cgtFile!.entryCount.toString(), theme: theme),
          const SizedBox(width: 24),
          _InfoLabel(label: "CGT Nodes", value: state.cgtFile!.totalNodes.toString(), theme: theme),
          if (state.hasUnsavedChanges) ...[
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Modified',
                style: TextStyle(color: Colors.orange, fontSize: 12),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _ModeToggle extends ConsumerWidget {
  final CrystalTheme theme;

  const _ModeToggle({required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(crystaliumProvider.select((s) => s.viewMode));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _ModeButton(
            mode: CrystaliumViewMode.mcp,
            label: "MCP",
            isSelected: viewMode == CrystaliumViewMode.mcp,
            theme: theme,
          ),
          _ModeButton(
            mode: CrystaliumViewMode.cgt,
            label: "CGT",
            isSelected: viewMode == CrystaliumViewMode.cgt,
            theme: theme,
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends ConsumerWidget {
  final CrystaliumViewMode mode;
  final String label;
  final bool isSelected;
  final CrystalTheme theme;

  const _ModeButton({
    required this.mode,
    required this.label,
    required this.isSelected,
    required this.theme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => ref.read(crystaliumProvider.notifier).setViewMode(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.accent.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? theme.accent : Colors.white54,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _InfoLabel extends StatelessWidget {
  final String label;
  final String value;
  final CrystalTheme theme;

  const _InfoLabel({
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.accent,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16)),
      ],
    );
  }
}
