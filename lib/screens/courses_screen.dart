import 'package:flutter/material.dart';
import 'package:mindmatch/utils/app_colors.dart';
import 'package:provider/provider.dart';
import '../services/course_service.dart';
import '../widgets/courses_widget.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  bool _loading = false;
  String? _error;
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await Provider.of<CourseService>(context, listen: false).loadCourses();
    } catch (e) {
      _error = 'Erro ao carregar cursos';
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final courseService = Provider.of<CourseService>(context);
    final courses = courseService.courses;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    

    if (_loading && courses.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && courses.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              style: TextStyle(color: isDark ? Colors.white : Colors.red),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _load,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
        width: MediaQuery.of(context).size.width, 
        color: AppColors.whiteBack,
        child: 
        Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: AppColors.whiteBack,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              child: 
        Column(
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
            const SizedBox(height: 12),
           Padding(
                padding: const EdgeInsets.all(16),
                child: _buildCardContent(selectedIndex),
              ),
          ],
        ),
        )
      ),
            ),
    );
  }

  Widget _buildCardContent(int index) {
    switch (index) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardCourse(index, context, "Curso Teste", "desc Teste", "300 min", "26% concluido"),
            _buildCardCourse(index, context, "Curso Teste", "desc Teste", "300 min", "26% concluido"),
            _buildCardCourse(index, context, "Curso Teste", "desc Teste", "300 min", "26% concluido"),
            _buildCardCourse(index, context, "Curso Teste", "desc Teste", "300 min", "26% concluido"),
            _buildCardCourse(index, context, "Curso Teste", "desc Teste", "300 min", "26% concluido")
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           _buildCardCourse(index, context, "Curso Teste", "desc Teste", "300 min", "26% concluido"),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardCourse(index, context, "Curso Teste", "desc Teste", "300 min", "26% concluido")
          ],
        );
      default:
        return const Text('Nenhum conteúdo disponível');
    }
  }
}

  Widget _buildCardCourse(
  int index,
  BuildContext context,
  String nome,
  String desc,
  String duracao,
  String conclusao,
) {
  final double larguraTotal = MediaQuery.of(context).size.width;
  final double larguraImagem = larguraTotal * 0.20;

  return Container(
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
    decoration: BoxDecoration(
      color: AppColors.whiteBack,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: larguraImagem,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.redAccent, // fundo vermelho
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
          ),
          child: Center(
            child: Icon(
              Icons.star_border,
              size: 40,
              color: Colors.white,
            ),
          ),
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                  Text(desc),
                  Text(duracao),
                  Text(conclusao, style: TextStyle(color: Colors.orangeAccent),),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

// ✅ Widget interno: MenuCategorias
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
