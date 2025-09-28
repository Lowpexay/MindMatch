import 'package:flutter/material.dart';
import 'package:mindmatch/utils/app_colors.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => CoursesScreenState();
}

class CoursesScreenState extends State<CoursesScreen> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.blackFont : AppColors.lighterGreyBack,
      appBar: AppBar(
        title: const Text("Cursos"),
        backgroundColor: isDark ? AppColors.blackFont : AppColors.whiteBack,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            MenuCategorias(
              selectedIndex: selectedIndex,
              onChanged: (index) {
                setState(() {
                  selectedIndex = index;
                });
              },
            ),
            const SizedBox(height: 24),
            Text('Conteúdo da aba: ${selectedIndex + 1}'),
          ],
        ),
      ),
    );
  }
}

// ✅ Widget interno: MenuCategorias como classe
class MenuCategorias extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onChanged;

  const MenuCategorias({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> categorias = const ['Em Destaque', 'Favoritos', 'Concluídos'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(categorias.length, (index) {
        final isSelected = selectedIndex == index;

        return GestureDetector(
          onTap: () => onChanged(index),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                categorias[index],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.deepPurple : Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              if (isSelected)
                Container(
                  height: 2,
                  width: 40,
                  color: Colors.deepPurple,
                ),
            ],
          ),
        );
      }),
    );
  }
}
