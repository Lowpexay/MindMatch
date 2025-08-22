import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppColorsProfile {
  static const Color whiteBack = Color(0xFFF9FAFA);
  static const Color purpleBack = Color(0xFF6365F1);
  static const Color blackFont = Color(0xFF262626);
  static const Color lightGreyFont = Color(0xFFcac9c9);
}

class ProfileEditScreen extends StatelessWidget{
  const ProfileEditScreen({super.key});

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Container()
    );
  }
  
}