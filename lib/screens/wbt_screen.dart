import 'package:oracle_drive/components/file_tree_view.dart';
import 'package:oracle_drive/components/widgets/crystal_button.dart';
import 'package:oracle_drive/components/widgets/crystal_panel.dart';
import 'package:oracle_drive/components/widgets/crystal_tab_bar.dart';
import 'package:oracle_drive/components/widgets/crystal_progress_bar.dart';
import 'package:oracle_drive/models/app_game_code.dart'; // Import AppGameCode
import 'package:oracle_drive/providers/app_state_provider.dart';
import 'package:oracle_drive/providers/wbt_provider.dart';
import 'package:oracle_drive/src/third_party/wbtlib/wbt.dart'; // Import wbt.g.dart for GameCode
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

class WhiteBinToolsScreen extends ConsumerStatefulWidget {
  const WhiteBinToolsScreen({super.key});

  @override
  ConsumerState<WhiteBinToolsScreen> createState() =>
      _WhiteBinToolsScreenState();
}

class _WhiteBinToolsScreenState extends ConsumerState<WhiteBinToolsScreen>
    with AutomaticKeepAliveClientMixin {
  final Logger _logger = Logger('WhiteBinToolsScreen');

  AppGameCode get _gameCode => ref.watch(selectedGameProvider);

  @override
  bool get wantKeepAlive => true;

  Future<void> _loadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['bin'],
      dialogTitle: 'Select filelist (e.g. white_img.win32.bin)',
    );

    if (result != null && result.files.single.path != null) {
      ref
          .read(wbtProvider(_gameCode).notifier)
          .setFileListPath(result.files.single.path);
      _logger.info("Selected filelist: ${result.files.single.path}");
    }
  }

  Future<void> _parseEntries() async {
    final state = ref.read(wbtProvider(_gameCode));
    if (state.fileListPath == null) return;

    ref.read(wbtProvider(_gameCode).notifier).setProcessing(true);
    try {
      final wbtGameCode = _gameCode.toWbtGameCode();
      if (wbtGameCode == null) {
        throw Exception(
          "Unsupported game code for WBT operations: ${_gameCode.displayName}",
        );
      }

      List<FileEntry> entries = await WhiteBinTools.parseFileEntries(
        wbtGameCode,
        state.fileListPath!,
      );

      ref.read(wbtProvider(_gameCode).notifier).setFileEntries(entries);
      _logger.info(
        "Loaded ${entries.length} entries for game ${_gameCode.displayName}.",
      );
    } catch (e) {
      _logger.severe("Error parsing filelist: $e");
    } finally {
      ref.read(wbtProvider(_gameCode).notifier).setProcessing(false);
    }
  }

  Future<void> _extractFiles() async {
    final state = ref.read(wbtProvider(_gameCode));
    if (state.fileEntries == null || state.selectedFilesToExtract.isEmpty)
      return;

    String? binPath = await FilePicker.platform
        .pickFiles(
          type: FileType.custom,
          allowedExtensions: ['bin'],
          dialogTitle: 'Select the content .bin (e.g. _white_img.bin)',
        )
        .then((result) => result?.files.single.path);

    if (binPath == null) return;
    ref.read(wbtProvider(_gameCode).notifier).setBinPath(binPath);

    String? outputDir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select output directory',
    );
    if (outputDir == null) return;

    ref.read(wbtProvider(_gameCode).notifier).setProcessing(true);
    ref.read(wbtProvider(_gameCode).notifier).setExtractionProgress(0);
    try {
      final wbtGameCode = _gameCode.toWbtGameCode();
      if (wbtGameCode == null) {
        throw Exception(
          "Unsupported game code for WBT operations: ${_gameCode.displayName}",
        );
      }

      await WhiteBinTools.unpack(
        wbtGameCode,
        state.fileListPath!,
        binPath,
        state.selectedFilesToExtract,
        outputDir: outputDir,
        onProgress: (p) {
          ref.read(wbtProvider(_gameCode).notifier).setExtractionProgress(p);
        },
      );
      _logger.info("Extraction complete.");
    } catch (e) {
      _logger.severe("Extraction failed: $e");
    } finally {
      ref.read(wbtProvider(_gameCode).notifier).setProcessing(false);
      ref.read(wbtProvider(_gameCode).notifier).setExtractionProgress(0);
    }
  }

  Future<void> _repackFiles() async {
    final state = ref.read(wbtProvider(_gameCode));
    if (state.fileListPath == null) {
      _logger.warning("Please load a filelist first.");
      return;
    }

    String? currentBinPath = state.binPath;
    if (currentBinPath == null) {
      String? binPath = await FilePicker.platform
          .pickFiles(
            type: FileType.custom,
            allowedExtensions: ['bin'],
            dialogTitle:
                'Select the content .bin to UPDATE (e.g. _white_img.bin)',
          )
          .then((result) => result?.files.single.path);
      if (binPath == null) return;
      currentBinPath = binPath;
      ref.read(wbtProvider(_gameCode).notifier).setBinPath(binPath);
    }

    String? sourceDir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select directory with modded files to inject',
    );
    if (sourceDir == null) return;
    ref.read(wbtProvider(_gameCode).notifier).setRepackSourceDir(sourceDir);

    ref.read(wbtProvider(_gameCode).notifier).setProcessing(true);
    try {
      final wbtGameCode = _gameCode.toWbtGameCode();
      if (wbtGameCode == null) {
        throw Exception(
          "Unsupported game code for WBT operations: ${_gameCode.displayName}",
        );
      }

      _logger.info(
        "Repacking from $sourceDir for game ${_gameCode.displayName}...",
      );
      await WhiteBinTools.repackMultiple(
        wbtGameCode,
        state.fileListPath!,
        currentBinPath,
        sourceDir,
        makeBackup: true,
      );
      _logger.info("Repack complete. Backup created.");
    } catch (e) {
      _logger.severe("Repack failed: $e");
    } finally {
      ref.read(wbtProvider(_gameCode).notifier).setProcessing(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // KeepAlive

    final state = ref.watch(wbtProvider(_gameCode));

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // Header / Toolbar
          Container(
            color: Colors.black.withValues(alpha: 0.4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                CrystalButton(
                  onPressed: _loadFile,
                  icon: Icons.folder_open,
                  label: state.fileListPath == null
                      ? "Load FileList"
                      : "Change FileList",
                  isPrimary: true,
                ),
                if (state.fileListPath != null) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      "Loaded: ${state.fileListPath!.split('/').last}",
                      style: const TextStyle(color: Colors.white70),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Tabs
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: CrystalTabBar(
              labels: const ["EXTRACT", "REPACK"],
              icons: const [Icons.file_download, Icons.file_upload],
            ),
          ),

          Expanded(
            child: TabBarView(
              children: [
                // Extract View
                _buildExtractView(state),

                // Repack View
                _buildRepackView(state),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtractView(WbtState state) {
    if (state.isProcessing && state.extractionProgress > 0) {
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CrystalProgressBar(
                value: state.extractionProgress,
                label: "EXTRACTING FILES...",
                valueLabel: "${(state.extractionProgress * 100).toInt()}%",
              ),
              const SizedBox(height: 16),
              Text(
                "Processing ${state.selectedFilesToExtract.length} files...",
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    if (state.isProcessing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.fileListPath == null) {
      return const Center(
        child: Text(
          "Load a filelist (.bin) to start.",
          style: TextStyle(color: Colors.white24),
        ),
      );
    }

    if (state.fileEntries == null) {
      return Center(
        child: CrystalButton(
          onPressed: _parseEntries,
          icon: Icons.list,
          label: "LOAD FILE TREE",
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: CrystalPanel(
        child: Column(
          children: [
            Expanded(
              child: MyTreeWidget(
                files: state.fileEntries!,
                onSelectionChanged: (selected) {
                  ref
                      .read(wbtProvider(_gameCode).notifier)
                      .setSelectedFiles(selected);
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black.withValues(alpha: 0.3),
              width: double.infinity,
              alignment: Alignment.center, // Center the button
              child: CrystalButton(
                onPressed: state.selectedFilesToExtract.isNotEmpty
                    ? _extractFiles
                    : null,
                icon: Icons.download,
                label: "EXTRACT ${state.selectedFilesToExtract.length} FILES",
                isPrimary: state.selectedFilesToExtract.isNotEmpty,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepackView(WbtState state) {
    if (state.isProcessing) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: CrystalPanel(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  size: 64,
                  color: Colors.cyan,
                ),
                const SizedBox(height: 24),
                const Text(
                  "Batch Repack Mode",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Select a directory containing the modified files.\n"
                  "The tool will scan the directory and update the .bin archive with any matching files found.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54),
                ),
                const SizedBox(height: 48),

                // Source Dir Display
                if (state.repackSourceDir != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.folder, color: Colors.amber),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            state.repackSourceDir!,
                            style: const TextStyle(color: Colors.white70),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                CrystalButton(
                  onPressed: state.fileListPath != null ? _repackFiles : null,
                  icon: Icons.upload_file,
                  label: "SELECT FOLDER & REPACK",
                  isPrimary: true,
                ),
                if (state.fileListPath == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 16.0),
                    child: Text(
                      "Please load a filelist first (Top Bar)",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
