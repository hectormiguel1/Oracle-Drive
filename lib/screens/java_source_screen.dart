import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import 'package:oracle_drive/components/widgets/crystal_button.dart';
import 'package:oracle_drive/components/widgets/crystal_loading_spinner.dart';
import 'package:oracle_drive/components/widgets/crystal_panel.dart';
import 'package:oracle_drive/components/widgets/style.dart';
import 'package:path/path.dart' as p;

class JavaSourceScreen extends StatefulWidget {
  final String filePath;

  const JavaSourceScreen({super.key, required this.filePath});

  @override
  State<JavaSourceScreen> createState() => _JavaSourceScreenState();
}

class _JavaSourceScreenState extends State<JavaSourceScreen> {
  String? _sourceCode;
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSource();
  }

  Future<void> _loadSource() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final file = File(widget.filePath);
      if (!file.existsSync()) {
        throw Exception('File not found: ${widget.filePath}');
      }

      final content = await file.readAsString();
      setState(() {
        _sourceCode = content;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard() {
    if (_sourceCode != null) {
      Clipboard.setData(ClipboardData(text: _sourceCode!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Source copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileName = p.basename(widget.filePath);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Column(
        children: [
          // Header bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              border: Border(
                bottom: BorderSide(color: Colors.cyan.withValues(alpha: 0.3)),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white70),
                  tooltip: 'Back to Workspace',
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.code, color: Colors.greenAccent, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName,
                        style: CrystalStyles.title.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.filePath,
                        style: CrystalStyles.label.copyWith(fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                CrystalButton(
                  icon: Icons.copy,
                  label: 'Copy',
                  onPressed: _sourceCode != null ? _copyToClipboard : null,
                ),
                const SizedBox(width: 8),
                CrystalButton(
                  icon: Icons.refresh,
                  label: 'Reload',
                  onPressed: _loadSource,
                ),
              ],
            ),
          ),
          // Source code viewer
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CrystalLoadingSpinner.large(label: 'Loading source...'),
      );
    }

    if (_error != null) {
      return Center(
        child: CrystalPanel(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              Text(
                'Failed to load source',
                style: CrystalStyles.title.copyWith(color: Colors.redAccent),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: Colors.white54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              CrystalButton(
                icon: Icons.refresh,
                label: 'Retry',
                onPressed: _loadSource,
              ),
            ],
          ),
        ),
      );
    }

    if (_sourceCode == null || _sourceCode!.isEmpty) {
      return const Center(
        child: Text(
          'No source code to display',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: CrystalPanel(
        padding: EdgeInsets.zero,
        child: SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: HighlightView(
              _sourceCode!,
              language: 'java',
              theme: vs2015Theme,
              padding: const EdgeInsets.all(16),
              textStyle: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
