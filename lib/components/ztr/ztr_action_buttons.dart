import 'package:oracle_drive/components/widgets/crystal_button.dart';
import 'package:oracle_drive/models/app_game_code.dart';
import 'package:flutter/material.dart';

class ZtrActionButtons extends StatelessWidget {
  final AppGameCode selectedGame;
  final int stringCount;
  final VoidCallback onLoadZtrFile;
  final VoidCallback? onLoadZtrDirectory;
  final VoidCallback onDumpZtrFile;
  final VoidCallback onDumpTxtFile;
  final VoidCallback onResetDatabase;
  final VoidCallback onAddEntry;

  const ZtrActionButtons({
    super.key,
    required this.selectedGame,
    required this.stringCount,
    required this.onLoadZtrFile,
    this.onLoadZtrDirectory,
    required this.onDumpZtrFile,
    required this.onDumpTxtFile,
    required this.onResetDatabase,
    required this.onAddEntry,
  });

  @override
  Widget build(BuildContext context) {
    if (stringCount == 0) {
      // This block is now handled by ZtrScreen directly, but keeping it
      // here for completeness if logic changes later.
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CrystalButton(
            icon: Icons.insert_drive_file,
            label: "Load ZTR File",
            onPressed: onLoadZtrFile,
            isPrimary: true,
          ),
          if (onLoadZtrDirectory != null) ...[
            const SizedBox(width: 10),
            CrystalButton(
              icon: Icons.folder_open,
              label: "Load Directory",
              onPressed: onLoadZtrDirectory!,
            ),
          ],
        ],
      );
    } else {
      return Column(
        children: [
          Text(
            "Loaded $stringCount strings for ${selectedGame.displayName}.",
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              CrystalButton(
                icon: Icons.insert_drive_file,
                label: "Load File",
                onPressed: onLoadZtrFile,
              ),
              if (onLoadZtrDirectory != null)
                CrystalButton(
                  icon: Icons.folder_open,
                  label: "Load Directory",
                  onPressed: onLoadZtrDirectory!,
                ),
              CrystalButton(
                icon: Icons.download,
                label: "Dump to ZTR",
                onPressed: onDumpZtrFile,
              ),
              CrystalButton(
                icon: Icons.text_snippet,
                label: "Dump to Text",
                onPressed: onDumpTxtFile,
              ),
              CrystalButton(
                icon: Icons.add_box,
                label: "Add Entry",
                onPressed: onAddEntry,
              ),
              CrystalButton(
                icon: Icons.delete_forever,
                label: "Reset Database",
                onPressed: onResetDatabase,
              ),
            ],
          ),
        ],
      );
    }
  }
}
