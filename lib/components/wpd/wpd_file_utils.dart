import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

/// Utility class for file-related helpers in the WPD screen.
class WpdFileUtils {
  WpdFileUtils._();

  /// Get the appropriate icon for a file based on its extension.
  static IconData getFileIcon(String name) {
    final ext = p.extension(name).toLowerCase();
    switch (ext) {
      case '.wpd':
        return Icons.folder_zip;
      case '.bin':
        return Icons.data_object;
      case '.imgb':
        return Icons.image;
      case '.clb':
        return Icons.lock;
      case '.class':
      case '.java':
        return Icons.code;
      case '.dds':
        return Icons.photo;
      case '.wdb':
        return Icons.table_chart;
      case '.ztr':
        return Icons.text_fields;
      case '.xgr':
        return Icons.data_object;
      default:
        return Icons.insert_drive_file;
    }
  }

  /// Get the appropriate color for a file based on its extension.
  static Color getFileColor(String name) {
    final ext = p.extension(name).toLowerCase();
    switch (ext) {
      case '.wpd':
        return Colors.orangeAccent;
      case '.bin':
        return Colors.blueGrey;
      case '.imgb':
        return Colors.pinkAccent;
      case '.clb':
        return Colors.redAccent;
      case '.class':
      case '.java':
        return Colors.greenAccent;
      case '.dds':
        return Colors.purpleAccent;
      case '.wdb':
        return Colors.cyanAccent;
      case '.ztr':
        return Colors.amberAccent;
      case '.xgr':
        return Colors.tealAccent;
      default:
        return Colors.white54;
    }
  }

  /// Get a human-readable file type description.
  static String getFileTypeDescription(String name) {
    final ext = p.extension(name).toLowerCase();
    switch (ext) {
      case '.wpd':
        return 'White Package Data';
      case '.bin':
        return 'Binary Archive';
      case '.imgb':
        return 'Image Bundle';
      case '.clb':
        return 'Compiled Lua Binary';
      case '.class':
        return 'Java Bytecode';
      case '.java':
        return 'Java Source';
      case '.dds':
        return 'DirectDraw Surface';
      case '.wdb':
        return 'White Database';
      case '.ztr':
        return 'ZTR Text Resource';
      case '.xgr':
        return 'XGR Archive';
      default:
        return 'File';
    }
  }
}
