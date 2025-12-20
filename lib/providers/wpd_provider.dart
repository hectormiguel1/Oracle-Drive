import 'dart:io';
import 'package:oracle_drive/models/app_game_code.dart';
import 'package:flutter_riverpod/legacy.dart';

class WpdState {
  final String? rootDirPath;
  final FileSystemEntity? selectedNode;

  WpdState({this.rootDirPath, this.selectedNode});

  WpdState copyWith({String? rootDirPath, FileSystemEntity? selectedNode}) {
    return WpdState(
      rootDirPath: rootDirPath ?? this.rootDirPath,
      selectedNode: selectedNode ?? this.selectedNode,
    );
  }
}

final wpdProvider =
    StateNotifierProvider.family<WpdNotifier, WpdState, AppGameCode>((
      ref,
      gameCode,
    ) {
      return WpdNotifier();
    });

class WpdNotifier extends StateNotifier<WpdState> {
  WpdNotifier() : super(WpdState());

  void setRootDirPath(String? path) {
    state = state.copyWith(rootDirPath: path, selectedNode: null);
  }

  void setSelectedNode(FileSystemEntity? node) {
    state = state.copyWith(selectedNode: node);
  }
}
