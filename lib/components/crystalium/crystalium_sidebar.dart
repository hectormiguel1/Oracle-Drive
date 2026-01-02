import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oracle_drive/components/widgets/crystal_panel.dart';
import 'package:oracle_drive/models/crystalium/cgt_file.dart';
import 'package:oracle_drive/providers/crystalium_provider.dart';
import 'package:oracle_drive/theme/crystal_theme.dart';

/// MCP pattern list sidebar.
class McpPatternList extends ConsumerWidget {
  const McpPatternList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(crystaliumProvider);
    final theme = Theme.of(context).extension<CrystalTheme>()!;

    if (state.mcpFile == null) return const SizedBox.shrink();

    return SizedBox(
      width: 280,
      child: CrystalPanel(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel(text: "AVAILABLE PATTERNS", theme: theme),
            Expanded(
              child: ListView.separated(
                itemCount: state.mcpFile!.patterns.length,
                separatorBuilder: (context, index) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final pattern = state.mcpFile!.patterns[index];
                  final isSelected = state.selectedPattern == pattern;
                  return ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    selected: isSelected,
                    selectedTileColor: theme.accent.withValues(alpha: 0.1),
                    title: Text(
                      pattern.name.isEmpty ? "Pattern $index" : pattern.name,
                      style: TextStyle(
                        color: isSelected ? theme.accent : Colors.white,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    onTap: () => ref.read(crystaliumProvider.notifier).selectPattern(pattern),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// CGT entry and node list sidebar.
class CgtEntrySidebar extends ConsumerWidget {
  const CgtEntrySidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(crystaliumProvider);
    final theme = Theme.of(context).extension<CrystalTheme>()!;

    if (state.cgtFile == null) return const SizedBox.shrink();

    return SizedBox(
      width: 300,
      child: CrystalPanel(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel(text: "ENTRIES (STAGES)", theme: theme),
            Expanded(child: _EntryList(theme: theme)),
            if (state.selectedEntry != null) ...[
              const Divider(color: Colors.white10, height: 24),
              _SectionLabel(text: "NODES IN ENTRY", theme: theme),
              Expanded(child: _NodeList(theme: theme)),
            ],
          ],
        ),
      ),
    );
  }
}

class _EntryList extends ConsumerWidget {
  final CrystalTheme theme;

  const _EntryList({required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(crystaliumProvider);

    return ListView.builder(
      itemCount: state.cgtFile!.entries.length,
      itemBuilder: (context, index) {
        final entry = state.cgtFile!.entries[index];
        final isSelected = state.selectedEntry == entry;
        final name = entry.patternName.replaceAll(RegExp(r'\x00'), '');
        final role = CrystariumRole.fromId(entry.roleId);

        return ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          selected: isSelected,
          selectedTileColor: theme.accent.withValues(alpha: 0.1),
          leading: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _getRoleColor(entry.roleId),
              shape: BoxShape.circle,
            ),
          ),
          title: Text(
            name.isEmpty ? "Entry $index" : "$index: $name",
            style: TextStyle(
              color: isSelected ? theme.accent : Colors.white,
              fontSize: 13,
            ),
          ),
          subtitle: Text(
            "Stage ${entry.stage} | ${role.abbreviation}",
            style: TextStyle(fontSize: 10, color: Colors.white30),
          ),
          onTap: () => ref.read(crystaliumProvider.notifier).selectEntry(entry),
        );
      },
    );
  }

  Color _getRoleColor(int roleId) {
    switch (roleId) {
      case 1:
        return const Color(0xFFFF4444);
      case 5:
        return const Color(0xFF44FF44);
      case 2:
        return const Color(0xFF4444FF);
      case 3:
        return const Color(0xFFFF44FF);
      case 0:
        return const Color(0xFFFFFF44);
      case 4:
        return const Color(0xFF44FFFF);
      default:
        return Colors.white;
    }
  }
}

class _NodeList extends ConsumerWidget {
  final CrystalTheme theme;

  const _NodeList({required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(crystaliumProvider);
    final selectedEntry = state.selectedEntry!;

    return ListView.builder(
      itemCount: selectedEntry.nodeIds.length,
      itemBuilder: (context, index) {
        final nodeIdx = selectedEntry.nodeIds[index];
        if (nodeIdx == 0) return const SizedBox.shrink();
        if (nodeIdx >= state.cgtFile!.nodes.length) return const SizedBox.shrink();

        final node = state.cgtFile!.nodes[nodeIdx];
        final isSelected = state.selectedNodeIdx == nodeIdx;
        final hasChildren = state.childrenMap.containsKey(nodeIdx) &&
            state.childrenMap[nodeIdx]!.isNotEmpty;

        return ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          selected: isSelected,
          selectedTileColor: theme.accent.withValues(alpha: 0.1),
          leading: Icon(
            hasChildren ? Icons.account_tree : Icons.circle,
            size: 12,
            color: isSelected ? theme.accent : Colors.white38,
          ),
          title: Text(
            node.name.replaceAll(RegExp(r'\x00'), ''),
            style: TextStyle(
              color: isSelected ? theme.accent : Colors.white70,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
          subtitle: Text(
            'ID: $nodeIdx | Parent: ${node.parentIndex}',
            style: TextStyle(fontSize: 9, color: Colors.white24),
          ),
          onTap: () => ref.read(crystaliumProvider.notifier).selectNode(nodeIdx),
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final CrystalTheme theme;

  const _SectionLabel({required this.text, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0, top: 4.0),
      child: Text(
        text,
        style: TextStyle(
          color: theme.accent.withValues(alpha: 0.7),
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
