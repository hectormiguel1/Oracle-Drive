import 'package:ff13_mod_resource/components/widgets/crystal_container.dart';
import 'package:ff13_mod_resource/components/widgets/crystal_panel.dart';
import 'package:ff13_mod_resource/components/widgets/style.dart';
import 'package:ff13_mod_resource/theme/crystal_theme.dart';
import 'package:flutter/material.dart';

class CrystalDropdown<T> extends StatefulWidget {
  final T value;
  final List<T> items;
  final ValueChanged<T> onChanged;
  final String? label;
  final String Function(T item)? itemLabelBuilder;

  const CrystalDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.label,
    this.itemLabelBuilder,
  });

  @override
  State<CrystalDropdown<T>> createState() => _CrystalDropdownState<T>();
}

class _CrystalDropdownState<T> extends State<CrystalDropdown<T>> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;
    final accentColor = Theme.of(context).extension<CrystalTheme>()!.accent;

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Full screen transparent detector
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeDropdown,
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.transparent),
            ),
          ),
          // Dropdown content
          Positioned(
            width: size.width,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0.0, size.height + 5.0),
              child: Material(
                color: Colors.transparent,
                child: CrystalPanel(
                  padding: EdgeInsets.zero,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: widget.items.map((item) {
                  final isSelected = item == widget.value;
                  final displayLabel = widget.itemLabelBuilder?.call(item) ?? item.toString();
                  return InkWell(
                    onTap: () {
                      widget.onChanged(item);
                      _closeDropdown();
                    },
                    hoverColor: accentColor.withValues(alpha: 0.2),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.white10),
                        ),
                        color: isSelected
                            ? accentColor.withValues(alpha: 0.1)
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            displayLabel,
                            style: TextStyle(
                              color: isSelected
                                  ? accentColor
                                  : Colors.white,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check,
                              size: 16,
                              color: accentColor,
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    setState(() => _isOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).extension<CrystalTheme>()!.accent;
    final displayValue = widget.itemLabelBuilder?.call(widget.value) ?? widget.value.toString();
    return CompositedTransformTarget(
      link: _layerLink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(widget.label!, style: CrystalStyles.label),
            ),
          GestureDetector(
            onTap: _toggleDropdown,
            child: CrystalContainer(
              skew: 0, // Rectangular for inputs, or 10 for slight style
              color: Colors.black.withValues(alpha: 0.4),
              borderColor: _isOpen ? accentColor : Colors.white24,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    displayValue,
                    style: const TextStyle(color: Colors.white),
                  ),
                  Icon(
                    _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: _isOpen ? accentColor : Colors.white54,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
