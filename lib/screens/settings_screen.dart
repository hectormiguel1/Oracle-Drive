import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oracle_drive/components/widgets/crystal_button.dart';
import 'package:oracle_drive/components/widgets/crystal_dialog.dart';
import 'package:oracle_drive/components/widgets/crystal_dropdowns.dart';
import 'package:oracle_drive/components/widgets/crystal_panel.dart';
import 'package:oracle_drive/components/widgets/crystal_snackbar.dart';
import 'package:oracle_drive/components/widgets/crystal_switch.dart';
import 'package:oracle_drive/components/widgets/crystal_text_field.dart';
import 'package:oracle_drive/components/widgets/crystal_ribbon.dart';
import 'package:oracle_drive/components/widgets/style.dart';
import 'package:oracle_drive/providers/journal_provider.dart';
import 'package:oracle_drive/providers/settings_provider.dart';
import 'package:oracle_drive/src/isar/settings/settings_models.dart';
import 'package:oracle_drive/theme/crystal_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _retentionDaysController = TextEditingController();
  final _retentionCountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final settings = ref.read(settingsNotifierProvider);
    _retentionDaysController.text = settings.retentionDays.toString();
    _retentionCountController.text = settings.retentionCount.toString();
  }

  @override
  void dispose() {
    _retentionDaysController.dispose();
    _retentionCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsNotifierProvider);
    final entryCount = ref.watch(journalEntryCountProvider);
    final groupCount = ref.watch(journalGroupCountProvider);
    final accentColor = Theme.of(context).extension<CrystalTheme>()?.accent ?? Colors.cyan;

    return Scaffold(
      backgroundColor: CrystalColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(accentColor),
            const SizedBox(height: 24),
            _buildJournalSection(settings, entryCount, groupCount, accentColor),
            const SizedBox(height: 24),
            _buildWorkspacesSection(settings, accentColor),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color accentColor) {
    return Row(
      children: [
        Icon(
          Icons.settings,
          color: accentColor,
          size: 32,
        ),
        const SizedBox(width: 12),
        const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildJournalSection(SettingsState settings, int entryCount, int groupCount, Color accentColor) {
    return CrystalPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'JOURNAL SETTINGS',
              style: CrystalStyles.sectionHeader.copyWith(color: accentColor),
            ),
          ),

          // Enable/Disable Journal
          _buildSettingRow(
            label: 'Enable Journaling',
            description: 'Track all changes for undo/redo support',
            child: CrystalSwitch(
              value: settings.journalEnabled,
              onChanged: (value) {
                ref.read(settingsNotifierProvider.notifier).setJournalEnabled(value);
              },
            ),
          ),
          const Divider(color: Colors.white12, height: 32),

          // Retention Mode
          _buildSettingRow(
            label: 'Retention Policy',
            description: 'How long to keep journal history',
            child: SizedBox(
              width: 200,
              child: CrystalDropdown<JournalRetentionMode>(
                value: settings.retentionMode,
                items: JournalRetentionMode.values,
                itemLabelBuilder: (mode) => _retentionModeLabel(mode),
                onChanged: (mode) {
                  ref.read(settingsNotifierProvider.notifier).setJournalRetentionMode(mode);
                },
              ),
            ),
          ),

          // Retention Value (conditional)
          if (settings.retentionMode == JournalRetentionMode.days) ...[
            const SizedBox(height: 16),
            _buildSettingRow(
              label: 'Retention Days',
              description: 'Delete entries older than this many days',
              child: SizedBox(
                width: 120,
                child: CrystalTextField(
                  controller: _retentionDaysController,
                  onChanged: (value) {
                    final days = int.tryParse(value);
                    if (days != null && days > 0) {
                      ref.read(settingsNotifierProvider.notifier).setJournalRetentionDays(days);
                    }
                  },
                ),
              ),
            ),
          ],
          if (settings.retentionMode == JournalRetentionMode.count) ...[
            const SizedBox(height: 16),
            _buildSettingRow(
              label: 'Max Entries',
              description: 'Keep only the last N entries',
              child: SizedBox(
                width: 120,
                child: CrystalTextField(
                  controller: _retentionCountController,
                  onChanged: (value) {
                    final count = int.tryParse(value);
                    if (count != null && count > 0) {
                      ref.read(settingsNotifierProvider.notifier).setJournalRetentionCount(count);
                    }
                  },
                ),
              ),
            ),
          ],
          const Divider(color: Colors.white12, height: 32),

          // Journal Stats
          _buildSettingRow(
            label: 'Journal Statistics',
            description: 'Current journal size and usage',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatChip('Entries', entryCount.toString(), accentColor),
                  const SizedBox(width: 16),
                  _buildStatChip('Groups', groupCount.toString(), accentColor),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Actions
          Row(
            children: [
              CrystalButton(
                label: 'Apply Retention Policy',
                icon: Icons.cleaning_services,
                onPressed: () {
                  ref.read(journalNotifierProvider.notifier).applyRetentionPolicy();
                  _refreshCounts();
                  showCrystalSnackBar(
                    context,
                    'Retention policy applied',
                    type: CrystalSnackBarType.success,
                  );
                },
              ),
              const SizedBox(width: 16),
              CrystalButton(
                label: 'Clear All History',
                icon: Icons.delete_forever,
                onPressed: _confirmClearHistory,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspacesSection(SettingsState settings, Color accentColor) {
    return CrystalPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'DEFAULT WORKSPACES',
              style: CrystalStyles.sectionHeader.copyWith(color: accentColor),
            ),
          ),

          _buildWorkspaceRow(
            label: 'FF13',
            path: settings.defaultWorkspaceFf13,
            onSelect: () => _selectWorkspace(0),
            onClear: () => _clearWorkspace(0),
            accentColor: accentColor,
          ),
          const SizedBox(height: 16),
          _buildWorkspaceRow(
            label: 'FF13-2',
            path: settings.defaultWorkspaceFf132,
            onSelect: () => _selectWorkspace(1),
            onClear: () => _clearWorkspace(1),
            accentColor: accentColor,
          ),
          const SizedBox(height: 16),
          _buildWorkspaceRow(
            label: 'FF13-LR',
            path: settings.defaultWorkspaceFf13Lr,
            onSelect: () => _selectWorkspace(2),
            onClear: () => _clearWorkspace(2),
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow({
    required String label,
    required String description,
    required Widget child,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        child,
      ],
    );
  }

  Widget _buildStatChip(String label, String value, Color accentColor) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: accentColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildWorkspaceRow({
    required String label,
    required String? path,
    required VoidCallback onSelect,
    required VoidCallback onClear,
    required Color accentColor,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white12),
            ),
            child: Text(
              path ?? 'Not set',
              style: TextStyle(
                color: path != null ? Colors.white : Colors.white54,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(Icons.folder_open, color: accentColor),
          onPressed: onSelect,
          tooltip: 'Select folder',
        ),
        if (path != null)
          IconButton(
            icon: const Icon(Icons.clear, color: Colors.white54),
            onPressed: onClear,
            tooltip: 'Clear',
          ),
      ],
    );
  }

  String _retentionModeLabel(JournalRetentionMode mode) {
    switch (mode) {
      case JournalRetentionMode.unlimited:
        return 'Unlimited';
      case JournalRetentionMode.days:
        return 'Time-based';
      case JournalRetentionMode.count:
        return 'Count-based';
    }
  }

  void _refreshCounts() {
    final repo = ref.read(journalRepositoryProvider);
    ref.read(journalEntryCountProvider.notifier).state = repo.getEntryCount();
    ref.read(journalGroupCountProvider.notifier).state = repo.getGroupCount();
  }

  Future<void> _confirmClearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => CrystalDialog(
        title: 'Clear Journal History',
        content: const Text(
          'This will permanently delete all journal entries. '
          'You will lose undo/redo history. This cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          CrystalButton(
            label: 'Cancel',
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CrystalButton(
            label: 'Clear All',
            isPrimary: true,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(journalNotifierProvider.notifier).clearAll();
      _refreshCounts();
      if (mounted) {
        showCrystalSnackBar(
          context,
          'Journal history cleared',
          type: CrystalSnackBarType.success,
        );
      }
    }
  }

  Future<void> _selectWorkspace(int gameCode) async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select default workspace',
    );

    if (result != null) {
      ref.read(settingsNotifierProvider.notifier).setDefaultWorkspace(gameCode, result);
    }
  }

  void _clearWorkspace(int gameCode) {
    ref.read(settingsNotifierProvider.notifier).setDefaultWorkspace(gameCode, null);
  }
}
