import 'package:oracle_drive/src/services/app_database.dart';
import 'package:oracle_drive/components/widgets/crystal_button.dart';
import 'package:oracle_drive/components/widgets/crystal_dialog.dart';
import 'package:oracle_drive/components/widgets/crystal_dropdowns.dart';
import 'package:oracle_drive/components/widgets/crystal_loading_spinner.dart';
import 'package:oracle_drive/components/widgets/crystal_panel.dart';
import 'package:oracle_drive/components/widgets/crystal_progress_bar.dart';
import 'package:oracle_drive/components/widgets/crystal_snackbar.dart';
import 'package:oracle_drive/components/ztr/ztr_action_buttons.dart';
import 'package:oracle_drive/components/ztr/ztr_search_field.dart';
import 'package:oracle_drive/components/ztr/ztr_table.dart';
import 'package:oracle_drive/models/ztr_model.dart';
import 'package:oracle_drive/providers/app_state_provider.dart';
import 'package:oracle_drive/providers/ztr_provider.dart';
import 'package:oracle_drive/theme/crystal_theme.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ZtrScreen extends ConsumerStatefulWidget {
  const ZtrScreen({super.key});

  @override
  ConsumerState<ZtrScreen> createState() => _ZtrScreenState();
}

class _ZtrScreenState extends ConsumerState<ZtrScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    // Initial load will be triggered by build() checking ztrInitializedProvider
  }

  /// Initialize ZTR data for the given game code if not already initialized.
  Future<void> _initializeIfNeeded(dynamic gameCode) async {
    final isInitialized = ref.read(ztrInitializedProvider(gameCode));
    if (isInitialized) return;

    // Mark as loading during initialization
    ref.read(ztrIsLoadingProvider(gameCode).notifier).state = true;

    try {
      await AppDatabase.ensureInitialized();
      final dbCount = AppDatabase.instance.getRepositoryForGame(gameCode).getStringCount();
      ref.read(ztrStringCountProvider(gameCode).notifier).state = dbCount;
      // Only fetch entries if there are strings in the database
      if (dbCount > 0) {
        await ref.read(ztrNotifierProvider(gameCode)).fetchStrings();
      }
    } finally {
      ref.read(ztrInitializedProvider(gameCode).notifier).state = true;
      ref.read(ztrIsLoadingProvider(gameCode).notifier).state = false;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final gameCode = ref.read(selectedGameProvider);
    ref.read(ztrNotifierProvider(gameCode)).setFilter(_searchController.text);
  }

  Future<void> _loadZtrFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ztr'],
      dialogTitle: 'Select .ztr file to load',
    );

    if (result != null && result.files.single.path != null) {
      final gameCode = ref.read(selectedGameProvider);
      try {
        await ref.read(ztrNotifierProvider(gameCode)).loadZtrFile(result.files.single.path!);
        _showSuccessSnackBar("ZTR data loaded successfully!");
      } catch (e) {
        _showErrorSnackBar("Error loading ZTR: $e");
      }
    }
  }

  Future<void> _loadZtrDirectory() async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select directory containing .ztr files',
    );

    if (result != null) {
      // Show region filter dialog
      final filter = await _showRegionFilterDialog();
      if (filter == null) return; // User cancelled

      final gameCode = ref.read(selectedGameProvider);
      try {
        await ref.read(ztrNotifierProvider(gameCode)).loadZtrDirectory(
              result,
              filePattern: filter.isEmpty ? null : filter,
            );
        _showSuccessSnackBar("ZTR directory loaded successfully!");
      } catch (e) {
        _showErrorSnackBar("Error loading ZTR directory: $e");
      }
    }
  }

  Future<String?> _showRegionFilterDialog() async {
    String selectedFilter = '';
    final customController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => CrystalDialog(
          title: 'Select Region Filter',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose which ZTR files to load based on region suffix:',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFilterChip('All Files', '', selectedFilter, (v) {
                    setState(() => selectedFilter = v);
                  }),
                  _buildFilterChip('US', '_us.ztr', selectedFilter, (v) {
                    setState(() => selectedFilter = v);
                  }),
                  _buildFilterChip('JP', '_jp.ztr', selectedFilter, (v) {
                    setState(() => selectedFilter = v);
                  }),
                  _buildFilterChip('KR', '_kr.ztr', selectedFilter, (v) {
                    setState(() => selectedFilter = v);
                  }),
                  _buildFilterChip('CN', '_ch.ztr', selectedFilter, (v) {
                    setState(() => selectedFilter = v);
                  }),
                  _buildFilterChip('DE', '_gr.ztr', selectedFilter, (v) {
                    setState(() => selectedFilter = v);
                  }),
                  _buildFilterChip('FR', '_fr.ztr', selectedFilter, (v) {
                    setState(() => selectedFilter = v);
                  }),
                  _buildFilterChip('IT', '_it.ztr', selectedFilter, (v) {
                    setState(() => selectedFilter = v);
                  }),
                  _buildFilterChip('ES', '_sp.ztr', selectedFilter, (v) {
                    setState(() => selectedFilter = v);
                  }),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: customController,
                decoration: const InputDecoration(
                  labelText: 'Custom pattern (e.g., _us.ztr)',
                  hintText: 'Enter custom filter pattern',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() => selectedFilter = value);
                },
              ),
            ],
          ),
          actions: [
            CrystalButton(
              label: 'Cancel',
              onPressed: () => Navigator.of(context).pop(null),
            ),
            CrystalButton(
              label: 'Load',
              isPrimary: true,
              onPressed: () => Navigator.of(context).pop(selectedFilter),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String value,
    String selectedValue,
    ValueChanged<String> onSelected,
  ) {
    final isSelected = value == selectedValue;
    final theme = Theme.of(context).extension<CrystalTheme>()!;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(value),
      selectedColor: theme.accent.withValues(alpha: 0.3),
      checkmarkColor: theme.accent,
      labelStyle: TextStyle(
        color: isSelected ? theme.accent : Colors.white70,
      ),
      side: BorderSide(
        color: isSelected ? theme.accent : Colors.white24,
      ),
      backgroundColor: Colors.black26,
    );
  }

  Future<void> _dumpZtrFile() async {
    final gameCode = ref.read(selectedGameProvider);
    final notifier = ref.read(ztrNotifierProvider(gameCode));
    final hasFilters = notifier.hasActiveFilters;
    final filteredEntries = ref.read(filteredZtrEntriesProvider(gameCode));
    final stringCount = ref.read(ztrStringCountProvider(gameCode));

    if (stringCount == 0) {
      _showWarningSnackBar("No strings in database to dump.");
      return;
    }

    if (hasFilters && filteredEntries.isEmpty) {
      _showWarningSnackBar("No entries match current filters.");
      return;
    }

    final count = hasFilters ? filteredEntries.length : stringCount;
    final suffix = hasFilters ? '_filtered' : '_dump';

    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save ZTR file ($count entries)',
      fileName: '${gameCode.name}$suffix.ztr',
      type: FileType.custom,
      allowedExtensions: ['ztr'],
    );

    if (savePath != null) {
      try {
        if (hasFilters) {
          await notifier.dumpFilteredZtrFile(savePath);
          _showSuccessSnackBar("${filteredEntries.length} filtered entries dumped to ZTR!");
        } else {
          await notifier.dumpZtrFile(savePath);
          _showSuccessSnackBar("ZTR data dumped successfully!");
        }
      } catch (e) {
        _showErrorSnackBar("Error dumping ZTR: $e");
      }
    }
  }

  Future<void> _dumpTxtFile() async {
    final gameCode = ref.read(selectedGameProvider);
    final notifier = ref.read(ztrNotifierProvider(gameCode));
    final hasFilters = notifier.hasActiveFilters;
    final filteredEntries = ref.read(filteredZtrEntriesProvider(gameCode));
    final stringCount = ref.read(ztrStringCountProvider(gameCode));

    if (stringCount == 0) {
      _showWarningSnackBar("No strings in database to dump.");
      return;
    }

    if (hasFilters && filteredEntries.isEmpty) {
      _showWarningSnackBar("No entries match current filters.");
      return;
    }

    final count = hasFilters ? filteredEntries.length : stringCount;
    final suffix = hasFilters ? '_filtered' : '_dump';

    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Text file ($count entries)',
      fileName: '${gameCode.name}$suffix.txt',
      type: FileType.custom,
      allowedExtensions: ['txt'],
    );

    if (savePath != null) {
      try {
        if (hasFilters) {
          await notifier.dumpFilteredTxtFile(savePath);
          _showSuccessSnackBar("${filteredEntries.length} filtered entries dumped to text!");
        } else {
          await notifier.dumpTxtFile(savePath);
          _showSuccessSnackBar("ZTR data dumped to text successfully!");
        }
      } catch (e) {
        _showErrorSnackBar("Error dumping ZTR to text: $e");
      }
    }
  }

  Future<void> _addZtrEntry() async {
    final idController = TextEditingController();
    final textController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => CrystalDialog(
        title: "Add New ZTR Entry",
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: idController,
                decoration: const InputDecoration(labelText: "Reference ID"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "ID cannot be empty";
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: textController,
                decoration: const InputDecoration(labelText: "String Value"),
                maxLines: null,
              ),
            ],
          ),
        ),
        actions: [
          CrystalButton(
            label: "Cancel",
            onPressed: () => Navigator.of(context).pop(),
          ),
          CrystalButton(
            label: "Add",
            isPrimary: true,
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(context).pop();
                final gameCode = ref.read(selectedGameProvider);
                try {
                  await ref.read(ztrNotifierProvider(gameCode)).addEntry(
                        idController.text,
                        textController.text,
                      );
                  _showSuccessSnackBar("Entry '${idController.text}' added.");
                } catch (e) {
                  _showErrorSnackBar("Error adding entry: $e");
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleEntryUpdated(ZtrEntry updatedEntry) async {
    final gameCode = ref.read(selectedGameProvider);
    try {
      await ref.read(ztrNotifierProvider(gameCode)).updateEntry(updatedEntry);
      _showSuccessSnackBar("Entry '${updatedEntry.id}' updated.");
    } catch (e) {
      _showErrorSnackBar("Error updating entry: $e");
    }
  }

  Future<void> _handleEntryRemoved(String entryId) async {
    showDialog(
      context: context,
      builder: (context) => CrystalDialog(
        title: "Confirm Deletion",
        content: Text("Are you sure you want to delete entry '$entryId'?"),
        actions: [
          CrystalButton(
            label: "Cancel",
            onPressed: () => Navigator.of(context).pop(),
          ),
          CrystalButton(
            label: "Delete",
            isPrimary: true,
            onPressed: () async {
              Navigator.of(context).pop();
              final gameCode = ref.read(selectedGameProvider);
              try {
                await ref.read(ztrNotifierProvider(gameCode)).deleteEntry(entryId);
                _showSuccessSnackBar("Entry '$entryId' deleted.");
              } catch (e) {
                _showErrorSnackBar("Error deleting entry: $e");
              }
            },
          ),
        ],
      ),
    );
  }

  void _onResetDatabasePressed() {
    showDialog(
      context: context,
      builder: (context) => CrystalDialog(
        title: "Confirm Reset",
        content: const Text(
          "Are you sure you want to reset the database? This will delete all loaded strings.",
        ),
        actions: [
          CrystalButton(
            label: "Cancel",
            onPressed: () => Navigator.of(context).pop(),
          ),
          CrystalButton(
            label: "Reset",
            isPrimary: true,
            onPressed: () async {
              Navigator.of(context).pop();
              final gameCode = ref.read(selectedGameProvider);
              try {
                await ref.read(ztrNotifierProvider(gameCode)).resetDatabase();
                _showSuccessSnackBar("Database reset successfully.");
              } catch (e) {
                _showErrorSnackBar("Error resetting DB: $e");
              }
            },
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) context.showSuccessSnackBar(message);
  }

  void _showErrorSnackBar(String message) {
    if (mounted) context.showErrorSnackBar(message);
  }

  void _showWarningSnackBar(String message) {
    if (mounted) context.showWarningSnackBar(message);
  }

  @override
  Widget build(BuildContext context) {
    final gameCode = ref.watch(selectedGameProvider);
    final isInitialized = ref.watch(ztrInitializedProvider(gameCode));
    final isLoading = ref.watch(ztrIsLoadingProvider(gameCode));
    final stringCount = ref.watch(ztrStringCountProvider(gameCode));
    final filteredEntries = ref.watch(filteredZtrEntriesProvider(gameCode));
    final directoryProgress = ref.watch(ztrDirectoryProgressProvider(gameCode));
    final sourceFiles = ref.watch(ztrSourceFilesProvider(gameCode));
    final sourceFileFilter = ref.watch(ztrSourceFileFilterProvider(gameCode));

    // Trigger initialization if needed (runs once per game code)
    if (!isInitialized && !isLoading) {
      // Use addPostFrameCallback to avoid calling setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _initializeIfNeeded(gameCode);
      });
    }

    // Show loading spinner during initialization or ongoing operations
    final showLoading = !isInitialized || isLoading;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: showLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CrystalLoadingSpinner(label: 'Loading...'),
                  if (directoryProgress != null) ...[
                    const SizedBox(height: 20),
                    _buildDirectoryProgress(directoryProgress),
                  ],
                ],
              ),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16.0),
                  child: stringCount == 0
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Current Game: ${gameCode.displayName}",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CrystalButton(
                                    onPressed: _loadZtrFile,
                                    icon: Icons.insert_drive_file,
                                    label: "Load ZTR File",
                                    isPrimary: true,
                                  ),
                                  const SizedBox(width: 12),
                                  CrystalButton(
                                    onPressed: _loadZtrDirectory,
                                    icon: Icons.folder_open,
                                    label: "Load Directory",
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            Text(
                              "Current Game: ${gameCode.displayName}",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: ZtrSearchField(
                                    controller: _searchController,
                                    onChanged: (query) => _onSearchChanged(),
                                  ),
                                ),
                                if (sourceFiles.isNotEmpty) ...[
                                  const SizedBox(width: 12),
                                  _buildSourceFileFilter(
                                    sourceFiles,
                                    sourceFileFilter,
                                    gameCode,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 10),
                            ZtrActionButtons(
                              selectedGame: gameCode,
                              stringCount: stringCount,
                              onLoadZtrFile: _loadZtrFile,
                              onLoadZtrDirectory: _loadZtrDirectory,
                              onDumpZtrFile: _dumpZtrFile,
                              onDumpTxtFile: _dumpTxtFile,
                              onResetDatabase: _onResetDatabasePressed,
                              onAddEntry: _addZtrEntry,
                            ),
                          ],
                        ),
                ),
                if (stringCount > 0 && filteredEntries.isNotEmpty)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: CrystalPanel(
                        child: ZtrTable(
                          gameCode: gameCode,
                          entries: filteredEntries,
                          onEntryUpdated: _handleEntryUpdated,
                          onEntryRemoved: _handleEntryRemoved,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildDirectoryProgress(dynamic progress) {
    final total = progress.totalFiles.toInt();
    final processed = progress.processedFiles.toInt();
    final successCount = progress.successCount.toInt();
    final errorCount = progress.errorCount.toInt();
    final currentFile = progress.currentFile as String;
    final stage = progress.stage as String;

    final percentage = total > 0 ? processed / total : 0.0;

    return SizedBox(
      width: 400,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            stage == 'scanning'
                ? 'Scanning for ZTR files...'
                : stage == 'complete'
                    ? 'Complete!'
                    : 'Processing: $currentFile',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          CrystalProgressBar(value: percentage),
          const SizedBox(height: 8),
          Text(
            '$processed / $total files (Success: $successCount, Errors: $errorCount)',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceFileFilter(
    List<String> sourceFiles,
    String? currentFilter,
    dynamic gameCode,
  ) {
    // Add "All Files" option at the beginning
    final allOptions = ['', ...sourceFiles];
    final currentValue = currentFilter ?? '';

    return SizedBox(
      width: 300,
      child: CrystalDropdown<String>(
        value: currentValue,
        items: allOptions,
        itemLabelBuilder: (item) => item.isEmpty ? 'All Files' : item,
        onChanged: (value) {
          ref
              .read(ztrNotifierProvider(gameCode))
              .setSourceFileFilter(value.isEmpty ? null : value);
        },
      ),
    );
  }
}
