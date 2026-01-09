import 'package:fabula_nova_sdk/bridge_generated/modules/event/structs.dart'
    as event_sdk;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oracle_drive/components/widgets/style.dart';
import 'package:oracle_drive/providers/app_state_provider.dart';
import 'package:oracle_drive/providers/event_provider.dart';
import 'package:oracle_drive/src/services/app_database.dart';
import 'package:oracle_drive/src/utils/ztr_text_renderer.dart';

class EventDetailPanel extends ConsumerWidget {
  const EventDetailPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(eventSelectedTabProvider);
    final selectedItem = ref.watch(eventSelectedItemProvider);
    final data = ref.watch(eventDataProvider);

    // Tab 0 (Info) shows file info when no item selected
    if (selectedTab == 0 && selectedItem == null && data != null) {
      return _FileInfoView(data);
    }

    if (selectedItem == null) {
      return _buildEmptyState();
    }

    return switch (selectedTab) {
      0 => _WpdRecordDetailView(ref.watch(eventSelectedWpdRecordProvider)),
      1 => _ActorDetailView(ref.watch(eventSelectedActorProvider)),
      2 => _BlockDetailView(ref.watch(eventSelectedBlockProvider)),
      3 => _ExternalResourceDetailView(ref.watch(eventSelectedExternalResourceProvider)),
      4 => _ResourceDetailView(ref.watch(eventSelectedResourceProvider)),
      5 => _DialogueDetailView(ref.watch(eventSelectedDialogueProvider)),
      6 => _SoundDetailView(
            ref.watch(eventSelectedSoundBlockProvider),
            ref.watch(eventSelectedSoundReferenceProvider),
          ),
      _ => _buildEmptyState(),
    };
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.touch_app, size: 48, color: Colors.white10),
          const SizedBox(height: 16),
          const Text(
            'Select an item to view details',
            style: TextStyle(color: Colors.white24, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

/// Shows file-level info including schedule header and section counts.
class _FileInfoView extends StatelessWidget {
  final event_sdk.EventMetadata data;

  const _FileInfoView(this.data);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailHeader(
            icon: Icons.info_outline,
            iconColor: Colors.blue,
            title: data.name.isNotEmpty ? data.name : 'Event File',
            subtitle: 'Event Information',
          ),
          const SizedBox(height: 24),

          // Schedule Header
          if (data.scheduleHeader != null) ...[
            _DetailSection(
              title: 'SCHEDULE HEADER',
              children: [
                _DetailRow('Magic', data.scheduleHeader!.magic),
                _DetailRow('Version', data.scheduleHeader!.version.toString()),
                _DetailRow('Header Size', '0x${data.scheduleHeader!.headerSize.toRadixString(16).toUpperCase()}'),
                _DetailRow('Data Size', '0x${data.scheduleHeader!.dataSize.toRadixString(16).toUpperCase()}'),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Section Counts
          _DetailSection(
            title: 'SECTION COUNTS',
            children: [
              _SectionCountRow('@CRST', data.sectionCounts.crst, 'Resource Structure Table'),
              _SectionCountRow('@CRES', data.sectionCounts.cres, 'Resources'),
              _SectionCountRow('@CATT', data.sectionCounts.catt, 'Attributes'),
              _SectionCountRow('@CCPT', data.sectionCounts.ccpt, 'Control Points'),
              _SectionCountRow('@CACT', data.sectionCounts.cact, 'Actors'),
              _SectionCountRow('@CDPT', data.sectionCounts.cdpt, 'Data Points'),
              _SectionCountRow('@CTRK', data.sectionCounts.ctrk, 'Tracks'),
              _SectionCountRow('@CBKT', data.sectionCounts.cbkt, 'Block Table'),
              _SectionCountRow('@CBLK', data.sectionCounts.cblk, 'Blocks'),
            ],
          ),
          const SizedBox(height: 16),

          // File Info
          _DetailSection(
            title: 'FILE INFO',
            children: [
              _DetailRow('File Size', _formatSize(data.fileSize.toInt())),
              _DetailRow('Records', data.recordCount.toString()),
              _DetailRow('Actors', data.actors.length.toString()),
              _DetailRow('Blocks', data.blocks.length.toString()),
              _DetailRow('External Resources', data.externalResources.length.toString()),
              _DetailRow('Dialogue Entries', data.dialogueEntries.length.toString()),
              _DetailRow('Sound Blocks', data.soundBlocks.length.toString()),
              _DetailRow('Sound References', data.soundReferences.length.toString()),
            ],
          ),
        ],
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

class _SectionCountRow extends StatelessWidget {
  final String tag;
  final int count;
  final String description;

  const _SectionCountRow(this.tag, this.count, this.description);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              tag,
              style: TextStyle(
                color: count > 0 ? Colors.cyan : Colors.white38,
                fontSize: 12,
                fontFamily: 'monospace',
                fontWeight: count > 0 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              count.toString(),
              style: TextStyle(
                color: count > 0 ? Colors.white : Colors.white38,
                fontSize: 12,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _WpdRecordDetailView extends StatelessWidget {
  final event_sdk.WpdRecordInfo? record;

  const _WpdRecordDetailView(this.record);

  @override
  Widget build(BuildContext context) {
    if (record == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailHeader(
            icon: Icons.insert_drive_file,
            iconColor: Colors.blue,
            title: record!.name,
            subtitle: 'WPD Record',
          ),
          const SizedBox(height: 24),
          _DetailSection(
            title: 'PROPERTIES',
            children: [
              _DetailRow('Extension', record!.extension_),
              _DetailRow('Offset', '0x${record!.offset.toRadixString(16).toUpperCase()}'),
              _DetailRow('Size', '${record!.size} bytes (${_formatSize(record!.size)})'),
            ],
          ),
        ],
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

class _ExternalResourceDetailView extends StatelessWidget {
  final event_sdk.ExternalResource? resource;

  const _ExternalResourceDetailView(this.resource);

  @override
  Widget build(BuildContext context) {
    if (resource == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailHeader(
            icon: Icons.link,
            iconColor: Colors.teal,
            title: resource!.name,
            subtitle: 'External Resource',
          ),
          const SizedBox(height: 24),
          _DetailSection(
            title: 'PROPERTIES',
            children: [
              _DetailRow('Category', _getCategoryName(resource!.category)),
              _DetailRowCopyable('Hash', resource!.hash),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.teal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.teal.shade300, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This hash links to an external asset file in the DataSet or elsewhere.',
                    style: TextStyle(color: Colors.teal.shade200, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryName(event_sdk.ResourceCategory category) {
    return switch (category) {
      event_sdk.ResourceCategory.event => 'Event',
      event_sdk.ResourceCategory.camera => 'Camera Animation',
      event_sdk.ResourceCategory.world => 'World/Environment',
      event_sdk.ResourceCategory.facial => 'Facial Animation',
      event_sdk.ResourceCategory.normal => 'Normal/Generic Animation',
      event_sdk.ResourceCategory.block => 'Block Animation',
      event_sdk.ResourceCategory.cutsceneCamera => 'Cutscene Camera',
      event_sdk.ResourceCategory.unknown => 'Unknown',
    };
  }
}

class _SoundDetailView extends StatelessWidget {
  final event_sdk.SoundBlock? soundBlock;
  final event_sdk.SoundReference? soundRef;

  const _SoundDetailView(this.soundBlock, this.soundRef);

  @override
  Widget build(BuildContext context) {
    if (soundBlock != null) {
      return _SoundBlockDetailView(soundBlock);
    }
    if (soundRef != null) {
      return _SoundReferenceDetailView(soundRef);
    }
    return const SizedBox.shrink();
  }
}

class _SoundReferenceDetailView extends StatelessWidget {
  final event_sdk.SoundReference? soundRef;

  const _SoundReferenceDetailView(this.soundRef);

  @override
  Widget build(BuildContext context) {
    if (soundRef == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailHeader(
            icon: _getSoundTypeIcon(soundRef!.soundType),
            iconColor: _getSoundTypeColor(soundRef!.soundType),
            title: soundRef!.soundId,
            subtitle: 'Sound Reference',
          ),
          const SizedBox(height: 24),
          _DetailSection(
            title: 'PROPERTIES',
            children: [
              _DetailRow('Type', _getSoundTypeName(soundRef!.soundType)),
              _DetailRow('Block', soundRef!.blockName),
              _DetailRowCopyable('Sound ID', soundRef!.soundId),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getSoundTypeIcon(event_sdk.SoundType soundType) {
    return switch (soundType) {
      event_sdk.SoundType.music => Icons.library_music,
      event_sdk.SoundType.ambient => Icons.surround_sound,
      event_sdk.SoundType.voice => Icons.record_voice_over,
      event_sdk.SoundType.soundEffect => Icons.speaker,
      event_sdk.SoundType.unknown => Icons.volume_up,
    };
  }

  Color _getSoundTypeColor(event_sdk.SoundType soundType) {
    return switch (soundType) {
      event_sdk.SoundType.music => Colors.purple,
      event_sdk.SoundType.ambient => Colors.teal,
      event_sdk.SoundType.voice => Colors.green,
      event_sdk.SoundType.soundEffect => Colors.orange,
      event_sdk.SoundType.unknown => Colors.grey,
    };
  }

  String _getSoundTypeName(event_sdk.SoundType soundType) {
    return switch (soundType) {
      event_sdk.SoundType.music => 'Background Music',
      event_sdk.SoundType.ambient => 'Ambient Sound',
      event_sdk.SoundType.voice => 'Voice/Dialogue',
      event_sdk.SoundType.soundEffect => 'Sound Effect',
      event_sdk.SoundType.unknown => 'Unknown',
    };
  }
}

class _ActorDetailView extends StatelessWidget {
  final event_sdk.EventActor? actor;

  const _ActorDetailView(this.actor);

  @override
  Widget build(BuildContext context) {
    if (actor == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailHeader(
            icon: Icons.person,
            iconColor: Colors.amber,
            title: actor!.name,
            subtitle: 'Actor',
          ),
          const SizedBox(height: 24),
          _DetailSection(
            title: 'PROPERTIES',
            children: [
              _DetailRow('Type', _getActorTypeString(actor!.actorType)),
              _DetailRow('Index', actor!.index.toString()),
              _DetailRow('Flags', '0x${actor!.flags.toRadixString(16).toUpperCase()}'),
            ],
          ),
        ],
      ),
    );
  }

  String _getActorTypeString(event_sdk.ActorType actorType) {
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
}

class _BlockDetailView extends StatelessWidget {
  final event_sdk.EventBlock? block;

  const _BlockDetailView(this.block);

  @override
  Widget build(BuildContext context) {
    if (block == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailHeader(
            icon: Icons.view_timeline,
            iconColor: Colors.blue,
            title: block!.name,
            subtitle: 'Execution Block',
          ),
          const SizedBox(height: 24),
          _DetailSection(
            title: 'TIMING',
            children: [
              _DetailRow('Block ID', block!.id.toString()),
              _DetailRow('Duration (frames)', '${block!.durationFrames} frames'),
              _DetailRow('Duration (seconds)', '${block!.durationSeconds.toStringAsFixed(3)}s'),
              _DetailRow('Frame Rate', '30 fps (assumed)'),
              _DetailRow('Track Count', block!.trackCount.toString()),
            ],
          ),
          if (block!.tracks.isNotEmpty) ...[
            const SizedBox(height: 16),
            _DetailSection(
              title: 'TRACKS (${block!.tracks.length})',
              children: [
                ...block!.tracks.take(20).map((track) => _TrackRow(track)),
                if (block!.tracks.length > 20)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '... and ${block!.tracks.length - 20} more tracks',
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TrackRow extends StatelessWidget {
  final event_sdk.BlockTrack track;

  const _TrackRow(this.track);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _getTrackColor(track.trackType).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${track.index}',
              style: TextStyle(
                color: _getTrackColor(track.trackType),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _getTrackTypeName(track.trackType),
                      style: TextStyle(
                        color: _getTrackColor(track.trackType),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '0x${track.typeCode.toRadixString(16).toUpperCase().padLeft(4, '0')}',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                if (track.reference != null)
                  Text(
                    track.reference!,
                    style: const TextStyle(color: Colors.cyan, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (track.floatValues.isNotEmpty)
                  Text(
                    track.floatValues.take(4).map((f) => f.toStringAsFixed(2)).join(', '),
                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                  ),
              ],
            ),
          ),
          Text(
            '${track.size}B',
            style: const TextStyle(color: Colors.white24, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Color _getTrackColor(event_sdk.TrackType trackType) {
    return switch (trackType) {
      event_sdk.TrackType_MotionSet() => Colors.orange,
      event_sdk.TrackType_CharacterSet() => Colors.amber,
      event_sdk.TrackType_Camera() => Colors.cyan,
      event_sdk.TrackType_Sound() => Colors.purple,
      event_sdk.TrackType_MusicBus() => Colors.pink,
      event_sdk.TrackType_Dialogue() => Colors.green,
      event_sdk.TrackType_Effect() => Colors.red,
      event_sdk.TrackType_EventDef() => Colors.blue,
      event_sdk.TrackType_ActorControl() => Colors.grey,
      event_sdk.TrackType_Unknown() => Colors.grey,
    };
  }

  String _getTrackTypeName(event_sdk.TrackType trackType) {
    return switch (trackType) {
      event_sdk.TrackType_MotionSet() => 'Motion',
      event_sdk.TrackType_CharacterSet() => 'CharSet',
      event_sdk.TrackType_Camera() => 'Camera',
      event_sdk.TrackType_Sound() => 'Sound',
      event_sdk.TrackType_MusicBus() => 'Music',
      event_sdk.TrackType_Dialogue() => 'Dialogue',
      event_sdk.TrackType_Effect() => 'Effect',
      event_sdk.TrackType_EventDef() => 'Event',
      event_sdk.TrackType_ActorControl() => 'Actor',
      event_sdk.TrackType_Unknown() => 'Unknown',
    };
  }
}

class _ResourceDetailView extends StatelessWidget {
  final event_sdk.EventResource? resource;

  const _ResourceDetailView(this.resource);

  @override
  Widget build(BuildContext context) {
    if (resource == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailHeader(
            icon: Icons.inventory_2,
            iconColor: Colors.teal,
            title: resource!.name,
            subtitle: 'Resource Reference',
          ),
          const SizedBox(height: 24),
          _DetailSection(
            title: 'PROPERTIES',
            children: [
              _DetailRow('Type', resource!.resourceType),
              if (resource!.externalHash != null)
                _DetailRowCopyable('External Hash', resource!.externalHash!),
            ],
          ),
        ],
      ),
    );
  }
}

class _DialogueDetailView extends ConsumerWidget {
  final event_sdk.DialogueEntry? dialogue;

  const _DialogueDetailView(this.dialogue);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (dialogue == null) return const SizedBox.shrink();

    final gameCode = ref.watch(selectedGameProvider);

    // Try to resolve the ZTR key to actual text
    String? resolvedText;
    try {
      final repo = AppDatabase.instance.getRepositoryForGame(gameCode);
      resolvedText = repo.resolveStringId(dialogue!.ztrKey);
    } catch (_) {
      // Database not initialized or error - leave as null
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailHeader(
            icon: Icons.chat_bubble_outline,
            iconColor: Colors.green,
            title: dialogue!.recordName,
            subtitle: 'Dialogue Entry',
          ),
          const SizedBox(height: 24),
          _DetailSection(
            title: 'ZTR LOOKUP',
            children: [
              _DetailRowCopyable('ZTR Key', dialogue!.ztrKey),
            ],
          ),
          if (resolvedText != null) ...[
            const SizedBox(height: 16),
            _DetailSection(
              title: 'RESOLVED TEXT',
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: ZtrTextRenderer.render(
                    resolvedText,
                    gameCode,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber.shade300, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'ZTR database not loaded or key not found. '
                      'Load ZTR files in the ZTR screen to resolve dialogue text.',
                      style: TextStyle(color: Colors.amber.shade200, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (dialogue!.rawContent.isNotEmpty) ...[
            const SizedBox(height: 16),
            _DetailSection(
              title: 'RAW CONTENT',
              children: [
                _DetailRow('Value', dialogue!.rawContent),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SoundBlockDetailView extends StatelessWidget {
  final event_sdk.SoundBlock? soundBlock;

  const _SoundBlockDetailView(this.soundBlock);

  @override
  Widget build(BuildContext context) {
    if (soundBlock == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailHeader(
            icon: Icons.audiotrack,
            iconColor: Colors.purple,
            title: soundBlock!.name,
            subtitle: 'Sound Block',
          ),
          const SizedBox(height: 24),
          _DetailSection(
            title: 'AUDIO INFO',
            children: [
              _DetailRow('Duration (samples)', '${soundBlock!.durationSamples} samples'),
              _DetailRow('Duration (seconds)', '${soundBlock!.durationSeconds.toStringAsFixed(3)}s'),
              _DetailRow('Sample Rate', '44100 Hz (assumed)'),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Shared Components
// ============================================================

class _DetailHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _DetailHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: CrystalStyles.title.copyWith(fontSize: 18),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DetailSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: CrystalStyles.sectionHeader,
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRowCopyable extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRowCopyable(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: SelectableText(
                    value,
                    style: const TextStyle(
                      color: Colors.cyan,
                      fontSize: 13,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 16),
                  color: Colors.white38,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Copy to clipboard',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Copied: $value'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
