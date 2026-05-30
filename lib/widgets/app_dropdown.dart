import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class AppDropdown extends StatelessWidget {
  final String? value;
  final String hint;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  const AppDropdown({
    super.key,
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.textSecondary),
      ),
      child: DropdownButton<String>(
        isExpanded: true,
        alignment: AlignmentDirectional.centerStart,
        hint: Text(
          hint,
          style: TextStyle(
            color: AppColors.textPrimary,
          ),
        ),
        value: value?.isEmpty == true ? null : value,
        icon: Icon(
          Icons.arrow_drop_down,
          size: 28,
          color: AppColors.textPrimary,
        ),
        dropdownColor: AppColors.background,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
        ),
        underline: const SizedBox.shrink(),
        items: items,
        onChanged: onChanged,
      ),
    );
  }
}
