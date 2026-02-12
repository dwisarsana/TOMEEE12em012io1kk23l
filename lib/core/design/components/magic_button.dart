import 'package:flutter/material.dart';
import '../colors.dart';

class MagicButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isGhost;

  const MagicButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isGhost = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isGhost) {
      return TextButton.icon(
        onPressed: onPressed,
        icon: icon != null ? Icon(icon, size: 18) : const SizedBox.shrink(),
        label: Text(
          label,
          style: TextStyle(
            color: TomeColors.slateGrey,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: TomeColors.mysticIndigo.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: TomeColors.mysticIndigo,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: const StadiumBorder(),
        ),
        icon: icon != null ? Icon(icon, size: 20) : const SizedBox.shrink(),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
