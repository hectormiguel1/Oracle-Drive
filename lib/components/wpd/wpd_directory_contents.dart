import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oracle_drive/components/wpd/wpd_file_utils.dart';
import 'package:oracle_drive/models/app_game_code.dart';
import 'package:oracle_drive/providers/wpd_provider.dart';
import 'package:path/path.dart' as p;

/// Directory contents list for the WPD screen.
class WpdDirectoryContents extends ConsumerWidget {
  final Directory directory;
  final AppGameCode gameCode;
  final VoidCallback? onItemSelected;

  const WpdDirectoryContents({
    super.key,
    required this.directory,
    required this.gameCode,
    this.onItemSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    try {
      final list = directory.listSync()
        ..sort((a, b) {
          final aIsDir = a is Directory;
          final bIsDir = b is Directory;
          if (aIsDir && !bIsDir) return -1;
          if (!aIsDir && bIsDir) return 1;
          return a.path.compareTo(b.path);
        });

      if (list.isEmpty) {
        return const Center(
          child: Text(
            "Empty Directory",
            style: TextStyle(color: Colors.white24),
          ),
        );
      }

      return ListView.builder(
        itemCount: list.length,
        itemBuilder: (context, index) {
          final item = list[index];
          final itemName = p.basename(item.path);
          final itemIsDir = item is Directory;

          return ListTile(
            leading: Icon(
              itemIsDir ? Icons.folder : WpdFileUtils.getFileIcon(itemName),
              color: itemIsDir ? Colors.cyan : WpdFileUtils.getFileColor(itemName),
            ),
            title: Text(
              itemName,
              style: const TextStyle(color: Colors.white70),
            ),
            dense: true,
            onTap: () {
              ref.read(wpdProvider(gameCode).notifier).setSelectedNode(item);
              onItemSelected?.call();
            },
          );
        },
      );
    } catch (e) {
      return Center(
        child: Text(
          "Error reading directory: $e",
          style: const TextStyle(color: Colors.redAccent),
        ),
      );
    }
  }
}
