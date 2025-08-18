import 'package:flutter/material.dart';

class AppColorsProfile {
  static const Color whiteBack = Color(0xFFF9FAFA);
  static const Color purpleBack = Color(0xFF6365F1);
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          //botoes lado esquerdo
          icon: const Icon(Icons.arrow_back_ios),
          color: Color(0xFFF9FAFA),
          tooltip: "Voltar",
          onPressed: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Voltar')));
          },
        ),
        title: Text(
          "Perfil",
          style: TextStyle(
            color:AppColorsProfile.whiteBack,
            fontWeight: FontWeight.bold
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            color: AppColorsProfile.whiteBack,
            onPressed: () {
              print("editar");
            },
          )
        ],
        centerTitle: true,
        backgroundColor: AppColorsProfile.purpleBack,
      ),
      body: Container(),
    );
  }
}
