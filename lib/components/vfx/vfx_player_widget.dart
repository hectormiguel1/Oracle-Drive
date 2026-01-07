import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oracle_drive/components/widgets/crystal_button.dart';
import 'package:oracle_drive/src/services/native_service.dart';

/// Widget for playing VFX effects with GPU rendering.
///
/// Renders VFX models at 30fps using the wgpu-based GPU renderer.
class VfxPlayerWidget extends ConsumerStatefulWidget {
  /// Path to the XFV file
  final String xfvPath;

  /// Name of the model to render (or empty for test quad)
  final String modelName;

  /// Name of the texture to use (or empty for auto-select)
  final String textureName;

  /// Render size in pixels
  final int size;

  /// Target frames per second
  final int fps;

  const VfxPlayerWidget({
    required this.xfvPath,
    this.modelName = '',
    this.textureName = '',
    this.size = 256,
    this.fps = 30,
    super.key,
  });

  @override
  ConsumerState<VfxPlayerWidget> createState() => _VfxPlayerWidgetState();
}

class _VfxPlayerWidgetState extends ConsumerState<VfxPlayerWidget> {
  ui.Image? _currentFrame;
  bool _isPlaying = false;
  bool _isLoading = true;
  String? _error;
  Timer? _renderTimer;
  double _animTime = 0.0;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  @override
  void didUpdateWidget(VfxPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.xfvPath != widget.xfvPath ||
        oldWidget.modelName != widget.modelName ||
        oldWidget.textureName != widget.textureName) {
      _stop();
      _initPlayer();
    }
  }

  Future<void> _initPlayer() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Initialize the player
      await NativeService.instance.vfxPlayerInit(widget.size, widget.size);

      // Load the model or test quad
      if (widget.modelName.isEmpty) {
        // Load a cyan test quad
        await NativeService.instance.vfxPlayerLoadTest(0.2, 0.8, 0.9, 1.0);
      } else {
        await NativeService.instance.vfxPlayerLoadModel(
          widget.xfvPath,
          widget.modelName,
          textureName: widget.textureName,
        );
      }

      // Render initial frame
      await _renderSingleFrame();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _renderSingleFrame() async {
    try {
      final rgba = await NativeService.instance.vfxPlayerRenderFrame(0.0);
      await _decodeFrame(rgba);
      _animTime = await NativeService.instance.vfxPlayerGetTime();
    } catch (e) {
      // Ignore render errors during playback
    }
  }

  void _play() {
    if (_isPlaying) return;

    setState(() {
      _isPlaying = true;
    });

    final deltaMs = 1000 ~/ widget.fps;
    final deltaTime = 1.0 / widget.fps;

    _renderTimer = Timer.periodic(Duration(milliseconds: deltaMs), (_) async {
      if (!_isPlaying || !mounted) return;

      try {
        final rgba = await NativeService.instance.vfxPlayerRenderFrame(deltaTime);
        await _decodeFrame(rgba);
        _animTime = await NativeService.instance.vfxPlayerGetTime();
      } catch (e) {
        // Continue even if a frame fails
      }
    });
  }

  void _stop() {
    _renderTimer?.cancel();
    _renderTimer = null;
    if (mounted) {
      setState(() {
        _isPlaying = false;
      });
    }
  }

  Future<void> _reset() async {
    _stop();
    try {
      await NativeService.instance.vfxPlayerReset();
      await _renderSingleFrame();
    } catch (e) {
      // Ignore
    }
  }

  Future<void> _decodeFrame(Uint8List rgba) async {
    final completer = Completer<ui.Image>();

    ui.decodeImageFromPixels(
      rgba,
      widget.size,
      widget.size,
      ui.PixelFormat.rgba8888,
      (image) {
        completer.complete(image);
      },
    );

    final image = await completer.future;

    if (mounted) {
      setState(() {
        _currentFrame = image;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: widget.size.toDouble(),
        height: widget.size.toDouble() + 50,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 8),
              Text(
                'Initializing GPU...',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return _buildError();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: widget.size.toDouble(),
          height: widget.size.toDouble(),
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(color: Colors.white24),
            borderRadius: BorderRadius.circular(4),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: _currentFrame != null
                ? RawImage(
                    image: _currentFrame,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                  )
                : const Center(
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.white24,
                      size: 48,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        // Controls
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: _isPlaying ? _stop : _play,
              color: Colors.white70,
              iconSize: 24,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            IconButton(
              icon: const Icon(Icons.restart_alt),
              onPressed: _reset,
              color: Colors.white54,
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            const SizedBox(width: 8),
            Text(
              '${_animTime.toStringAsFixed(1)}s',
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
            const Spacer(),
            Text(
              '${widget.fps} fps',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildError() {
    return Container(
      width: widget.size.toDouble(),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.red.shade300.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade300, size: 18),
              const SizedBox(width: 8),
              const Text(
                'GPU Render Error',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: TextStyle(color: Colors.red.shade200, fontSize: 11),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          CrystalButton(
            label: 'Retry',
            icon: Icons.refresh,
            onPressed: _initPlayer,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _renderTimer?.cancel();
    NativeService.instance.vfxPlayerDispose();
    super.dispose();
  }
}
