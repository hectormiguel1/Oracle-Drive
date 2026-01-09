import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oracle_drive/providers/vfx_provider.dart';

/// List of VFX items for the current tab.
class VfxItemList extends ConsumerWidget {
  const VfxItemList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(vfxDataProvider);
    final tab = ref.watch(vfxSelectedTabProvider);
    final selectedIndex = ref.watch(vfxSelectedItemProvider);

    if (data == null) {
      return const Center(
        child: Text(
          'No VFX loaded',
          style: TextStyle(color: Colors.white38),
        ),
      );
    }

    final List<_VfxItem> items;
    switch (tab) {
      case 0:
        items = data.textures
            .map((t) => _VfxItem(
                  name: t.name,
                  subtitle: '${t.width}x${t.height} ${t.formatName}',
                  icon: Icons.image_outlined,
                ))
            .toList();
        break;
      case 1:
        items = data.models
            .map((m) => _VfxItem(
                  name: m.name,
                  subtitle: m.vertexCount != null
                      ? '${m.vertexCount!} verts'
                      : _formatBytes(m.dataSize),
                  icon: Icons.view_in_ar_outlined,
                ))
            .toList();
        break;
      case 2:
        items = data.animations
            .map((a) => _VfxItem(
                  name: a.name,
                  subtitle: a.durationFrames != null
                      ? '${a.durationFrames!} frames'
                      : _formatBytes(a.dataSize),
                  icon: Icons.animation_outlined,
                ))
            .toList();
        break;
      case 3:
        items = data.effects
            .map((e) => _VfxItem(
                  name: e.name,
                  subtitle: '${e.controllerPaths.length} controllers',
                  icon: Icons.auto_awesome_outlined,
                ))
            .toList();
        break;
      default:
        items = [];
    }

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_off_outlined, size: 48, color: Colors.white24),
            const SizedBox(height: 8),
            Text(
              'No items',
              style: TextStyle(color: Colors.white38),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = selectedIndex == index;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              ref.read(vfxNotifierProvider).setSelectedItem(index);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.cyan.withValues(alpha: 0.15) : null,
                border: Border(
                  left: BorderSide(
                    color: isSelected ? Colors.cyan : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    item.icon,
                    size: 18,
                    color: isSelected ? Colors.cyan : Colors.white54,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontSize: 13,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          item.subtitle,
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _VfxItem {
  final String name;
  final String subtitle;
  final IconData icon;

  const _VfxItem({
    required this.name,
    required this.subtitle,
    required this.icon,
  });
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
}
