import 'dart:io';

import 'package:fabula_nova_sdk/bridge_generated/modules/event/structs.dart'
    as event_sdk;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oracle_drive/components/event/event_detail_panel.dart';
import 'package:oracle_drive/components/event/event_item_list.dart';
import 'package:oracle_drive/components/widgets/crystal_button.dart';
import 'package:oracle_drive/components/widgets/crystal_divider.dart';
import 'package:oracle_drive/components/widgets/crystal_snackbar.dart';
import 'package:oracle_drive/components/widgets/style.dart';
import 'package:oracle_drive/providers/event_provider.dart';
import 'package:path/path.dart' as p;

class EventScreen extends ConsumerStatefulWidget {
  const EventScreen({super.key});

  @override
  ConsumerState<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends ConsumerState<EventScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      ref.read(eventNotifierProvider).setSelectedTab(_tabController.index);
    }
  }

  Future<void> _pickEventFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xwb'],
      dialogTitle: 'Select Event File (.xwb)',
    );

    if (result != null && result.files.single.path != null) {
      await ref
          .read(eventNotifierProvider)
          .loadEvent(result.files.single.path!);
    }
  }

  Future<void> _pickEventDirectory() async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Event Directory (e.g., ev_xxxx_xxx)',
    );

    if (result != null) {
      await ref.read(eventNotifierProvider).loadEventDirectory(result);
    }
  }

  Future<void> _extractEvent() async {
    final path = ref.read(eventPathProvider);
    if (path == null) return;

    final outputDir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Output Directory',
    );

    if (outputDir != null) {
      final result = await ref
          .read(eventNotifierProvider)
          .extractEvent(path, outputDir);

      if (mounted) {
        if (result != null && result.extractedFiles.isNotEmpty) {
          context.showSuccessSnackBar(
            'Extracted ${result.extractedFiles.length} files',
          );
        } else {
          context.showErrorSnackBar('Failed to extract event');
        }
      }
    }
  }

  Future<void> _exportJson() async {
    final path = ref.read(eventPathProvider);
    if (path == null) return;

    final json = await ref.read(eventNotifierProvider).exportToJson(path);
    if (json != null) {
      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Event JSON',
        fileName: '${p.basenameWithoutExtension(path)}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (outputPath != null) {
        await File(outputPath).writeAsString(json);
        if (mounted) {
          context.showSuccessSnackBar('Exported to ${p.basename(outputPath)}');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isLoading = ref.watch(eventIsLoadingProvider);
    final error = ref.watch(eventErrorProvider);
    final data = ref.watch(eventDataProvider);
    final displayName = ref.watch(eventDisplayNameProvider);

    return Padding(
      padding: const EdgeInsets.all(13.0),
      child: Column(
        children: [
          // Header
          _buildHeader(displayName, data != null, isLoading),
          const SizedBox(height: 8),
          // Error display
          if (error != null) _buildError(error),
          // Main content
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : data == null
                ? _buildEmptyState()
                : _buildContent(data),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String displayName, bool hasData, bool isLoading) {
    return _EventHeader(
      displayName: displayName,
      hasData: hasData,
      isLoading: isLoading,
      onExtract: _extractEvent,
      onExportJson: _exportJson,
      onPickFile: _pickEventFile,
      onPickDirectory: _pickEventDirectory,
    );
  }

  Widget _buildError(String error) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade300, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.movie_outlined, size: 64, color: Colors.white24),
          const SizedBox(width: 16),
          const Text(
            'No event loaded',
            style: TextStyle(color: Colors.white38, fontSize: 16),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CrystalButton(
                label: 'Load File',
                icon: Icons.insert_drive_file,
                onPressed: _pickEventFile,
              ),
              const SizedBox(width: 12),
              CrystalButton(
                label: 'Load Directory',
                icon: Icons.folder,
                onPressed: _pickEventDirectory,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(event_sdk.EventMetadata data) {
    return Column(
      children: [
        // Tabs
        Container(
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Expanded(
                child: TabBar(
                  controller: _tabController,
                  isScrollable: false,
                  tabs: [
                    _buildTab('Info', ref.watch(eventWpdRecordCountProvider)),
                    _buildTab('Actors', ref.watch(eventActorCountProvider)),
                    _buildTab('Blocks', ref.watch(eventBlockCountProvider)),
                    _buildTab(
                      'External',
                      ref.watch(eventExternalResourceCountProvider),
                    ),
                    _buildTab(
                      'Resources',
                      ref.watch(eventResourceCountProvider),
                    ),
                    _buildTab(
                      'Dialogue',
                      ref.watch(eventDialogueCountProvider),
                    ),
                    _buildTab('Sound', ref.watch(eventSoundCountProvider)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Tab content
        Expanded(child: EventDetailPanel()),
      ],
    );
  }

  Widget _buildTab(String label, int count) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count', style: const TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }
}

/// Extracted event header widget for better performance with selective rebuilds.
class _EventHeader extends ConsumerWidget {
  final String displayName;
  final bool hasData;
  final bool isLoading;
  final VoidCallback onExtract;
  final VoidCallback onExportJson;
  final VoidCallback onPickFile;
  final VoidCallback onPickDirectory;

  const _EventHeader({
    required this.displayName,
    required this.hasData,
    required this.isLoading,
    required this.onExtract,
    required this.onExportJson,
    required this.onPickFile,
    required this.onPickDirectory,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use selective watches - only rebuild when these specific values change
    final actorCount = ref.watch(eventActorCountProvider);
    final blockCount = ref.watch(eventBlockCountProvider);
    final dialogueCount = ref.watch(eventDialogueCountProvider);
    final totalDuration = ref.watch(eventTotalDurationProvider);
    final hasDataset = ref.watch(
      eventDataProvider.select((data) => data?.dataset != null),
    );
    final motionCount = ref.watch(
      eventDataProvider.select(
        (data) => data?.dataset?.motionBlocks.length ?? 0,
      ),
    );
    final cameraCount = ref.watch(
      eventDataProvider.select(
        (data) => data?.dataset?.cameraBlocks.length ?? 0,
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(Icons.movie_outlined, color: Colors.amber, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        style: CrystalStyles.title.copyWith(fontSize: 18),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hasDataset) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.teal.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Colors.teal.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          'DataSet',
                          style: TextStyle(
                            color: Colors.teal.shade300,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (hasData) ...[
                  Text(
                    '$actorCount actors, $blockCount blocks, $dialogueCount dialogue'
                    '${totalDuration > 0 ? " (${totalDuration.toStringAsFixed(1)}s)" : ""}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  if (hasDataset)
                    Text(
                      '$motionCount motion blocks, $cameraCount camera blocks',
                      style: TextStyle(
                        color: Colors.teal.shade400,
                        fontSize: 11,
                      ),
                    ),
                ],
              ],
            ),
          ),
          if (hasData) ...[
            IconButton(
              icon: const Icon(Icons.folder_open_outlined),
              tooltip: 'Extract to Folder',
              onPressed: isLoading ? null : onExtract,
              color: Colors.white70,
            ),
            IconButton(
              icon: const Icon(Icons.data_object),
              tooltip: 'Export JSON',
              onPressed: isLoading ? null : onExportJson,
              color: Colors.white70,
            ),
            const SizedBox(width: 8),
          ],
          CrystalButton(
            label: hasData ? 'Load File' : 'Load Event',
            icon: Icons.insert_drive_file,
            onPressed: isLoading ? null : onPickFile,
          ),
          const SizedBox(width: 8),
          CrystalButton(
            label: 'Load Dir',
            icon: Icons.folder,
            onPressed: isLoading ? null : onPickDirectory,
          ),
        ],
      ),
    );
  }
}
