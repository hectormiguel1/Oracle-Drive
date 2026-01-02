import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oracle_drive/components/widgets/crystal_loading_spinner.dart';
import 'package:oracle_drive/components/widgets/crystal_panel.dart';
import 'package:oracle_drive/components/widgets/crystal_progress_bar.dart';
import 'package:oracle_drive/components/widgets/style.dart';
import 'package:oracle_drive/models/app_game_code.dart';
import 'package:oracle_drive/providers/wpd_provider.dart';

/// Processing overlay shown during batch operations.
class WpdProcessingOverlay extends ConsumerWidget {
  final AppGameCode gameCode;

  const WpdProcessingOverlay({
    super.key,
    required this.gameCode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final processing = ref.watch(wpdProcessingProvider(gameCode));

    if (!processing.isProcessing) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Colors.black54,
      child: Center(
        child: CrystalPanel(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CrystalLoadingSpinner(),
              const SizedBox(height: 16),
              Text(
                processing.message,
                style: CrystalStyles.label.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              if (processing.totalCount > 1) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: 280,
                  child: CrystalProgressBar(
                    value: processing.progress,
                    label: 'Progress',
                    valueLabel: '${processing.processedCount} / ${processing.totalCount}',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
