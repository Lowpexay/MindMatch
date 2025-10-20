import 'package:flutter/material.dart';
import 'package:mindmatch/utils/app_colors.dart';

class CustomNavbar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final VoidCallback? onCenterAvatarTap; // novo callback para avatar central (AI Chat)

  const CustomNavbar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    this.onCenterAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 70,
          decoration: BoxDecoration(
            color: isDark ? AppColors.blackFont : AppColors.whiteBack,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'Home', 0, context),
              _buildNavItem(Icons.video_library, 'Cursos', 1, context),
              SizedBox(width: 60), // espaço para o avatar central (Luma)
              _buildNavItem(Icons.chat_bubble_outline, 'Chats', 2, context),
              _buildNavItem(Icons.person_outline, 'Perfil', 3, context),
            ],
          ),
        ),

        Positioned(
          top: -25,
          left: MediaQuery.of(context).size.width / 2 - 30,
          child: GestureDetector(
            // Se callback custom foi passado, usamos para abrir AI Chat; senão fallback para chats (índice 2)
            onTap: onCenterAvatarTap ?? () => onItemTapped(2),
            child: Column(
              children: [
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: isDark ? AppColors.blackFont : AppColors.whiteBack, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const CircleAvatar(
                    backgroundImage: AssetImage('assets/images/cabecaLuma.png'),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, context) {
    final isSelected = selectedIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isDark ? (isSelected ? AppColors.purpleBack : AppColors.whiteBack) : (isSelected ? AppColors.purpleBack : AppColors.blackFont),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? (isSelected ? AppColors.purpleBack : AppColors.whiteBack) : (isSelected ? AppColors.purpleBack : AppColors.blackFont),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Container(
            height: 1,
            color: isDark ? (isSelected ? AppColors.purpleBack : AppColors.whiteBack) : (isSelected ? AppColors.purpleBack : AppColors.blackFont),
          ),
        ],
      ),
    );
  }
}
