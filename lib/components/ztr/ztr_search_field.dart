import 'package:oracle_drive/components/widgets/crystal_text_field.dart';
import 'package:flutter/material.dart';

class ZtrSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const ZtrSearchField({super.key, required this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CrystalTextField(
      controller: controller,
      onChanged: onChanged,
      hintText: 'Search Reference ID or String',
      prefixIcon: Icons.search,
    );
  }
}
