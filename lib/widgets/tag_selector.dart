import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class TagSelector extends StatelessWidget {
  final List<String> availableTags;
  final List<String> selectedTags;
  final Function(List<String>) onTagsChanged;
  final int maxSelection;

  const TagSelector({
    super.key,
    required this.availableTags,
    required this.selectedTags,
    required this.onTagsChanged,
    this.maxSelection = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selectedTags.isNotEmpty) ...[
          Text(
            'Selecionados (${selectedTags.length}/$maxSelection):',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Wrap(
          spacing: 8,
            runSpacing: 8,
            children: availableTags.map((tag) {
              final isSelected = selectedTags.contains(tag);
              final canSelect = selectedTags.length < maxSelection || isSelected;
              final isDark = Theme.of(context).brightness == Brightness.dark;

        // Ajuste: em dark mode, não selecionados devem "ficar roxos" (texto e borda roxos, fundo discreto)
        final bool darkUnselected = isDark && !isSelected;
        final Color baseBg = isSelected
          ? AppColors.primary
          : darkUnselected
            ? AppColors.primary.withOpacity(0.12)
            : Colors.white;
        final Color baseText = isSelected
          ? Colors.white
          : darkUnselected
            ? Colors.white // texto branco em dark mode quando não selecionado
            : Colors.black; // modo claro continua preto

              return GestureDetector(
                onTap: canSelect ? () => _toggleTag(tag) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: baseBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
            color: isSelected
              ? AppColors.primary
              : darkUnselected
                ? AppColors.primary
                : canSelect
                  ? (isDark ? Colors.white24 : AppColors.gray300)
                  : AppColors.gray200,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : [],
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      color: canSelect ? baseText : AppColors.textMuted,
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        if (selectedTags.length >= maxSelection) ...[
          const SizedBox(height: 8),
          Text(
            'Máximo de $maxSelection tags selecionadas',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.warning,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  void _toggleTag(String tag) {
    final newSelectedTags = List<String>.from(selectedTags);
    
    if (newSelectedTags.contains(tag)) {
      newSelectedTags.remove(tag);
    } else if (newSelectedTags.length < maxSelection) {
      newSelectedTags.add(tag);
    }
    
    onTagsChanged(newSelectedTags);
  }
}
