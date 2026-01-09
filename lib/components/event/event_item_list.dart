import 'package:fabula_nova_sdk/bridge_generated/modules/event/structs.dart'
    as event_sdk;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oracle_drive/providers/app_state_provider.dart';
import 'package:oracle_drive/providers/event_provider.dart';
import 'package:oracle_drive/src/services/app_database.dart';

class EventItemList extends ConsumerWidget {
  const EventItemList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(eventDataProvider);
    final selectedTab = ref.watch(eventSelectedTabProvider);
    final selectedItem = ref.watch(eventSelectedItemProvider);

    if (data == null) {
      return const Center(child: Text('No data'));
    }

    return switch (selectedTab) {
      0 => _buildInfoList(context, ref, data, selectedItem),
      1 => _buildActorList(context, ref, data.actors, selectedItem),
      2 => _buildBlockList(context, ref, data.blocks, selectedItem),
      3 => _buildExternalResourceList(context, ref, data.externalResources, selectedItem),
      4 => _buildResourceList(context, ref, data.resources, selectedItem),
      5 => _buildDialogueList(context, ref, data.dialogueEntries, selectedItem),
      6 => _buildSoundList(context, ref, data, selectedItem),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildInfoList(
    BuildContext context,
    WidgetRef ref,
    event_sdk.EventMetadata data,
    int? selectedIndex,
  ) {
    if (data.wpdRecords.isEmpty) {
      return _buildEmptyState('No WPD records');
    }

    return ListView.builder(
      itemCount: data.wpdRecords.length,
      itemBuilder: (context, index) {
        final record = data.wpdRecords[index];
        final isSelected = selectedIndex == index;
        final sizeStr = _formatSize(record.size);

        return _ListTile(
          isSelected: isSelected,
          onTap: () => ref.read(eventNotifierProvider).setSelectedItem(index),
          leading: _getRecordIcon(record.extension_),
          title: record.name,
          subtitle: '${record.extension_} • $sizeStr',
        );
      },
    );
  }

  Widget _buildExternalResourceList(
    BuildContext context,
    WidgetRef ref,
    List<event_sdk.ExternalResource> resources,
    int? selectedIndex,
  ) {
    if (resources.isEmpty) {
      return _buildEmptyState('No external resources');
    }

    return ListView.builder(
      itemCount: resources.length,
      itemBuilder: (context, index) {
        final resource = resources[index];
        final isSelected = selectedIndex == index;

        return _ListTile(
          isSelected: isSelected,
          onTap: () => ref.read(eventNotifierProvider).setSelectedItem(index),
          leading: _getCategoryIcon(resource.category),
          title: resource.name,
          subtitle: _getCategoryName(resource.category),
        );
      },
    );
  }

  Widget _buildSoundList(
    BuildContext context,
    WidgetRef ref,
    event_sdk.EventMetadata data,
    int? selectedIndex,
  ) {
    final blocks = data.soundBlocks;
    final refs = data.soundReferences;
    final totalCount = blocks.length + refs.length;

    if (totalCount == 0) {
      return _buildEmptyState('No sound data');
    }

    return ListView.builder(
      itemCount: totalCount,
      itemBuilder: (context, index) {
        final isSelected = selectedIndex == index;

        if (index < blocks.length) {
          // Sound block
          final sound = blocks[index];
          final duration = sound.durationSamples > 0
              ? '${sound.durationSeconds.toStringAsFixed(2)}s'
              : '';

          return _ListTile(
            isSelected: isSelected,
            onTap: () => ref.read(eventNotifierProvider).setSelectedItem(index),
            leading: const Icon(Icons.audiotrack, color: Colors.purple, size: 18),
            title: sound.name,
            subtitle: 'Block • $duration',
          );
        } else {
          // Sound reference
          final soundRef = refs[index - blocks.length];

          return _ListTile(
            isSelected: isSelected,
            onTap: () => ref.read(eventNotifierProvider).setSelectedItem(index),
            leading: _getSoundTypeIcon(soundRef.soundType),
            title: soundRef.soundId,
            subtitle: _getSoundTypeName(soundRef.soundType),
          );
        }
      },
    );
  }

  Widget _buildActorList(
    BuildContext context,
    WidgetRef ref,
    List<event_sdk.EventActor> actors,
    int? selectedIndex,
  ) {
    if (actors.isEmpty) {
      return _buildEmptyState('No actors');
    }

    return ListView.builder(
      itemCount: actors.length,
      itemBuilder: (context, index) {
        final actor = actors[index];
        final isSelected = selectedIndex == index;

        return _ListTile(
          isSelected: isSelected,
          onTap: () => ref.read(eventNotifierProvider).setSelectedItem(index),
          leading: _getActorIcon(actor.actorType),
          title: actor.name,
          subtitle: _getActorTypeDisplay(actor.actorType),
        );
      },
    );
  }

  Widget _buildBlockList(
    BuildContext context,
    WidgetRef ref,
    List<event_sdk.EventBlock> blocks,
    int? selectedIndex,
  ) {
    if (blocks.isEmpty) {
      return _buildEmptyState('No blocks');
    }

    return ListView.builder(
      itemCount: blocks.length,
      itemBuilder: (context, index) {
        final block = blocks[index];
        final isSelected = selectedIndex == index;
        final duration = block.durationFrames > 0
            ? '${block.durationSeconds.toStringAsFixed(2)}s'
            : '';

        return _ListTile(
          isSelected: isSelected,
          onTap: () => ref.read(eventNotifierProvider).setSelectedItem(index),
          leading: const Icon(Icons.view_timeline, color: Colors.blue, size: 18),
          title: block.name,
          subtitle: duration,
        );
      },
    );
  }

  Widget _buildResourceList(
    BuildContext context,
    WidgetRef ref,
    List<event_sdk.EventResource> resources,
    int? selectedIndex,
  ) {
    if (resources.isEmpty) {
      return _buildEmptyState('No resources');
    }

    return ListView.builder(
      itemCount: resources.length,
      itemBuilder: (context, index) {
        final resource = resources[index];
        final isSelected = selectedIndex == index;

        return _ListTile(
          isSelected: isSelected,
          onTap: () => ref.read(eventNotifierProvider).setSelectedItem(index),
          leading: _getResourceIcon(resource.resourceType),
          title: resource.name,
          subtitle: resource.resourceType,
        );
      },
    );
  }

  Widget _buildDialogueList(
    BuildContext context,
    WidgetRef ref,
    List<event_sdk.DialogueEntry> dialogues,
    int? selectedIndex,
  ) {
    if (dialogues.isEmpty) {
      return _buildEmptyState('No dialogue entries');
    }

    final gameCode = ref.watch(selectedGameProvider);

    // Try to get ZTR resolver
    String? Function(String) resolveZtr = (key) => null;
    try {
      final repo = AppDatabase.instance.getRepositoryForGame(gameCode);
      resolveZtr = repo.resolveStringId;
    } catch (_) {
      // Database not initialized
    }

    return ListView.builder(
      itemCount: dialogues.length,
      itemBuilder: (context, index) {
        final dialogue = dialogues[index];
        final isSelected = selectedIndex == index;

        // Try to resolve text for subtitle
        final resolvedText = resolveZtr(dialogue.ztrKey);
        final subtitle = resolvedText ?? dialogue.ztrKey;

        return _ListTile(
          isSelected: isSelected,
          onTap: () => ref.read(eventNotifierProvider).setSelectedItem(index),
          leading: Icon(
            Icons.chat_bubble_outline,
            color: resolvedText != null ? Colors.green : Colors.green.shade700,
            size: 18,
          ),
          title: dialogue.recordName,
          subtitle: subtitle,
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(color: Colors.white38),
      ),
    );
  }

  Widget _getActorIcon(event_sdk.ActorType actorType) {
    return switch (actorType) {
      event_sdk.ActorType_Camera() =>
        const Icon(Icons.videocam, color: Colors.cyan, size: 18),
      event_sdk.ActorType_Sound() =>
        const Icon(Icons.volume_up, color: Colors.orange, size: 18),
      event_sdk.ActorType_Effect() =>
        const Icon(Icons.auto_awesome, color: Colors.pink, size: 18),
      event_sdk.ActorType_Bgm() =>
        const Icon(Icons.music_note, color: Colors.purple, size: 18),
      event_sdk.ActorType_Proxy() =>
        const Icon(Icons.person_outline, color: Colors.grey, size: 18),
      event_sdk.ActorType_System() =>
        const Icon(Icons.settings, color: Colors.grey, size: 18),
      event_sdk.ActorType_Character() =>
        const Icon(Icons.person, color: Colors.amber, size: 18),
      event_sdk.ActorType_Unknown() =>
        const Icon(Icons.help_outline, color: Colors.grey, size: 18),
    };
  }

  String _getActorTypeDisplay(event_sdk.ActorType actorType) {
    return switch (actorType) {
      event_sdk.ActorType_Camera() => 'Camera',
      event_sdk.ActorType_Sound() => 'Sound',
      event_sdk.ActorType_Effect() => 'Effect',
      event_sdk.ActorType_Bgm() => 'BGM',
      event_sdk.ActorType_Proxy() => 'Proxy',
      event_sdk.ActorType_System() => 'System',
      event_sdk.ActorType_Character(:final field0) => 'Character ($field0)',
      event_sdk.ActorType_Unknown(:final field0) => 'Unknown ($field0)',
    };
  }

  Widget _getResourceIcon(String resourceType) {
    return switch (resourceType.toLowerCase()) {
      'camera' => const Icon(Icons.videocam, color: Colors.cyan, size: 18),
      'facial/animation' => const Icon(Icons.face, color: Colors.orange, size: 18),
      'world/environment' => const Icon(Icons.public, color: Colors.green, size: 18),
      _ => const Icon(Icons.inventory_2, color: Colors.grey, size: 18),
    };
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  Widget _getRecordIcon(String extension) {
    return switch (extension.toLowerCase()) {
      'scb' => const Icon(Icons.schedule, color: Colors.amber, size: 18),
      'srb' => const Icon(Icons.music_note, color: Colors.purple, size: 18),
      'txt' => const Icon(Icons.text_snippet, color: Colors.green, size: 18),
      'mcb' => const Icon(Icons.directions_run, color: Colors.orange, size: 18),
      'ccb' => const Icon(Icons.videocam, color: Colors.cyan, size: 18),
      _ => const Icon(Icons.insert_drive_file, color: Colors.grey, size: 18),
    };
  }

  Widget _getCategoryIcon(event_sdk.ResourceCategory category) {
    return switch (category) {
      event_sdk.ResourceCategory.event =>
        const Icon(Icons.event, color: Colors.blue, size: 18),
      event_sdk.ResourceCategory.camera =>
        const Icon(Icons.videocam, color: Colors.cyan, size: 18),
      event_sdk.ResourceCategory.world =>
        const Icon(Icons.public, color: Colors.green, size: 18),
      event_sdk.ResourceCategory.facial =>
        const Icon(Icons.face, color: Colors.orange, size: 18),
      event_sdk.ResourceCategory.normal =>
        const Icon(Icons.directions_run, color: Colors.teal, size: 18),
      event_sdk.ResourceCategory.block =>
        const Icon(Icons.view_module, color: Colors.indigo, size: 18),
      event_sdk.ResourceCategory.cutsceneCamera =>
        const Icon(Icons.movie, color: Colors.amber, size: 18),
      event_sdk.ResourceCategory.unknown =>
        const Icon(Icons.help_outline, color: Colors.grey, size: 18),
    };
  }

  String _getCategoryName(event_sdk.ResourceCategory category) {
    return switch (category) {
      event_sdk.ResourceCategory.event => 'Event',
      event_sdk.ResourceCategory.camera => 'Camera',
      event_sdk.ResourceCategory.world => 'World',
      event_sdk.ResourceCategory.facial => 'Facial',
      event_sdk.ResourceCategory.normal => 'Normal/Animation',
      event_sdk.ResourceCategory.block => 'Block',
      event_sdk.ResourceCategory.cutsceneCamera => 'Cutscene Camera',
      event_sdk.ResourceCategory.unknown => 'Unknown',
    };
  }

  Widget _getSoundTypeIcon(event_sdk.SoundType soundType) {
    return switch (soundType) {
      event_sdk.SoundType.music =>
        const Icon(Icons.library_music, color: Colors.purple, size: 18),
      event_sdk.SoundType.ambient =>
        const Icon(Icons.surround_sound, color: Colors.teal, size: 18),
      event_sdk.SoundType.voice =>
        const Icon(Icons.record_voice_over, color: Colors.green, size: 18),
      event_sdk.SoundType.soundEffect =>
        const Icon(Icons.speaker, color: Colors.orange, size: 18),
      event_sdk.SoundType.unknown =>
        const Icon(Icons.volume_up, color: Colors.grey, size: 18),
    };
  }

  String _getSoundTypeName(event_sdk.SoundType soundType) {
    return switch (soundType) {
      event_sdk.SoundType.music => 'Music',
      event_sdk.SoundType.ambient => 'Ambient',
      event_sdk.SoundType.voice => 'Voice',
      event_sdk.SoundType.soundEffect => 'Sound Effect',
      event_sdk.SoundType.unknown => 'Unknown',
    };
  }
}

class _ListTile extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final Widget leading;
  final String title;
  final String subtitle;

  const _ListTile({
    required this.isSelected,
    required this.onTap,
    required this.leading,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber.withOpacity(0.15) : null,
          border: Border(
            left: BorderSide(
              color: isSelected ? Colors.amber : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
