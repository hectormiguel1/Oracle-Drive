import 'package:oracle_drive/components/widgets/crystal_button.dart';
import 'package:flutter/material.dart';

class CrystalTabBar extends StatelessWidget {
  final List<String> labels;
  final List<IconData> icons;

  const CrystalTabBar({super.key, required this.labels, required this.icons})
    : assert(labels.length == icons.length);

  @override
  Widget build(BuildContext context) {
    final controller = DefaultTabController.of(context);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(labels.length, (index) {
            final isSelected = controller.index == index;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: CrystalButton(
                label: labels[index],
                icon: icons[index],
                isPrimary: isSelected,
                onPressed: () {
                  controller.animateTo(index);
                },
              ),
            );
          }),
        );
      },
    );
  }
}
