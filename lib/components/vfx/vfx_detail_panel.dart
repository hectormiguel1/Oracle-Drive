import 'dart:typed_data';

import 'package:fabula_nova_sdk/bridge_generated/modules/vfx/structs.dart'
    as vfx_sdk;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oracle_drive/components/vfx/mesh_wireframe_renderer.dart';
import 'package:oracle_drive/components/widgets/crystal_button.dart';
import 'package:oracle_drive/components/widgets/style.dart';
import 'package:oracle_drive/providers/vfx_provider.dart';
import 'package:oracle_drive/src/services/native_service.dart';

/// Panel showing details of the selected VFX item.
class VfxDetailPanel extends ConsumerWidget {
  const VfxDetailPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(vfxSelectedTabProvider);
    final selectedItem = ref.watch(vfxSelectedItemProvider);

    if (selectedItem == null) {
      return const Center(
        child: Text(
          'Select an item to view details',
          style: TextStyle(color: Colors.white38),
        ),
      );
    }

    switch (tab) {
      case 0:
        final texture = ref.watch(vfxSelectedTextureProvider);
        return texture != null
            ? _TextureDetails(texture: texture)
            : const SizedBox.shrink();
      case 1:
        final model = ref.watch(vfxSelectedModelProvider);
        return model != null
            ? _ModelDetails(model: model)
            : const SizedBox.shrink();
      case 2:
        final animation = ref.watch(vfxSelectedAnimationProvider);
        return animation != null
            ? _AnimationDetails(animation: animation)
            : const SizedBox.shrink();
      case 3:
        final effect = ref.watch(vfxSelectedEffectProvider);
        return effect != null
            ? _EffectDetails(effect: effect)
            : const SizedBox.shrink();
      default:
        return const SizedBox.shrink();
    }
  }
}

class _TextureDetails extends ConsumerStatefulWidget {
  final vfx_sdk.VfxTexture texture;

  const _TextureDetails({required this.texture});

  @override
  ConsumerState<_TextureDetails> createState() => _TextureDetailsState();
}

class _TextureDetailsState extends ConsumerState<_TextureDetails> {
  bool _isLoading = false;
  String? _error;
  Uint8List? _pngBytes;
  (int, int)? _pngDimensions;

  @override
  void initState() {
    super.initState();
    _loadTexturePreview();
  }

  @override
  void didUpdateWidget(_TextureDetails oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.texture.name != widget.texture.name) {
      _error = null;
      _pngBytes = null;
      _pngDimensions = null;
      _loadTexturePreview();
    }
  }

  Future<void> _loadTexturePreview() async {
    final vfxPath = ref.read(vfxPathProvider);
    if (vfxPath == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await NativeService.instance.extractVfxTextureAsPng(
        vfxPath,
        widget.texture.name,
      );

      if (mounted) {
        setState(() {
          _pngDimensions = result.$1;
          _pngBytes = result.$2;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TEXTURE DETAILS', style: CrystalStyles.sectionHeader),
          const SizedBox(height: 16),
          _DetailRow('Name', widget.texture.name),
          _DetailRow('Dimensions', '${widget.texture.width} x ${widget.texture.height}'),
          _DetailRow('Format', widget.texture.formatName),
          _DetailRow('Format Code', '${widget.texture.format}'),
          _DetailRow('Mip Levels', '${widget.texture.mipCount}'),
          _DetailRow('Image Type', _getImageTypeName(widget.texture.imageType)),
          if (widget.texture.depth > 1) _DetailRow('Depth', '${widget.texture.depth}'),
          const Divider(color: Colors.white24, height: 32),
          Text('IMGB REFERENCE', style: CrystalStyles.sectionHeader),
          const SizedBox(height: 16),
          _DetailRow('Offset', '0x${widget.texture.imgbOffset.toRadixString(16).toUpperCase()}'),
          _DetailRow('Size', _formatBytes(widget.texture.imgbSize)),
          const Divider(color: Colors.white24, height: 32),
          Text('PREVIEW', style: CrystalStyles.sectionHeader),
          const SizedBox(height: 16),
          _buildPreview(),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading texture...',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade300, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Failed to load texture',
                  style: TextStyle(color: Colors.red.shade300, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Colors.red.shade200, fontSize: 12),
            ),
            const SizedBox(height: 12),
            CrystalButton(
              label: 'Retry',
              icon: Icons.refresh,
              onPressed: _loadTexturePreview,
            ),
          ],
        ),
      );
    }

    if (_pngBytes != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white24),
              borderRadius: BorderRadius.circular(4),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Image.memory(
                _pngBytes!,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
          if (_pngDimensions != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Preview: ${_pngDimensions!.$1} × ${_pngDimensions!.$2}',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ),
        ],
      );
    }

    // No preview available
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preview not available',
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 12),
        CrystalButton(
          label: 'Load Preview',
          icon: Icons.image,
          onPressed: _loadTexturePreview,
        ),
      ],
    );
  }

  String _getImageTypeName(int type) {
    switch (type) {
      case 0:
        return '2D';
      case 1:
        return '3D Volume';
      case 2:
        return 'Cube Map';
      default:
        return 'Unknown ($type)';
    }
  }
}

class _ModelDetails extends ConsumerStatefulWidget {
  final vfx_sdk.VfxModel model;

  const _ModelDetails({required this.model});

  @override
  ConsumerState<_ModelDetails> createState() => _ModelDetailsState();
}

class _ModelDetailsState extends ConsumerState<_ModelDetails> {
  String? _selectedTexture;

  @override
  Widget build(BuildContext context) {
    final mat = widget.model.material;
    final vfxData = ref.watch(vfxDataProvider);
    final availableTextures = vfxData?.textures ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MODEL DETAILS', style: CrystalStyles.sectionHeader),
          const SizedBox(height: 16),
          _DetailRow('Name', widget.model.name),
          _DetailRow('Data Size', _formatBytes(widget.model.dataSize)),
          if (widget.model.vertexCount != null)
            _DetailRow('Vertices', '${widget.model.vertexCount}'),
          if (widget.model.indexCount != null)
            _DetailRow('Indices', '${widget.model.indexCount}'),
          _DetailRow('Has Shader', widget.model.hasShader ? 'Yes' : 'No'),
          if (widget.model.techniqueName != null)
            _DetailRow('Technique', widget.model.techniqueName!),
          const Divider(color: Colors.white24, height: 32),
          Text('MATERIAL', style: CrystalStyles.sectionHeader),
          const SizedBox(height: 16),
          _ColorRow('Ambient', mat.ambientColor),
          _ColorRow('Diffuse', mat.diffuseColor),
          _ColorRow('Specular', mat.specularColor),
          _DetailRow('Shininess', mat.shininess.toStringAsFixed(2)),
          _DetailRow('Alpha Threshold', mat.alphaThreshold.toStringAsFixed(2)),
          const SizedBox(height: 8),
          _FlagRow('Blend', mat.blendEnabled),
          _FlagRow('Alpha Test', mat.alphaTestEnabled),
          _FlagRow('Backface Culling', mat.backFaceCulling),
          _FlagRow('Depth Mask', mat.depthMaskEnabled),
          _FlagRow('Lighting', mat.lightingEnabled),
          if (widget.model.textureRefs.isNotEmpty) ...[
            const Divider(color: Colors.white24, height: 32),
            Text('TEXTURE REFS', style: CrystalStyles.sectionHeader),
            const SizedBox(height: 8),
            ...widget.model.textureRefs.map((ref) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(ref, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                )),
          ],
          // Texture Selection for GPU preview
          if (availableTextures.isNotEmpty) ...[
            const Divider(color: Colors.white24, height: 32),
            Text('TEXTURE FOR GPU PREVIEW', style: CrystalStyles.sectionHeader),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white24),
              ),
              child: DropdownButton<String>(
                value: _selectedTexture,
                hint: Text(
                  availableTextures.isNotEmpty
                      ? 'Auto (${availableTextures.first.name})'
                      : 'No textures',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                isExpanded: true,
                dropdownColor: const Color(0xFF1E1E2E),
                underline: const SizedBox.shrink(),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Auto (first texture)'),
                  ),
                  ...availableTextures.map((tex) => DropdownMenuItem<String>(
                        value: tex.name,
                        child: Text('${tex.name} (${tex.width}x${tex.height})'),
                      )),
                ],
                onChanged: (value) => setState(() => _selectedTexture = value),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Select texture to use when rendering this model',
              style: TextStyle(color: Colors.white38, fontSize: 10),
            ),
          ],
          // Preview Section
          const Divider(color: Colors.white24, height: 32),
          Text('PREVIEW', style: CrystalStyles.sectionHeader),
          const SizedBox(height: 16),
          // Preview content (wireframe)
          if (widget.model.mesh != null)
            MeshWireframeRenderer(
              mesh: widget.model.mesh!,
              size: 220,
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white38, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No mesh geometry found',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AnimationDetails extends StatelessWidget {
  final vfx_sdk.VfxAnimation animation;

  const _AnimationDetails({required this.animation});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ANIMATION DETAILS', style: CrystalStyles.sectionHeader),
          const SizedBox(height: 16),
          _DetailRow('Name', animation.name),
          _DetailRow('Data Size', _formatBytes(animation.dataSize)),
          if (animation.durationFrames != null)
            _DetailRow('Duration', '${animation.durationFrames} frames'),
          if (animation.keyframeCount != null)
            _DetailRow('Keyframes', '${animation.keyframeCount}'),
        ],
      ),
    );
  }
}

class _EffectDetails extends StatelessWidget {
  final vfx_sdk.VfxEffect effect;

  const _EffectDetails({required this.effect});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('EFFECT DETAILS', style: CrystalStyles.sectionHeader),
          const SizedBox(height: 16),
          _DetailRow('Name', effect.name),
          _DetailRow('Data Size', _formatBytes(effect.dataSize)),
          if (effect.controllerPaths.isNotEmpty) ...[
            const Divider(color: Colors.white24, height: 32),
            Text('CONTROLLERS', style: CrystalStyles.sectionHeader),
            const SizedBox(height: 8),
            ...effect.controllerPaths.map((path) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    path,
                    style: const TextStyle(color: Colors.cyan, fontSize: 11),
                  ),
                )),
          ],
          if (effect.modelRefs.isNotEmpty) ...[
            const Divider(color: Colors.white24, height: 32),
            Text('MODEL REFS', style: CrystalStyles.sectionHeader),
            const SizedBox(height: 8),
            ...effect.modelRefs.map((ref) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(ref, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                )),
          ],
          if (effect.textureRefs.isNotEmpty) ...[
            const Divider(color: Colors.white24, height: 32),
            Text('TEXTURE REFS', style: CrystalStyles.sectionHeader),
            const SizedBox(height: 8),
            ...effect.textureRefs.map((ref) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(ref, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                )),
          ],
        ],
      ),
    );
  }
}

// Helper Widgets

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
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorRow extends StatelessWidget {
  final String label;
  final List<double> colorArray;

  const _ColorRow(this.label, this.colorArray);

  @override
  Widget build(BuildContext context) {
    // F32Array4 extends NonGrowableListView<double>, directly indexable
    final r = (colorArray[0] * 255).round().clamp(0, 255);
    final g = (colorArray[1] * 255).round().clamp(0, 255);
    final b = (colorArray[2] * 255).round().clamp(0, 255);
    final a = (colorArray[3] * 255).round().clamp(0, 255);
    final color = Color.fromARGB(a, r, g, b);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: Colors.white24),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '(${colorArray[0].toStringAsFixed(2)}, ${colorArray[1].toStringAsFixed(2)}, ${colorArray[2].toStringAsFixed(2)}, ${colorArray[3].toStringAsFixed(2)})',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _FlagRow extends StatelessWidget {
  final String label;
  final bool value;

  const _FlagRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            value ? Icons.check_circle : Icons.cancel,
            size: 14,
            color: value ? Colors.greenAccent : Colors.red.shade300,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: value ? Colors.white70 : Colors.white38,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
}
