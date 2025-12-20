import 'package:ff13_mod_resource/components/widgets/crystal_button.dart';
import 'package:ff13_mod_resource/models/app_game_code.dart';
import 'package:flutter/material.dart';

class ZtrActionButtons extends StatelessWidget {
  final AppGameCode selectedGame;
  final int stringCount;
  final VoidCallback onLoadZtrFile;
  final VoidCallback onDumpZtrFile;
  final VoidCallback onDumpTxtFile;
  final VoidCallback onResetDatabase;
  final VoidCallback onAddEntry; // New callback

  const ZtrActionButtons({
    super.key,
    required this.selectedGame,
    required this.stringCount,
    required this.onLoadZtrFile,
    required this.onDumpZtrFile,
    required this.onDumpTxtFile,
    required this.onResetDatabase,
    required this.onAddEntry, // Mark as required
  });

  @override
  Widget build(BuildContext context) {
    if (stringCount == 0) {
      // This block is now handled by ZtrScreen directly, but keeping it
      // here for completeness if logic changes later.
      return CrystalButton(
        icon: Icons.folder_open,
        label: "Load ZTR File",
        onPressed: onLoadZtrFile,
        isPrimary: true,
      );
    } else {
      return Column(
        children: [
          Text(
            "Loaded $stringCount strings for ${selectedGame.displayName}.",
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CrystalButton(
                icon: Icons.file_upload,
                label: "Load/Overwrite",
                onPressed: onLoadZtrFile,
              ),
              const SizedBox(width: 10),
              CrystalButton(
                icon: Icons.download,
                label: "Dump to ZTR",
                onPressed: onDumpZtrFile,
              ),
              const SizedBox(width: 10),
              CrystalButton(
                icon: Icons.text_snippet,
                label: "Dump to Text",
                onPressed: onDumpTxtFile,
              ),
              const SizedBox(width: 10),
              CrystalButton(
                icon: Icons.add_box, // New icon for adding
                label: "Add New Entry",
                onPressed: onAddEntry, // New button
              ),
              const SizedBox(width: 10),
              CrystalButton(
                icon: Icons.delete_forever, // Changed icon
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
