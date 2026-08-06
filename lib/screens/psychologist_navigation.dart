import 'package:flutter/material.dart';

import 'main_navigation.dart';

class PsychologistNavigation extends StatelessWidget {
  const PsychologistNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainNavigation(userRole: 'PSYCHOLOGIST');
  }
}
