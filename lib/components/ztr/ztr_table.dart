import 'package:ff13_mod_resource/components/widgets/crystal_table.dart';
import 'package:ff13_mod_resource/components/widgets/crystal_text_field.dart';
import 'package:ff13_mod_resource/models/app_game_code.dart';
import 'package:ff13_mod_resource/models/ztr_model.dart';
import 'package:ff13_mod_resource/src/utils/ztr_text_renderer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ZtrTable extends StatefulWidget {
  final List<ZtrEntry> entries;
  final AppGameCode gameCode;
  final Function(ZtrEntry updatedEntry) onEntryUpdated;
  final Function(String entryId) onEntryRemoved;

  const ZtrTable({
    super.key,
    required this.gameCode,
    required this.entries,
    required this.onEntryUpdated,
    required this.onEntryRemoved,
  });

  @override
  State<ZtrTable> createState() => _ZtrTableState();
}

class _ZtrTableState extends State<ZtrTable> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  String? _editingEntryId;

  @override
  void dispose() {
    _controllers.forEach((key, controller) => controller.dispose());
    _focusNodes.forEach((key, focusNode) => focusNode.dispose());
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ZtrTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.entries.length != oldWidget.entries.length ||
        !_areListsEqual(widget.entries, oldWidget.entries)) {
      _controllers.forEach((key, controller) => controller.dispose());
      _controllers.clear();
      _focusNodes.forEach((key, focusNode) => focusNode.dispose());
      _focusNodes.clear();
      _editingEntryId = null;
    }
  }

  bool _areListsEqual(List<ZtrEntry> list1, List<ZtrEntry> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id || list1[i].text != list2[i].text) {
        return false;
      }
    }
    return true;
  }

  Widget _buildCell(BuildContext context, int row, int col) {
    final entry = widget.entries[row];

    if (col == 0) {
      // ID
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          entry.id,
          style: const TextStyle(color: Colors.white70),
          overflow: TextOverflow.ellipsis,
        ),
      );
    } else if (col == 1) {
      // String (Editable)
      _controllers.putIfAbsent(
        entry.id,
        () => TextEditingController(text: entry.text),
      );
      _focusNodes.putIfAbsent(entry.id, () => FocusNode());

      if (_controllers[entry.id]!.text != entry.text &&
          _editingEntryId != entry.id) {
        _controllers[entry.id]!.text = entry.text;
      }

      if (_editingEntryId == entry.id) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: CrystalTextField(
            controller: _controllers[entry.id],
            hintText: "",
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp(r'[\x00-\x1F\x7F]')),
            ],
            onChanged: (newValue) {
              // Update logic handled on submit/focus loss ideally, but simple text update here is fine for state
            },
          ),
        );
      } else {
        return Align(
          alignment: Alignment.centerLeft,
          child: ZtrTextRenderer.render(
            entry.text,
            widget.gameCode,
            style: const TextStyle(color: Colors.white),
            overflow: TextOverflow.ellipsis,
            displayMultiple: true,
          ),
        );
      }
    } else {
      // Actions
      return IconButton(
        icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
        onPressed: () => widget.onEntryRemoved(entry.id),
      );
    }
  }

  void _handleCellTap(int row, int col) {
    if (col == 1) {
      final entry = widget.entries[row];
      setState(() {
        _editingEntryId = entry.id;
      });
      // Request focus after rebuild
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNodes[entry.id]?.requestFocus();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.entries.isEmpty) {
      return const Center(
        child: Text(
          "No ZTR entries to display.",
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        // Clear editing on outside tap
        if (_editingEntryId != null) {
          final entry = widget.entries.firstWhere(
            (e) => e.id == _editingEntryId,
            orElse: () => widget.entries.first, 
          ); // Fallback safe, though logic implies existence
          
          if (_controllers.containsKey(entry.id)) {
             final newValue = _controllers[entry.id]!.text;
             if (newValue != entry.text) {
               widget.onEntryUpdated(ZtrEntry(entry.id, newValue));
             }
          }
          setState(() {
            _editingEntryId = null;
          });
        }
      },
      child: CrystalTable(
        headers: const ["Reference ID", "String", "Actions"],
        itemCount: widget.entries.length,
        columnFlex: const [2, 5, 1], // Flex based layout
        cellBuilder: _buildCell,
        onCellTap: _handleCellTap,
      ),
    );
  }
}