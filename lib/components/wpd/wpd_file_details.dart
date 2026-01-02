import 'dart:io';

import 'package:flutter/material.dart';
import 'package:oracle_drive/components/widgets/style.dart';
import 'package:oracle_drive/components/wpd/wpd_file_utils.dart';
import 'package:path/path.dart' as p;

/// File/directory details header for the WPD screen.
class WpdFileDetails extends StatelessWidget {
  final FileSystemEntity node;

  const WpdFileDetails({
    super.key,
    required this.node,
  });

  @override
  Widget build(BuildContext context) {
    final isDir = node is Directory;
    final name = p.basename(node.path);

    return Row(
      children: [
        Icon(
          isDir ? Icons.folder : WpdFileUtils.getFileIcon(name),
          size: 32,
          color: isDir ? Colors.cyan : WpdFileUtils.getFileColor(name),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(
                name,
                style: CrystalStyles.title,
              ),
              const SizedBox(height: 4),
              SelectableText(
                node.path,
                style: CrystalStyles.label,
              ),
              if (!isDir) ...[
                const SizedBox(height: 2),
                Text(
                  WpdFileUtils.getFileTypeDescription(name),
                  style: CrystalStyles.label.copyWith(
                    color: WpdFileUtils.getFileColor(name).withValues(alpha: 0.8),
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
