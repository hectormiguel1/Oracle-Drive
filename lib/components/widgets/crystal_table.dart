import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:oracle_drive/theme/crystal_theme.dart';
import 'package:flutter/material.dart';

class CrystalTable extends StatefulWidget {
  final List<String> headers;
  final int itemCount;
  final Widget Function(BuildContext context, int row, int col) cellBuilder;
  final List<double>? columnWidths;
  final List<int>? columnFlex;
  final void Function(int row, int col)? onCellTap;

  final Color? accentColor;
  final Color? backgroundColor;
  final TextStyle? headerStyle;

  const CrystalTable({
    super.key,
    required this.headers,
    required this.itemCount,
    required this.cellBuilder,
    this.columnWidths,
    this.columnFlex,
    this.onCellTap,
    this.accentColor,
    this.backgroundColor,
    this.headerStyle,
  }) : assert(
         columnWidths != null || columnFlex != null,
         "Either columnWidths or columnFlex must be provided",
       ),
       assert(
         columnWidths == null || columnWidths.length == headers.length,
         "columnWidths length must match headers length",
       ),
       assert(
         columnFlex == null || columnFlex.length == headers.length,
         "columnFlex length must match headers length",
       );

  @override
  State<CrystalTable> createState() => _CrystalTableState();
}

class _CrystalTableState extends State<CrystalTable> {
  int _selectedIndex = -1;
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  Widget _buildHeader(Color bg, Color accent, bool isFixed, double? width) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: CustomPaint(
        painter: _HeaderPainter(
          color: bg.withValues(alpha: 0.5),
          borderColor: accent,
        ),
        child: Container(
          width: isFixed ? width : null,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          child: Row(
            children: List.generate(widget.headers.length, (index) {
              final child = Text(
                widget.headers[index],
                style:
                    widget.headerStyle ??
                    TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.0,
                    ),
                overflow: TextOverflow.ellipsis,
              );

              if (isFixed) {
                return SizedBox(
                  width: widget.columnWidths![index],
                  child: child,
                );
              } else {
                return Expanded(
                  flex: widget.columnFlex![index],
                  child: child,
                );
              }
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(int row, Color accent, Color bg, bool isFixed, double? width) {
    final isSelected = _selectedIndex == row;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: _CrystalTableRow(
        isSelected: isSelected,
        accentColor: accent,
        backgroundColor: bg,
        onTap: () {
          setState(() => _selectedIndex = row);
        },
        child: SizedBox(
          width: isFixed ? width : null,
          child: Row(
            children: List.generate(widget.headers.length, (col) {
              final cellWidget = widget.cellBuilder(
                context,
                row,
                col,
              );

              Widget tappableContent = GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  setState(() => _selectedIndex = row);
                  widget.onCellTap?.call(row, col);
                },
                child: cellWidget,
              );

              if (isFixed) {
                return SizedBox(
                  width: widget.columnWidths![col],
                  child: tappableContent,
                );
              } else {
                return Expanded(
                  flex: widget.columnFlex![col],
                  child: tappableContent,
                );
              }
            }),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color accent =
        widget.accentColor ??
        Theme.of(context).extension<CrystalTheme>()!.accent;
    final Color bg = widget.backgroundColor ?? const Color(0xFF101015);

    final bool isFixed = widget.columnWidths != null;
    final double totalWidth = isFixed && widget.columnWidths!.isNotEmpty
        ? widget.columnWidths!.reduce((a, b) => a + b)
        : 0;

    final scrollBehavior = ScrollConfiguration.of(context).copyWith(
      dragDevices: {
        ui.PointerDeviceKind.touch,
        ui.PointerDeviceKind.mouse,
        ui.PointerDeviceKind.trackpad,
      },
      scrollbars: false,
    );

    if (isFixed) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final displayWidth = totalWidth + 48;
          final contentWidth = math.max(displayWidth, constraints.maxWidth);
          final needsHorizontalScroll = displayWidth > constraints.maxWidth;

          return Stack(
            children: [
              // Main content with both scrolls
              Padding(
                padding: EdgeInsets.only(
                  right: 12, // Space for vertical scrollbar
                  bottom: needsHorizontalScroll ? 14 : 0, // Space for horizontal scrollbar
                ),
                child: ScrollConfiguration(
                  behavior: scrollBehavior,
                  child: SingleChildScrollView(
                    controller: _horizontalController,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: contentWidth,
                      child: Column(
                        children: [
                          // Pass contentWidth - Container padding is handled internally
                          _buildHeader(bg, accent, isFixed, contentWidth),
                          Expanded(
                            child: ListView.builder(
                              controller: _verticalController,
                              itemCount: widget.itemCount,
                              itemBuilder: (context, row) =>
                                  _buildRow(row, accent, bg, isFixed, contentWidth),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Vertical scrollbar - fixed at right edge
              Positioned(
                right: 0,
                top: 52, // Below header
                bottom: needsHorizontalScroll ? 14 : 0,
                child: RawScrollbar(
                  controller: _verticalController,
                  thumbVisibility: true,
                  trackVisibility: true,
                  interactive: true,
                  thumbColor: accent.withValues(alpha: 0.7),
                  trackColor: Colors.black26,
                  trackBorderColor: Colors.white10,
                  thickness: 8,
                  radius: const Radius.circular(4),
                  child: const SizedBox(width: 8),
                ),
              ),
              // Horizontal scrollbar - fixed at bottom edge
              if (needsHorizontalScroll)
                Positioned(
                  left: 0,
                  right: 12,
                  bottom: 0,
                  child: RawScrollbar(
                    controller: _horizontalController,
                    thumbVisibility: true,
                    trackVisibility: true,
                    interactive: true,
                    thumbColor: accent,
                    trackColor: Colors.black26,
                    trackBorderColor: Colors.white10,
                    thickness: 10,
                    radius: const Radius.circular(5),
                    child: const SizedBox(height: 10),
                  ),
                ),
            ],
          );
        },
      );
    } else {
      // Flex-based layout (no horizontal scrolling needed)
      return Column(
        children: [
          _buildHeader(bg, accent, isFixed, null),
          Expanded(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ScrollConfiguration(
                    behavior: scrollBehavior,
                    child: ListView.builder(
                      controller: _verticalController,
                      itemCount: widget.itemCount,
                      itemBuilder: (context, row) =>
                          _buildRow(row, accent, bg, isFixed, null),
                    ),
                  ),
                ),
                // Vertical scrollbar - fixed at right edge
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: RawScrollbar(
                    controller: _verticalController,
                    thumbVisibility: true,
                    trackVisibility: true,
                    interactive: true,
                    thumbColor: accent.withValues(alpha: 0.7),
                    trackColor: Colors.black26,
                    trackBorderColor: Colors.white10,
                    thickness: 8,
                    radius: const Radius.circular(4),
                    child: const SizedBox(width: 8),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }
}

// -----------------------------------------------------------------------------
// PRIVATE HELPERS
// -----------------------------------------------------------------------------

class _CrystalTableRow extends StatefulWidget {
  final Widget child;
  final bool isSelected;
  final VoidCallback onTap;
  final Color accentColor;
  final Color backgroundColor;

  const _CrystalTableRow({
    required this.child,
    required this.isSelected,
    required this.onTap,
    required this.accentColor,
    required this.backgroundColor,
  });

  @override
  State<_CrystalTableRow> createState() => _CrystalTableRowState();
}

class _CrystalTableRowState extends State<_CrystalTableRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool isActive = widget.isSelected || _isHovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Stack(
          children: [
            // 2. GLASS/PAINT LAYER
            Positioned.fill(
              child: CustomPaint(
                painter: _CrystalRowPainter(
                  // Use lower opacity to let the blur show through
                  color: isActive
                      ? widget.accentColor.withValues(alpha: 0.05)
                      : widget.backgroundColor.withValues(alpha: 0.05),
                  borderColor: isActive
                      ? widget.accentColor
                      : Colors.white24.withValues(alpha: 0.25),
                  isActive: isActive,
                ),
              ),
            ),
            // 3. CONTENT
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: widget.child,
            ),
          ],
        ),
      ),
    );
  }
}

// SHARED SHAPE PATH
Path _getRowShapePath(Size size) {
  final path = Path();
  // Fixed inset for consistent diamond shape
  double inset = size.height / 3;

  path.moveTo(inset, 0);
  path.lineTo(size.width - inset, 0);
  path.lineTo(size.width, size.height / 2);
  path.lineTo(size.width - inset, size.height);
  path.lineTo(inset, size.height);
  path.lineTo(0, size.height / 2);
  path.close();
  return path;
}

class _CrystalRowPainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  final bool isActive;

  _CrystalRowPainter({
    required this.color,
    required this.borderColor,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = _getRowShapePath(size);

    // Draw Tint
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke,
    );

    // Draw Gloss (The Crystal Reflection)
    if (isActive) {
      final double inset = size.height / 3;
      final glossPath = Path();
      glossPath.moveTo(inset, 0);
      glossPath.lineTo(size.width - inset, 0);
      glossPath.lineTo(size.width - inset - 20, size.height / 2);
      glossPath.lineTo(inset + 20, size.height / 2);
      glossPath.close();

      canvas.drawPath(
        path,
        Paint()
          ..color = borderColor.withValues(alpha: 0.15)
          ..blendMode = BlendMode.plus,
      );
      // Add glow
      canvas.drawShadow(path, borderColor.withValues(alpha: 0.7), 8.0, true);
    }

    // Draw Border
    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = isActive ? 1.5 : 1.0,
    );
  }

  @override
  bool shouldRepaint(covariant _CrystalRowPainter old) =>
      old.isActive != isActive ||
      old.color != color ||
      old.borderColor != borderColor;
}

class _HeaderPainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  final double skew = 10.0;

  _HeaderPainter({required this.color, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width - 20, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(20, size.height)
      ..close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
