import 'package:ff13_mod_resource/theme/crystal_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CrystalTextField extends StatelessWidget {
  final String? hintText;
  final bool obscureText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final IconData? prefixIcon;

  const CrystalTextField({
    super.key,
    this.hintText,
    this.obscureText = false,
    this.controller,
    this.onChanged,
    this.inputFormatters,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).extension<CrystalTheme>()!.accent;

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(color: accentColor, width: 1.5),
        ),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        inputFormatters: inputFormatters,
        obscureText: obscureText,
        style: TextStyle(color: accentColor, fontSize: 16),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.transparent,
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.white24),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          prefixIcon: Icon(
            prefixIcon ?? Icons.chevron_right,
            color: accentColor,
            size: 18,
          ),
        ),
      ),
    );
  }
}
