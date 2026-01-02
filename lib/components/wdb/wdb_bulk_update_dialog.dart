import 'package:oracle_drive/components/widgets/crystal_button.dart';
import 'package:oracle_drive/components/widgets/crystal_dialog.dart';
import 'package:oracle_drive/components/widgets/crystal_dropdowns.dart';
import 'package:oracle_drive/components/widgets/crystal_text_field.dart';
import 'package:oracle_drive/models/wdb_model.dart';
import 'package:flutter/material.dart';

enum BulkOperation { multiply, divide, add, subtract, set }

class BulkUpdateResult {
  final WdbColumn column;
  final BulkOperation operation;
  final double value;
  final bool applyToFiltered;
  final bool treatZeroAsOne;
  final bool onlyIfGreater;

  BulkUpdateResult({
    required this.column,
    required this.operation,
    required this.value,
    required this.applyToFiltered,
    required this.treatZeroAsOne,
    required this.onlyIfGreater,
  });
}

class WdbBulkUpdateDialog extends StatefulWidget {
  final List<WdbColumn> columns;
  final int totalRows;
  final int filteredRows;
  final bool hasFilter;

  const WdbBulkUpdateDialog({
    super.key,
    required this.columns,
    required this.totalRows,
    required this.filteredRows,
    required this.hasFilter,
  });

  @override
  State<WdbBulkUpdateDialog> createState() => _WdbBulkUpdateDialogState();
}

class _WdbBulkUpdateDialogState extends State<WdbBulkUpdateDialog> {
  late List<WdbColumn> _numericColumns;
  WdbColumn? _selectedColumn;
  BulkOperation _selectedOperation = BulkOperation.multiply;
  final TextEditingController _valueController = TextEditingController(text: '1');
  bool _applyToFiltered = true;
  bool _treatZeroAsOne = true;
  bool _onlyIfGreater = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _numericColumns = widget.columns
        .where((c) => c.type == WdbColumnType.int || c.type == WdbColumnType.float)
        .toList();
    if (_numericColumns.isNotEmpty) {
      _selectedColumn = _numericColumns.first;
    }
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  String _operationLabel(BulkOperation op) {
    switch (op) {
      case BulkOperation.multiply:
        return 'Multiply by';
      case BulkOperation.divide:
        return 'Divide by';
      case BulkOperation.add:
        return 'Add';
      case BulkOperation.subtract:
        return 'Subtract';
      case BulkOperation.set:
        return 'Set to';
    }
  }

  void _apply() {
    final value = double.tryParse(_valueController.text);
    if (value == null) {
      setState(() => _error = 'Please enter a valid number');
      return;
    }

    if (_selectedOperation == BulkOperation.divide && value == 0) {
      setState(() => _error = 'Cannot divide by zero');
      return;
    }

    if (_selectedColumn == null) {
      setState(() => _error = 'Please select a column');
      return;
    }

    final usesTreatZero = _selectedOperation == BulkOperation.multiply ||
        _selectedOperation == BulkOperation.divide;

    Navigator.of(context).pop(BulkUpdateResult(
      column: _selectedColumn!,
      operation: _selectedOperation,
      value: value,
      applyToFiltered: _applyToFiltered && widget.hasFilter,
      treatZeroAsOne: _treatZeroAsOne && usesTreatZero,
      onlyIfGreater: _onlyIfGreater,
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_numericColumns.isEmpty) {
      return CrystalDialog(
        title: 'Bulk Update',
        content: const Text(
          'No numeric columns available for bulk update.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          CrystalButton(
            onPressed: () => Navigator.of(context).pop(),
            label: 'Close',
          ),
        ],
      );
    }

    final affectedRows = (_applyToFiltered && widget.hasFilter)
        ? widget.filteredRows
        : widget.totalRows;

    return CrystalDialog(
      title: 'Bulk Update',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Column',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          CrystalDropdown<WdbColumn>(
            value: _selectedColumn!,
            items: _numericColumns,
            onChanged: (col) => setState(() => _selectedColumn = col),
            itemLabelBuilder: (col) => col.displayName,
          ),
          const SizedBox(height: 16),
          const Text(
            'Operation',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          CrystalDropdown<BulkOperation>(
            value: _selectedOperation,
            items: BulkOperation.values,
            onChanged: (op) => setState(() {
              _selectedOperation = op;
              _error = null;
            }),
            itemLabelBuilder: _operationLabel,
          ),
          const SizedBox(height: 16),
          const Text(
            'Value',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          CrystalTextField(
            controller: _valueController,
            hintText: 'Enter value...',
            onChanged: (_) => setState(() => _error = null),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ],
          if (_selectedOperation == BulkOperation.multiply ||
              _selectedOperation == BulkOperation.divide) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => setState(() => _treatZeroAsOne = !_treatZeroAsOne),
              child: Row(
                children: [
                  Icon(
                    _treatZeroAsOne
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    color: Colors.white70,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Treat zero values as 1 (so 0 x 5 = 5)',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => setState(() => _onlyIfGreater = !_onlyIfGreater),
            child: Row(
              children: [
                Icon(
                  _onlyIfGreater
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                  color: Colors.white70,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Only update if current value is greater',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
          if (widget.hasFilter) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => setState(() => _applyToFiltered = !_applyToFiltered),
              child: Row(
                children: [
                  Icon(
                    _applyToFiltered
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    color: Colors.white70,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Apply only to filtered rows',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white54, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This will update $affectedRows row${affectedRows != 1 ? 's' : ''}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        CrystalButton(
          onPressed: () => Navigator.of(context).pop(),
          label: 'Cancel',
        ),
        CrystalButton(
          onPressed: _apply,
          label: 'Apply',
          isPrimary: true,
          icon: Icons.edit,
        ),
      ],
    );
  }
}
