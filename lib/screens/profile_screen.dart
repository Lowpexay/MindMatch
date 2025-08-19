import 'package:flutter/material.dart';

<<<<<<< HEAD
class AppColorsProfile {
  static const Color whiteBack = Color(0xFFF9FAFA);
  static const Color purpleBack = Color(0xFF6365F1);
}

=======
>>>>>>> 0d94b621915f181fdb5d4de3f1095f1994610f9c
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
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
              color: AppColorsProfile.whiteBack, fontWeight: FontWeight.bold),
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
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height * 0.4,
              decoration: BoxDecoration(
                  color: AppColorsProfile.purpleBack,
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12))),
            ),
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                  border: Border.all(
                      color: Colors.black, width: 2, style: BorderStyle.solid)),
            )
          ],
        ),
      ),
    );
  }
}
=======
    return const Scaffold(
      body: Center(
        child: Text("Profile Screen"),
      ),
    );
  }
}
>>>>>>> 0d94b621915f181fdb5d4de3f1095f1994610f9c
