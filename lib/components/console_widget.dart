import 'package:oracle_drive/src/third_party/logging_ctx.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';

class ConsoleWidget extends StatefulWidget {
  const ConsoleWidget({super.key});

  @override
  State<ConsoleWidget> createState() => _ConsoleWidgetState();
}

class _ConsoleWidgetState extends State<ConsoleWidget> {
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
    // Schedule the scroll for the end of the frame to ensure layout is updated
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
    return Container(
      color: Colors.transparent,
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header (Optional, makes it look like a window)
          Container(
            color: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              children: [
                const Icon(Icons.terminal, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                const Text(
                  "DEBUG CONSOLE",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // Clear Button
                IconButton(
                  icon: const Icon(
                    Icons.block,
                    color: Colors.white38,
                    size: 16,
                  ),
                  onPressed: () => setState(() => _logs.clear()),
                  tooltip: 'Clear Console',
                ),
              ],
            ),
          ),

          // The Console Output
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is UserScrollNotification) {
                  // If user scrolls up (reverse), disable auto-scroll.
                  // If they hit bottom, re-enable it.
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
                  padding: const EdgeInsets.all(8),
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    return Text(
                      _logs[index],
                      style: GoogleFonts.jetBrainsMono(
                        height: 1.2,
                        fontSize: 13,
                        color: const Color(0xFFCCCCCC),
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
