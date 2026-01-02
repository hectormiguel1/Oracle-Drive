import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/crystal_button.dart';
import '../widgets/crystal_dialog.dart';
import '../widgets/crystal_text_field.dart';
import '../../models/app_game_code.dart';
import '../../models/workflow/workflow_models.dart';
import '../../providers/workflow_provider.dart';

/// Shows a dialog to create a new workflow.
///
/// Returns the workflow name if created, null if cancelled.
Future<String?> showCreateWorkflowDialog(
  BuildContext context,
  WidgetRef ref,
  AppGameCode gameCode,
) async {
  final nameController = TextEditingController();
  final descController = TextEditingController();

  final result = await showDialog<bool>(
    context: context,
    builder: (context) => CrystalDialog(
      title: 'New Workflow',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Workflow Name',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          CrystalTextField(
            controller: nameController,
            hintText: 'Enter workflow name...',
          ),
          const SizedBox(height: 16),
          const Text(
            'Description (optional)',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          CrystalTextField(
            controller: descController,
            hintText: 'Enter description...',
          ),
        ],
      ),
      actions: [
        CrystalButton(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context, false),
        ),
        CrystalButton(
          label: 'Create',
          isPrimary: true,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    ),
  );

  if (result == true && nameController.text.isNotEmpty) {
    ref.read(workflowEditorProvider.notifier).createNew(
          nameController.text,
          gameCode,
        );
    if (descController.text.isNotEmpty) {
      ref.read(workflowEditorProvider.notifier).setDescription(
            descController.text,
          );
    }
    return nameController.text;
  }

  return null;
}

/// Shows a dialog warning about unsaved changes.
///
/// Returns the user's choice:
/// - `true` if they want to save
/// - `false` if they want to discard
/// - `null` if cancelled
Future<bool?> showUnsavedChangesDialog(BuildContext context) async {
  return showDialog<bool>(
    context: context,
    builder: (context) => CrystalDialog(
      title: 'Unsaved Changes',
      content: const Text(
        'You have unsaved changes. Do you want to save before closing?',
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        CrystalButton(
          label: 'Discard',
          onPressed: () => Navigator.pop(context, false),
        ),
        CrystalButton(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context, null),
        ),
        CrystalButton(
          label: 'Save',
          isPrimary: true,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    ),
  );
}

/// Shows a validation errors dialog.
Future<void> showValidationErrorsDialog(
  BuildContext context,
  List<WorkflowValidationError> errors,
) {
  return showDialog(
    context: context,
    builder: (context) => CrystalDialog(
      title: 'Validation Errors',
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: errors
              .map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          e.message,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
      actions: [
        CrystalButton(
          label: 'Close',
          onPressed: () => Navigator.pop(context),
        ),
      ],
    ),
  );
}
