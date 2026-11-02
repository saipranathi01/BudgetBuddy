import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool filled;
  final IconData? icon;
  final bool isDanger;
  final bool isLoading;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.filled = true,
    this.icon,
    this.isDanger = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDanger ? AppColors.red : (filled ? Theme.of(context).colorScheme.primary : Colors.transparent);
    final fgColor = filled
        ? Colors.white
        : isDanger
            ? AppColors.red
            : Theme.of(context).colorScheme.primary;
    final border = filled
        ? null
        : BorderSide(
            color: isDanger
                ? AppColors.red.withValues(alpha: .6)
                : Theme.of(context).colorScheme.primary.withAlpha(180),
          );

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
            side: border ?? BorderSide.none,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Flexible(child: Text(text, textAlign: TextAlign.center)),
                ],
              ),
      ),
    );
  }
}
