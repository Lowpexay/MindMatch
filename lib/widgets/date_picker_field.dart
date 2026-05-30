import 'package:flutter/material.dart';
import 'styled_text_field.dart';

class DatePickerField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final DateTime? selectedDate;
  final void Function(DateTime) onDateSelected;
  final String helpText;
  final DateTime firstDate;
  final DateTime lastDate;
  final Locale? locale;
  final String? Function(String?)? validator;

  DatePickerField({
    super.key,
    required this.controller,
    required this.label,
    required this.onDateSelected,
    this.selectedDate,
    this.helpText = 'Selecione a data',
    DateTime? firstDate,
    DateTime? lastDate,
    this.locale,
    this.validator,
  })  : firstDate = firstDate ?? DateTime(1900),
        lastDate = lastDate ?? DateTime.now();

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, "0")}/${date.month.toString().padLeft(2, "0")}/${date.year}';
  }

  Future<void> _openDatePicker(BuildContext context) async {
    final now = DateTime.now();
    final initial = selectedDate ?? DateTime(now.year - 18, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: helpText,
      locale: locale,
    );

    if (picked != null) {
      controller.text = _formatDate(picked);
      onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openDatePicker(context),
      child: AbsorbPointer(
        child: StyledTextField(
          controller: controller,
          label: label,
          validator: validator,
        ),
      ),
    );
  }
}
