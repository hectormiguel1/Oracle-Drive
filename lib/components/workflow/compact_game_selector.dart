import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_game_code.dart';
import '../../providers/app_state_provider.dart';
import '../widgets/crystal_panel.dart';

/// A compact game selector designed for use in toolbars.
///
/// Displays the current game with a dropdown for selection.
/// Smaller than the full [CrystalDropdown] for dense toolbar layouts.
class CompactGameSelector extends ConsumerStatefulWidget {
  /// Optional callback when game changes. If null, only updates the provider.
  final ValueChanged<AppGameCode>? onGameChanged;

  const CompactGameSelector({
    super.key,
    this.onGameChanged,
  });

  @override
  ConsumerState<CompactGameSelector> createState() => _CompactGameSelectorState();
}

class _CompactGameSelectorState extends ConsumerState<CompactGameSelector> {
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
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final currentGame = ref.read(selectedGameProvider);

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
              offset: Offset(0.0, size.height + 4.0),
              child: Material(
                color: Colors.transparent,
                child: CrystalPanel(
                  padding: EdgeInsets.zero,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: AppGameCode.values.map((game) {
                      final isSelected = game == currentGame;
                      final gameAccent = _getGameAccent(game);
                      return InkWell(
                        onTap: () {
                          ref.read(selectedGameProvider.notifier).state = game;
                          widget.onGameChanged?.call(game);
                          _closeDropdown();
                        },
                        hoverColor: gameAccent.withValues(alpha: 0.2),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.white10),
                            ),
                            color: isSelected
                                ? gameAccent.withValues(alpha: 0.15)
                                : null,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: gameAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                game.displayName,
                                style: TextStyle(
                                  color: isSelected ? gameAccent : Colors.white,
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              const Spacer(),
                              if (isSelected)
                                Icon(Icons.check, size: 14, color: gameAccent),
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
    _removeOverlay();
    setState(() => _isOpen = false);
  }

  void _removeOverlay() {
    final entry = _overlayEntry;
    _overlayEntry = null;
    entry?.remove();
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  Color _getGameAccent(AppGameCode game) {
    return switch (game) {
      AppGameCode.ff13_1 => const Color(0xFF00E5FF), // Cyan
      AppGameCode.ff13_2 => const Color(0xFF3D5AFE), // Indigo
      AppGameCode.ff13_lr => const Color(0xFFEC407A), // Pink
    };
  }

  @override
  Widget build(BuildContext context) {
    final currentGame = ref.watch(selectedGameProvider);
    final gameAccent = _getGameAccent(currentGame);

    return CompositedTransformTarget(
      link: _layerLink,
      child: InkWell(
        onTap: _toggleDropdown,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: gameAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: _isOpen
                  ? gameAccent.withValues(alpha: 0.6)
                  : gameAccent.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: gameAccent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: gameAccent.withValues(alpha: 0.5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                currentGame.displayName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                color: gameAccent,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
