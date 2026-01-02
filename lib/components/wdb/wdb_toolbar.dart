import 'package:oracle_drive/components/widgets/crystal_button.dart';
import 'package:oracle_drive/components/widgets/crystal_popup_menu.dart';
import 'package:oracle_drive/components/widgets/crystal_text_field.dart';
import 'package:flutter/material.dart';

class WdbToolbar extends StatelessWidget {
  final VoidCallback onLoad;
  final VoidCallback? onNew;
  final VoidCallback? onBulkUpdate;
  final VoidCallback? onSaveWdb;
  final VoidCallback? onSaveJson;
  final String? currentPath;
  final ValueChanged<String>? onFilter;

  const WdbToolbar({
    super.key,
    required this.onLoad,
    this.onNew,
    this.onBulkUpdate,
    this.onSaveWdb,
    this.onSaveJson,
    this.currentPath,
    this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          CrystalButton(
            onPressed: onLoad,
            icon: Icons.table_chart,
            label: "Open WDB",
            isPrimary: true,
          ),
          if (currentPath != null) ...[
            const SizedBox(width: 8),
            CrystalButton(onPressed: onNew, icon: Icons.add, label: "New"),
            const SizedBox(width: 8),
            CrystalButton(
              onPressed: onBulkUpdate,
              icon: Icons.edit_note,
              label: "Bulk Update",
            ),
          ],
          const SizedBox(width: 8),
          CrystalPopupMenuButton<String>(
            enabled: onSaveWdb != null || onSaveJson != null,
            onSelected: (value) {
              if (value == 'wdb') {
                onSaveWdb?.call();
              } else if (value == 'json') {
                onSaveJson?.call();
              }
            },
            items: const [
              CrystalMenuItem(
                value: 'wdb',
                label: 'Save as .wdb',
                icon: Icons.save,
              ),
              CrystalMenuItem(
                value: 'json',
                label: 'Save as .json',
                icon: Icons.code,
              ),
            ],
            child: CrystalButton(
              onPressed: null,
              icon: Icons.save_alt,
              label: "Save...",
            ),
          ),
          if (currentPath != null) ...[
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                currentPath!,
                style: const TextStyle(color: Colors.white70),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 300,
              child: CrystalTextField(
                onChanged: onFilter,
                hintText: 'Filter...',
                prefixIcon: Icons.search,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
