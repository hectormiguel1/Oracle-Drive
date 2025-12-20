// components/extraction_bar.dart
import 'package:flutter/material.dart';

class ExtractionBar extends StatelessWidget {
  final int selectionCount;
  final VoidCallback onExtract;

  const ExtractionBar({
    super.key,
    required this.selectionCount,
    required this.onExtract,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasSelection = selectionCount > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: hasSelection ? onExtract : null,
          icon: Icon(
            Icons.download,
            color: hasSelection ? Colors.white : Colors.white24,
          ),
          label: Text(
            hasSelection
                ? "EXTRACT SELECTED ($selectionCount)"
                : "SELECT FILES TO EXTRACT",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: hasSelection ? Colors.white : Colors.white24,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: hasSelection ? Colors.cyan[700] : Colors.white10,
            disabledBackgroundColor: Colors.white10,
            elevation: hasSelection ? 8 : 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
}
