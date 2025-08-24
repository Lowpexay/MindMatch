import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class AppColorsProfile {
  static const Color whiteBack = Color(0xFFF9FAFA);
  static const Color purpleBack = Color(0xFF6365F1);
  static const Color blackFont = Color(0xFF262626);
  static const Color lightGreyFont = Color(0xFFcac9c9);
}

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreen();
}

class _ProfileEditScreen extends State<ProfileEditScreen> {
  DateTime? selectedDate;
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController birthdayController = TextEditingController();
  final TextEditingController cidadeController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController instagramController = TextEditingController();
  final TextEditingController twitterController = TextEditingController();

  @override
  void dispose() {
    nomeController.dispose();
    birthdayController.dispose();
    cidadeController.dispose();
    emailController.dispose();
    bioController.dispose();
    instagramController.dispose();
    twitterController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        birthdayController.text = DateFormat("dd/MM/yyyy").format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            context.push('/profile');
          },
          icon: const Icon(Icons.cancel_outlined),
          tooltip: "Cancelar",
          color: AppColorsProfile.whiteBack,
        ),
        title: Text(
          "Editar Perfil",
          style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColorsProfile.whiteBack),
        ),
        actions: [
          IconButton(
              onPressed: () => {print("Editar")},
              icon: Icon(Icons.done),
              tooltip: "Salvar",
              color: AppColorsProfile.whiteBack)
        ],
        centerTitle: true,
        backgroundColor: AppColorsProfile.purpleBack,
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SingleChildScrollView(
                child: Container(
              width: MediaQuery.of(context).size.width,
              padding: EdgeInsets.all(30),
              decoration: BoxDecoration(color: AppColorsProfile.purpleBack),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      AvatarPicker(),
                      Text(
                        "Adicionar Foto",
                        style: TextStyle(
                            color: AppColorsProfile.whiteBack,
                            fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                  SizedBox(height: 25),
                  Column(
                    children: [
                      InputDadoPerfil(
                          icon: Icons.person_outline,
                          label: "Nome:",
                          controller: nomeController),
                      SizedBox(height: 25),
                      Column(
                        spacing: 3,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Data de nascimento:",
                            style: TextStyle(
                                color: AppColorsProfile.whiteBack,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                          TextField(
                            controller: birthdayController,
                            readOnly: true,
                            decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColorsProfile.whiteBack,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: AppColorsProfile.lightGreyFont)),
                                prefixIcon: Icon(
                                  Icons.calendar_today_outlined,
                                  color: AppColorsProfile.purpleBack,
                                )),
                            onTap: () => _selectDate(context),
                          )
                        ],
                      ),
                      SizedBox(height: 25),
                      InputDadoPerfil(
                          icon: Icons.location_on_outlined,
                          label: "Cidade:",
                          controller: cidadeController),
                      SizedBox(height: 25),
                      InputDadoPerfil(
                          icon: Icons.email,
                          label: "Email:",
                          controller: emailController),
                      SizedBox(height: 25),
                      Column(
                        spacing: 3,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Bio: ",
                            style: TextStyle(
                                color: AppColorsProfile.whiteBack,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                          TextField(
                            controller: bioController,
                            maxLines: 5,
                            minLines: 3,
                            keyboardType: TextInputType.multiline,
                            decoration: InputDecoration(
                              hintText: "Bio",
                              hintStyle: TextStyle(
                                  color: AppColorsProfile.lightGreyFont),
                              filled: true,
                              fillColor: AppColorsProfile.whiteBack,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: AppColorsProfile.lightGreyFont)),
                            ),
                          )
                        ],
                      ),
                      SizedBox(height: 25),
                      InputDadoPerfil(
                          icon: Icons.camera_alt_outlined,
                          label: "Instagram:",
                          controller: instagramController),
                      SizedBox(height: 25),
                      InputDadoPerfil(
                          icon: Icons.wifi_tethering_outlined,
                          label: "Twitter:",
                          controller: twitterController),
                    ],
                  )
                ],
              ),
            ))
          ],
        ),
      ),
    );
  }
}

class InputDadoPerfil extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextEditingController controller;

  // ignore: use_super_parameters
  const InputDadoPerfil({
    Key? key,
    required this.icon,
    required this.label,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 3,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
              color: AppColorsProfile.whiteBack,
              fontWeight: FontWeight.bold,
              fontSize: 16),
        ),
        TextField(
          controller: controller,
          decoration: InputDecoration(
              hintText: label,
              hintStyle: TextStyle(color: AppColorsProfile.lightGreyFont),
              filled: true,
              fillColor: AppColorsProfile.whiteBack,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: AppColorsProfile.lightGreyFont)),
              prefixIcon: Icon(
                icon,
                color: AppColorsProfile.purpleBack,
              )),
        )
      ],
    );
  }
}

class AvatarPicker extends StatefulWidget {
  const AvatarPicker({super.key});

  @override
  _AvatarPickerState createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<AvatarPicker> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: CircleAvatar(
          radius: 60,
          backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
          backgroundColor: Colors.grey.shade300,
          child: _imageFile == null
              ? Icon(Icons.add_a_photo, size: 30, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}
