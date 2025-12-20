import 'package:oracle_drive/components/widgets/style.dart';
import 'package:oracle_drive/src/third_party/logging_ctx.dart';
import 'package:oracle_drive/theme/crystal_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';

class CrystalConsole extends StatefulWidget {
  final VoidCallback onClose;

  const CrystalConsole({super.key, required this.onClose});

  @override
  State<CrystalConsole> createState() => _CrystalConsoleState();
}

class _CrystalConsoleState extends State<CrystalConsole> {
  final ScrollController _scrollController = ScrollController();
  final List<String> _logs = [];
  bool _autoScroll = true;

  @override
  void initState() {
    super.initState();
    _registerCallback();
  }

  void _registerCallback() {
    LoggingCtx.registerLoggingCallback(
      (msg) => setState(() {
        _logs.add(msg);
        if (_autoScroll) {
          _scrollToBottom();
        }
      }),
      LogLevel.Info,
    );
  }

  void _scrollToBottom() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).extension<CrystalTheme>()!.accent;

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.9),
        border: Border(top: BorderSide(color: accentColor, width: 2)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 5,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: CrystalColors.panelBackground.withValues(alpha: 0.5),
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.terminal, color: accentColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  "SYSTEM LOG",
                  style: CrystalStyles.sectionHeader.copyWith(
                    color: accentColor,
                  ),
                ),
                const Spacer(),
                // Clear Button
                IconButton(
                  icon: const Icon(
                    Icons.delete_sweep,
                    color: Colors.white54,
                    size: 18,
                  ),
                  onPressed: () => setState(() => _logs.clear()),
                  tooltip: 'Clear Console',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 16),
                // Close Button
                IconButton(
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white70,
                    size: 20,
                  ),
                  onPressed: widget.onClose,
                  tooltip: 'Close Console',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Output
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is UserScrollNotification) {
                  if (notification.direction == ScrollDirection.reverse) {
                    _autoScroll = false;
                  } else if (notification.metrics.atEdge &&
                      notification.metrics.pixels ==
                          notification.metrics.maxScrollExtent) {
                    _autoScroll = true;
                  }
                }
                return false;
              },
              child: SelectionArea(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        _logs[index],
                        style: GoogleFonts.jetBrainsMono(
                          height: 1.3,
                          fontSize: 12,
                          color: const Color(0xFFE0E0E0),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
