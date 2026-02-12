import 'package:flutter/material.dart';
import '../colors.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double elevation;

  const GlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: TomeColors.pureWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: const Color(0x0A000000),
              blurRadius: 10 + (elevation * 5),
              offset: Offset(0, 4 + (elevation * 2)),
            ),
          ],
        ),
        padding: padding,
        child: child,
      ),
    );
  }
}
