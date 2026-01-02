import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:oracle_drive/components/widgets/crystal_button.dart';
import 'package:oracle_drive/components/widgets/crystal_file_browser.dart';
import 'package:oracle_drive/components/widgets/crystal_loading_spinner.dart';
import 'package:oracle_drive/components/widgets/crystal_panel.dart';
import 'package:oracle_drive/components/widgets/crystal_progress_bar.dart';
import 'package:oracle_drive/components/widgets/crystal_snackbar.dart';
import 'package:oracle_drive/components/widgets/crystal_tab_bar.dart';
import 'package:oracle_drive/models/app_game_code.dart';
import 'package:oracle_drive/providers/wbt_provider.dart';
import 'package:oracle_drive/providers/wpd_provider.dart';
import 'package:path/path.dart' as p;

/// Panel for archive operations (Extract/Repack) integrated into WPD screen
class WpdArchivePanel extends ConsumerStatefulWidget {
  final AppGameCode gameCode;

  const WpdArchivePanel({super.key, required this.gameCode});

  @override
  ConsumerState<WpdArchivePanel> createState() => _WpdArchivePanelState();
}

class _WpdArchivePanelState extends ConsumerState<WpdArchivePanel> {
  Future<String?> _pickContainerBin() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['bin'],
      dialogTitle: 'Select the content .bin (e.g. _white_img.bin)',
    );
    return result?.files.single.path;
  }

  Future<void> _extractAll() async {
    final notifier = ref.read(wpdProvider(widget.gameCode).notifier);
    final archive = ref.read(wpdProvider(widget.gameCode)).archive;

    String? binPath = archive.binPath ?? await _pickContainerBin();
    if (binPath == null) return;
    notifier.setArchiveBinPath(binPath);

    final outputDir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select output directory',
    );
    if (outputDir == null) return;

    try {
      await notifier.extractAllArchiveFiles(outputDir);
      if (mounted) {
        context.showSuccessSnackBar('Extraction complete to ${p.basename(outputDir)}');
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Extraction failed: $e');
      }
    }
  }

  Future<void> _extractSelected() async {
    final notifier = ref.read(wpdProvider(widget.gameCode).notifier);
    final archive = ref.read(wpdProvider(widget.gameCode)).archive;

    if (archive.selectedIndices.isEmpty) return;

    String? binPath = archive.binPath ?? await _pickContainerBin();
    if (binPath == null) return;
    notifier.setArchiveBinPath(binPath);

    final outputDir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select output directory',
    );
    if (outputDir == null) return;

    try {
      final count = await notifier.extractSelectedArchiveFiles(outputDir);
      if (mounted) {
        context.showSuccessSnackBar('Extracted $count files');
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Extraction failed: $e');
      }
    }
  }

  Future<void> _extractDirectory(String dirPath) async {
    final notifier = ref.read(wpdProvider(widget.gameCode).notifier);
    final archive = ref.read(wpdProvider(widget.gameCode)).archive;

    String? binPath = archive.binPath ?? await _pickContainerBin();
    if (binPath == null) return;
    notifier.setArchiveBinPath(binPath);

    final outputDir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select output directory',
    );
    if (outputDir == null) return;

    try {
      final count = await notifier.extractArchiveDirectory(dirPath, outputDir);
      if (mounted) {
        context.showSuccessSnackBar('Extracted $count files from $dirPath');
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Extraction failed: $e');
      }
    }
  }

  Future<void> _repackFiles() async {
    final notifier = ref.read(wpdProvider(widget.gameCode).notifier);
    final archive = ref.read(wpdProvider(widget.gameCode)).archive;

    String? binPath = archive.binPath ?? await _pickContainerBin();
    if (binPath == null) return;
    notifier.setArchiveBinPath(binPath);

    final sourceDir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select directory with modded files to inject',
    );
    if (sourceDir == null) return;

    try {
      await notifier.repackArchiveFiles(sourceDir);
      if (mounted) {
        context.showSuccessSnackBar('Repack complete. Backup created.');
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Repack failed: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wpdProvider(widget.gameCode));
    final archive = state.archive;

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // Header
          Container(
            color: Colors.black.withValues(alpha: 0.4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.archive, color: Colors.cyan, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    archive.fileListPath != null
                        ? '${p.basename(archive.fileListPath!)} (${archive.fileEntries.length} files)'
                        : 'Archive Mode',
                    style: const TextStyle(color: Colors.white70),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                CrystalButton(
                  onPressed: () {
                    ref.read(wpdProvider(widget.gameCode).notifier).exitArchiveMode();
                  },
                  icon: Icons.close,
                  label: 'Exit Archive',
                ),
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
                _buildExtractView(state, archive),
                _buildRepackView(state, archive),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtractView(WpdState state, ArchiveState archive) {
    if (state.processing.isProcessing && archive.extractionProgress > 0) {
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          constraints: const BoxConstraints(maxWidth: 600),
          child: CrystalProgressBar(
            value: archive.extractionProgress,
            label: "EXTRACTING FILES...",
            valueLabel: "${(archive.extractionProgress * 100).toInt()}%",
          ),
        ),
      );
    }

    if (state.processing.isProcessing || archive.isLoadingFileList) {
      return const Center(child: CrystalLoadingSpinner(label: 'Processing...'));
    }

    if (archive.rootNode != null) {
      return _buildFileTreeView(archive);
    }

    // Fallback - no tree yet
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

  Widget _buildFileTreeView(ArchiveState archive) {
    final notifier = ref.read(wpdProvider(widget.gameCode).notifier);

    return Column(
      children: [
        // Selection toolbar
        Container(
          color: Colors.black.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                "${archive.selectedFileCount} files selected",
                style: const TextStyle(color: Colors.white70),
              ),
              const Spacer(),
              CrystalButton(
                onPressed: () => notifier.selectAllArchiveFiles(),
                icon: Icons.select_all,
                label: "Select All",
              ),
              const SizedBox(width: 8),
              CrystalButton(
                onPressed: () => notifier.clearArchiveSelection(),
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
                onPressed: archive.selectedIndices.isNotEmpty ? _extractSelected : null,
                icon: Icons.download_outlined,
                label: "Extract Selected",
                isPrimary: true,
              ),
            ],
          ),
        ),

        // File tree
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: CrystalPanel(
              padding: const EdgeInsets.all(8),
              child: CrystalFileBrowser(
                nodes: _convertToFileNodes(archive.rootNode!.children),
                onToggleExpand: (path) => notifier.toggleArchiveExpanded(path),
                onToggleSelect: (path) => notifier.toggleArchiveSelection(path),
                onExtractDirectory: _extractDirectory,
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<CrystalFileNode> _convertToFileNodes(List<WbtTreeNode> nodes) {
    return nodes
        .map((node) => CrystalFileNode(
              name: node.name,
              fullPath: node.fullPath,
              isDirectory: node.isDirectory,
              fileIndex: node.fileIndex,
              size: node.uncompressedSize,
              compressedSize: node.compressedSize,
              children: _convertToFileNodes(node.children),
              isExpanded: node.isExpanded,
              isSelected: node.isSelected,
            ))
        .toList();
  }

  Widget _buildRepackView(WpdState state, ArchiveState archive) {
    if (state.processing.isProcessing) {
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
                const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.cyan),
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
                if (archive.repackSourceDir != null)
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
                            archive.repackSourceDir!,
                            style: const TextStyle(color: Colors.white70),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                CrystalButton(
                  onPressed: _repackFiles,
                  icon: Icons.upload_file,
                  label: "SELECT FOLDER & REPACK",
                  isPrimary: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
