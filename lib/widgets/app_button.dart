import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool filled;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool fullWidth;
  final Widget? icon;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.filled = true,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.borderRadius = 14,
    this.padding = const EdgeInsets.symmetric(vertical: 16),
    this.fullWidth = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null && !isLoading;
    final Color effectiveBackground = filled
        ? backgroundColor ?? AppColors.primary
        : Colors.transparent;
    final Color effectiveForeground = foregroundColor ??
        (filled ? Colors.white : AppColors.textPrimary);
    final Color effectiveBorder = borderColor ??
        (filled ? Colors.transparent : AppColors.gray300);

    final ButtonStyle style = ButtonStyle(
      backgroundColor: WidgetStatePropertyAll<Color?>(
        filled && !enabled
            ? effectiveBackground.withAlpha((effectiveBackground.a * 0.5).round())
            : effectiveBackground,
      ),
      foregroundColor: WidgetStatePropertyAll(effectiveForeground),
      side: WidgetStatePropertyAll(
        BorderSide(color: effectiveBorder),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      padding: WidgetStatePropertyAll(padding),
    );

    final Widget childContent = isLoading
        ? SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(effectiveForeground),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                icon!,
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          );

    final Widget button = filled
        ? ElevatedButton(
            onPressed: enabled ? onPressed : null,
            style: style,
            child: childContent,
          )
        : OutlinedButton(
            onPressed: enabled ? onPressed : null,
            style: style,
            child: childContent,
          );

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
