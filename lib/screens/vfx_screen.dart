import 'dart:io';

import 'package:fabula_nova_sdk/bridge_generated/modules/vfx/structs.dart'
    as vfx_sdk;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oracle_drive/components/vfx/vfx_detail_panel.dart';
import 'package:oracle_drive/components/vfx/vfx_item_list.dart';
import 'package:oracle_drive/components/widgets/crystal_button.dart';
import 'package:oracle_drive/components/widgets/crystal_divider.dart';
import 'package:oracle_drive/components/widgets/crystal_snackbar.dart';
import 'package:oracle_drive/components/widgets/style.dart';
import 'package:oracle_drive/providers/vfx_provider.dart';
import 'package:path/path.dart' as p;

class VfxScreen extends ConsumerStatefulWidget {
  const VfxScreen({super.key});

  @override
  ConsumerState<VfxScreen> createState() => _VfxScreenState();
}

class _VfxScreenState extends ConsumerState<VfxScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      ref.read(vfxNotifierProvider).setSelectedTab(_tabController.index);
    }
  }

  Future<void> _pickVfxFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xfv'],
      dialogTitle: 'Select VFX File (.xfv)',
    );

    if (result != null && result.files.single.path != null) {
      await ref.read(vfxNotifierProvider).loadVfx(result.files.single.path!);
    }
  }

  Future<void> _extractTextures() async {
    final path = ref.read(vfxPathProvider);
    if (path == null) return;

    final outputDir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Output Directory for Textures',
    );

    if (outputDir != null) {
      final extracted = await ref
          .read(vfxNotifierProvider)
          .extractTextures(path, outputDir);

      if (mounted) {
        if (extracted.isNotEmpty) {
          context.showSuccessSnackBar('Extracted ${extracted.length} textures');
        } else {
          context.showErrorSnackBar('No textures extracted');
        }
      }
    }
  }

  Future<void> _exportJson() async {
    final path = ref.read(vfxPathProvider);
    if (path == null) return;

    final json = await ref.read(vfxNotifierProvider).exportToJson(path);
    if (json != null) {
      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save VFX JSON',
        fileName: '${p.basenameWithoutExtension(path)}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (outputPath != null) {
        await File(outputPath).writeAsString(json);
        if (mounted) {
          context.showSuccessSnackBar('Exported to ${p.basename(outputPath)}');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isLoading = ref.watch(vfxIsLoadingProvider);
    final error = ref.watch(vfxErrorProvider);
    final data = ref.watch(vfxDataProvider);
    final displayName = ref.watch(vfxDisplayNameProvider);

    return Padding(
      padding: const EdgeInsets.all(13.0),
      child: Column(
        children: [
          // Header
          _buildHeader(displayName, data != null, isLoading),
          const SizedBox(height: 8),
          // Error display
          if (error != null) _buildError(error),
          // Main content
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : data == null
                    ? _buildEmptyState()
                    : _buildContent(data),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String displayName, bool hasData, bool isLoading) {
    final textureCount = ref.watch(vfxTextureCountProvider);
    final modelCount = ref.watch(vfxModelCountProvider);
    final animCount = ref.watch(vfxAnimationCountProvider);
    final effectCount = ref.watch(vfxEffectCountProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: Colors.cyan, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: CrystalStyles.title.copyWith(fontSize: 18),
                ),
                if (hasData)
                  Text(
                    '$textureCount textures, $modelCount models, $animCount anims, $effectCount effects',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
              ],
            ),
          ),
          if (hasData) ...[
            IconButton(
              icon: const Icon(Icons.image_outlined),
              tooltip: 'Extract Textures',
              onPressed: isLoading ? null : _extractTextures,
              color: Colors.white70,
            ),
            IconButton(
              icon: const Icon(Icons.data_object),
              tooltip: 'Export JSON',
              onPressed: isLoading ? null : _exportJson,
              color: Colors.white70,
            ),
            const SizedBox(width: 8),
          ],
          CrystalButton(
            label: hasData ? 'Load Another' : 'Load VFX',
            icon: Icons.folder_open,
            onPressed: isLoading ? null : _pickVfxFile,
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade300, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: TextStyle(color: Colors.red.shade300, fontSize: 13),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () {
              ref.read(vfxErrorProvider.notifier).state = null;
            },
            color: Colors.red.shade300,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_outlined, size: 80, color: Colors.white10),
          const SizedBox(height: 24),
          Text(
            'VFX Viewer',
            style: CrystalStyles.title.copyWith(color: Colors.white24),
          ),
          const SizedBox(height: 8),
          const Text(
            'Load an XFV file to view its contents',
            style: TextStyle(color: Colors.white38),
          ),
          const SizedBox(height: 24),
          CrystalButton(
            label: 'Load VFX File',
            icon: Icons.folder_open,
            onPressed: _pickVfxFile,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(vfx_sdk.VfxData data) {
    return Row(
      children: [
        // Left: Tabs + Item List
        Expanded(
          flex: 4,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              children: [
                // Tab Bar
                Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.white12),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.cyan,
                    labelColor: Colors.cyan,
                    unselectedLabelColor: Colors.white54,
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    tabs: [
                      _buildTab('Textures', ref.watch(vfxTextureCountProvider)),
                      _buildTab('Models', ref.watch(vfxModelCountProvider)),
                      _buildTab('Anims', ref.watch(vfxAnimationCountProvider)),
                      _buildTab('Effects', ref.watch(vfxEffectCountProvider)),
                    ],
                  ),
                ),
                // Item List
                const Expanded(child: VfxItemList()),
              ],
            ),
          ),
        ),
        const CrystalVerticalDivider.subtle(width: 1),
        // Right: Detail Panel
        Expanded(
          flex: 6,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const VfxDetailPanel(),
          ),
        ),
      ],
    );
  }

  Widget _buildTab(String label, int count) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: const TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}
