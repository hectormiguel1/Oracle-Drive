import 'package:fabula_nova_sdk/bridge_generated/api.dart' as sdk;
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart' show Uint64List;
import 'package:oracle_drive/components/widgets/crystal_button.dart';
import 'package:oracle_drive/components/widgets/crystal_file_browser.dart';
import 'package:oracle_drive/components/widgets/crystal_loading_spinner.dart';
import 'package:oracle_drive/components/widgets/crystal_panel.dart';
import 'package:oracle_drive/components/widgets/crystal_tab_bar.dart';
import 'package:oracle_drive/components/widgets/crystal_progress_bar.dart';
import 'package:oracle_drive/models/app_game_code.dart';
import 'package:oracle_drive/providers/app_state_provider.dart';
import 'package:oracle_drive/providers/wbt_provider.dart';
import 'package:oracle_drive/src/services/native_service.dart';
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
      final path = result.files.single.path!;
      ref.read(wbtProvider(_gameCode).notifier).setFileListPath(path);
      _logger.info("Selected filelist: $path");

      // Load file list metadata
      await _loadFileList(path);
    }
  }

  Future<void> _loadFileList(String fileListPath) async {
    final notifier = ref.read(wbtProvider(_gameCode).notifier);
    notifier.setLoadingFileList(true);

    try {
      final entries = await sdk.wbtGetFileList(
        filelistPath: fileListPath,
        gameCode: _gameCode.idx,
      );
      notifier.setFileEntries(entries);
      _logger.info("Loaded ${entries.length} file entries");
    } catch (e) {
      _logger.severe("Failed to load file list: $e");
    } finally {
      notifier.setLoadingFileList(false);
    }
  }

  Future<void> _extractAll() async {
    final state = ref.read(wbtProvider(_gameCode));

    String? binPath = state.binPath ?? await _pickContainerBin();
    if (binPath == null) return;
    ref.read(wbtProvider(_gameCode).notifier).setBinPath(binPath);

    String? outputDir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select output directory',
    );
    if (outputDir == null) return;

    ref.read(wbtProvider(_gameCode).notifier).setProcessing(true);
    ref.read(wbtProvider(_gameCode).notifier).setExtractionProgress(0);
    try {
      await NativeService.instance.unpackWbt(
        _gameCode,
        state.fileListPath!,
        binPath,
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

  Future<void> _extractSelected() async {
    final state = ref.read(wbtProvider(_gameCode));
    if (state.selectedIndices.isEmpty) {
      _logger.warning("No files selected");
      return;
    }

    String? binPath = state.binPath ?? await _pickContainerBin();
    if (binPath == null) return;
    ref.read(wbtProvider(_gameCode).notifier).setBinPath(binPath);

    String? outputDir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select output directory',
    );
    if (outputDir == null) return;

    ref.read(wbtProvider(_gameCode).notifier).setProcessing(true);
    try {
      final indices = Uint64List.fromList(
        state.selectedIndices.map((i) => i).toList(),
      );
      final count = await sdk.wbtExtractFilesByIndices(
        filelistPath: state.fileListPath!,
        containerPath: binPath,
        indices: indices,
        outputDir: outputDir,
        gameCode: _gameCode.idx,
      );
      _logger.info("Extracted ${count.toInt()} files.");
    } catch (e) {
      _logger.severe("Extraction failed: $e");
    } finally {
      ref.read(wbtProvider(_gameCode).notifier).setProcessing(false);
    }
  }

  Future<void> _extractDirectory(String dirPath) async {
    final state = ref.read(wbtProvider(_gameCode));

    String? binPath = state.binPath ?? await _pickContainerBin();
    if (binPath == null) return;
    ref.read(wbtProvider(_gameCode).notifier).setBinPath(binPath);

    String? outputDir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select output directory',
    );
    if (outputDir == null) return;

    ref.read(wbtProvider(_gameCode).notifier).setProcessing(true);
    try {
      final count = await sdk.wbtExtractDirectory(
        filelistPath: state.fileListPath!,
        containerPath: binPath,
        dirPrefix: dirPath,
        outputDir: outputDir,
        gameCode: _gameCode.idx,
      );
      _logger.info("Extracted ${count.toInt()} files from $dirPath");
    } catch (e) {
      _logger.severe("Directory extraction failed: $e");
    } finally {
      ref.read(wbtProvider(_gameCode).notifier).setProcessing(false);
    }
  }

  Future<String?> _pickContainerBin() async {
    return await FilePicker.platform
        .pickFiles(
          type: FileType.custom,
          allowedExtensions: ['bin'],
          dialogTitle: 'Select the content .bin (e.g. _white_img.bin)',
        )
        .then((result) => result?.files.single.path);
  }

  Future<void> _repackFiles() async {
    final state = ref.read(wbtProvider(_gameCode));
    if (state.fileListPath == null) {
      _logger.warning("Please load a filelist first.");
      return;
    }

    String? currentBinPath = state.binPath ?? await _pickContainerBin();
    if (currentBinPath == null) return;
    ref.read(wbtProvider(_gameCode).notifier).setBinPath(currentBinPath);

    String? sourceDir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select directory with modded files to inject',
    );
    if (sourceDir == null) return;
    ref.read(wbtProvider(_gameCode).notifier).setRepackSourceDir(sourceDir);

    ref.read(wbtProvider(_gameCode).notifier).setProcessing(true);
    try {
      _logger.info(
        "Repacking from $sourceDir for game ${_gameCode.displayName}...",
      );
      await NativeService.instance.repackMultipleWbt(
        _gameCode,
        state.fileListPath!,
        currentBinPath,
        sourceDir,
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
                      "Loaded: ${state.fileListPath!.split('/').last} (${state.fileEntries.length} files)",
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
            ],
          ),
        ),
      );
    }

    if (state.isProcessing || state.isLoadingFileList) {
      return const Center(child: CrystalLoadingSpinner(label: 'Processing...'));
    }

    if (state.fileListPath == null) {
      return const Center(
        child: Text(
          "Load a filelist (.bin) to start.",
          style: TextStyle(color: Colors.white24),
        ),
      );
    }

    // Show file tree if loaded
    if (state.rootNode != null) {
      return _buildFileTreeView(state);
    }

    // Fallback to simple extract
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: CrystalPanel(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.download_for_offline, size: 64, color: Colors.cyan),
              const SizedBox(height: 16),
              const Text(
                "Extract All Files",
                style: TextStyle(fontSize: 24, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                "This will extract the entire archive to a directory of your choice.",
                style: TextStyle(color: Colors.white54),
              ),
              const SizedBox(height: 32),
              CrystalButton(
                onPressed: _extractAll,
                icon: Icons.download,
                label: "EXTRACT ALL",
                isPrimary: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileTreeView(WbtState state) {
    final notifier = ref.read(wbtProvider(_gameCode).notifier);

    return Column(
      children: [
        // Selection toolbar
        Container(
          color: Colors.black.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                "${state.selectedFileCount} files selected",
                style: const TextStyle(color: Colors.white70),
              ),
              const Spacer(),
              CrystalButton(
                onPressed: () => notifier.selectAll(),
                icon: Icons.select_all,
                label: "Select All",
              ),
              const SizedBox(width: 8),
              CrystalButton(
                onPressed: () => notifier.clearSelection(),
                icon: Icons.deselect,
                label: "Clear",
              ),
              const SizedBox(width: 16),
              CrystalButton(
                onPressed: _extractAll,
                icon: Icons.download,
                label: "Extract All",
              ),
              const SizedBox(width: 8),
              CrystalButton(
                onPressed: state.selectedIndices.isNotEmpty ? _extractSelected : null,
                icon: Icons.download_outlined,
                label: "Extract Selected",
                isPrimary: true,
              ),
            ],
          ),
        ),

        // File tree using CrystalFileBrowser
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: CrystalPanel(
              padding: const EdgeInsets.all(8),
              child: CrystalFileBrowser(
                nodes: _convertToFileNodes(state.rootNode!.children),
                onToggleExpand: (path) => notifier.toggleExpanded(path),
                onToggleSelect: (path) => notifier.toggleSelection(path),
                onExtractDirectory: _extractDirectory,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Converts WbtTreeNode list to CrystalFileNode list
  List<CrystalFileNode> _convertToFileNodes(List<WbtTreeNode> nodes) {
    return nodes.map((node) => CrystalFileNode(
      name: node.name,
      fullPath: node.fullPath,
      isDirectory: node.isDirectory,
      fileIndex: node.fileIndex,
      size: node.uncompressedSize,
      compressedSize: node.compressedSize,
      children: _convertToFileNodes(node.children),
      isExpanded: node.isExpanded,
      isSelected: node.isSelected,
    )).toList();
  }

  Widget _buildRepackView(WbtState state) {
    if (state.isProcessing) {
      return const Center(child: CrystalLoadingSpinner(label: 'Repacking...'));
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
