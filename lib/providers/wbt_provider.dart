import 'package:oracle_drive/models/app_game_code.dart';
import 'package:oracle_drive/src/third_party/wbtlib/wbt.dart';
import 'package:flutter_riverpod/legacy.dart';

class WbtState {
  final String? fileListPath;
  final String? binPath;
  final List<FileEntry>? fileEntries;
  final List<FileEntry> selectedFilesToExtract;
  final bool isProcessing;
  final double extractionProgress;
  final String? repackSourceDir;

  WbtState({
    this.fileListPath,
    this.binPath,
    this.fileEntries,
    this.selectedFilesToExtract = const [],
    this.isProcessing = false,
    this.extractionProgress = 0,
    this.repackSourceDir,
  });

  WbtState copyWith({
    String? fileListPath,
    String? binPath,
    List<FileEntry>? fileEntries,
    List<FileEntry>? selectedFilesToExtract,
    bool? isProcessing,
    double? extractionProgress,
    String? repackSourceDir,
  }) {
    return WbtState(
      fileListPath: fileListPath ?? this.fileListPath,
      binPath: binPath ?? this.binPath,
      fileEntries: fileEntries ?? this.fileEntries,
      selectedFilesToExtract:
          selectedFilesToExtract ?? this.selectedFilesToExtract,
      isProcessing: isProcessing ?? this.isProcessing,
      extractionProgress: extractionProgress ?? this.extractionProgress,
      repackSourceDir: repackSourceDir ?? this.repackSourceDir,
    );
  }
}

final wbtProvider =
    StateNotifierProvider.family<WbtNotifier, WbtState, AppGameCode>((
      ref,
      gameCode,
    ) {
      return WbtNotifier();
    });

class WbtNotifier extends StateNotifier<WbtState> {
  WbtNotifier() : super(WbtState());

  void setFileListPath(String? path) {
    state = WbtState(
      fileListPath: path,
      binPath: state.binPath,
      fileEntries: null,
      selectedFilesToExtract: [],
      isProcessing: false,
      extractionProgress: 0,
      repackSourceDir: state.repackSourceDir,
    );
  }

  void setBinPath(String? path) {
    state = state.copyWith(binPath: path);
  }

  void setFileEntries(List<FileEntry>? entries) {
    state = state.copyWith(fileEntries: entries);
  }

  void setSelectedFiles(List<FileEntry> selected) {
    state = state.copyWith(selectedFilesToExtract: selected);
  }

  void setProcessing(bool processing) {
    state = state.copyWith(isProcessing: processing);
  }

  void setExtractionProgress(double progress) {
    state = state.copyWith(extractionProgress: progress);
  }

  void setRepackSourceDir(String? dir) {
    state = state.copyWith(repackSourceDir: dir);
  }
}
