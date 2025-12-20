import 'package:ff13_mod_resource/components/widgets/crystal_button.dart';
import 'package:ff13_mod_resource/components/widgets/crystal_text_field.dart';
import 'package:flutter/material.dart';

class WdbToolbar extends StatelessWidget {
  final VoidCallback onLoad;
  final VoidCallback? onNew;
  final VoidCallback? onSaveWdb;
  final VoidCallback? onSaveJson;
  final String? currentPath;
  final ValueChanged<String>? onFilter;

  const WdbToolbar({
    super.key,
    required this.onLoad,
    this.onNew,
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
            CrystalButton(
              onPressed: onNew,
              icon: Icons.add,
              label: "New",
            ),
          ],
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            enabled: onSaveWdb != null || onSaveJson != null,
            onSelected: (value) {
              if (value == 'wdb') {
                onSaveWdb?.call();
              } else if (value == 'json') {
                onSaveJson?.call();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'wdb',
                child: Row(
                  children: [
                    Icon(Icons.save, size: 18, color: Colors.white70),
                    SizedBox(width: 8),
                    Text('Save as .wdb'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'json',
                child: Row(
                  children: [
                    Icon(Icons.code, size: 18, color: Colors.white70),
                    SizedBox(width: 8),
                    Text('Save as .json'),
                  ],
                ),
              ),
            ],
            child: CrystalButton(
              onPressed: null, // Let PopupMenuButton handle the tap
              icon: Icons.save_alt,
              label: "Save...",
              // isPrimary: false,
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
