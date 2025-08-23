import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppColorsProfile {
  static const Color whiteBack = Color(0xFFF9FAFA);
  static const Color purpleBack = Color(0xFF6365F1);
  static const Color blackFont = Color(0xFF262626);
  static const Color lightGreyFont = Color(0xFFcac9c9);
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
            context.go('/home');
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
              context.push('/profileEdit');
            },
          )
        ],
        centerTitle: true,
        backgroundColor: AppColorsProfile.purpleBack,
      ),
      body: SingleChildScrollView(
        //Tela perfil
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height * 0.3,
              decoration: BoxDecoration(
                  color: AppColorsProfile.purpleBack,
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12))),
              child: FractionallySizedBox(
                //Faz o redimencionamento do container em relação ao container pai
                widthFactor: 0.8,
                heightFactor: 0.8,
                alignment: Alignment.center,
                child: Container(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      //Foto Avatar
                      CircleAvatar(
                        radius: 50,
                        backgroundImage:
                            AssetImage("assets/images/luma_chat_avatar.png"),
                      ),
                      //Nome
                      Text(
                        'Gustavo Teodoro Gabilan',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppColorsProfile.whiteBack),
                      ),
                      //Idade
                      Text(
                        '20 Anos',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.normal,
                            color: AppColorsProfile.whiteBack),
                      ),
                      //Localizacao
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_on,
                            color: AppColorsProfile.whiteBack,
                            size: 15,
                          ),
                          Text(
                            "São Paulo",
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.normal,
                                color: AppColorsProfile.whiteBack),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
            //Quandrado de Baixo
            SingleChildScrollView(
              child: Container(
                width: MediaQuery.of(context).size.width,
                padding: EdgeInsets.all(30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //Classes para dados de texto
                    DadoPerfil(
                      dado: 'gustavogabilan77@gmail.com',
                      label: 'E-mail:',
                      icon: Icons.email_outlined,
                    ),
                    SizedBox(height: 25),
                    DadoPerfil(
                      dado: 'awdffwdawdawsdawd',
                      label: 'Bio:',
                      icon: Icons.chat_outlined,
                    ),
                    SizedBox(height: 25),
                    DadoPerfil(
                      dado: '@gustavo_gabi_ig',
                      label: 'Instagram:',
                      icon: Icons.camera_alt_outlined,
                    ),
                    SizedBox(height: 25),
                    DadoPerfil(
                      dado: '@gustavo_gabi_tt',
                      label: 'Twitter:',
                      icon: Icons.wifi_tethering_outlined,
                    ),
                    SizedBox(height: 25),
                    //Dados de Interesse
                    Column(
                      spacing: 5,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        //Label
                        Row(
                          children: [
                            Icon(
                              Icons.star_outline,
                              color: AppColorsProfile.purpleBack,
                            ),
                            Text(
                              'Interesses',
                              style: TextStyle(
                                  color: AppColorsProfile.purpleBack,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            )
                          ],
                        ),
                        //Interesses
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            InteressesLabel(
                              dado: "tecnologia",
                            ),
                            InteressesLabel(
                              dado: "saúde mental",
                            ),
                            InteressesLabel(
                              dado: "esportes",
                            )
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 25),
                    Column(
                      spacing: 5,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        //Label
                        Row(
                          children: [
                            Icon(
                              Icons.rocket_launch_outlined,
                              color: AppColorsProfile.purpleBack,
                            ),
                            Text(
                              'Interesses',
                              style: TextStyle(
                                  color: AppColorsProfile.purpleBack,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            )
                          ],
                        ),
                        //Interesses
                        Container(
                            width: double.infinity,
                            alignment: Alignment.centerLeft,
                            padding: EdgeInsets.all(12),
                            height: 50,
                            decoration: BoxDecoration(
                                color: AppColorsProfile.whiteBack,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: AppColorsProfile.lightGreyFont),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ]),
                            child: Row(
                              spacing: 12,
                              children: [
                                Text(
                                  '🤝',
                                  style: TextStyle(
                                      color: AppColorsProfile.blackFont,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Fazer Novas Amizades',
                                  style: TextStyle(
                                      color: AppColorsProfile.blackFont,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold),
                                )
                              ],
                            ))
                      ],
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

//Widget dos Dados
class DadoPerfil extends StatelessWidget {
  final IconData icon;
  final String label;
  final String dado;

  // ignore: use_super_parameters
  const DadoPerfil({
    Key? key,
    required this.icon,
    required this.label,
    required this.dado,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 3,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: AppColorsProfile.purpleBack,
            ),
            Text(
              label,
              style: TextStyle(
                  color: AppColorsProfile.purpleBack,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            )
          ],
        ),
        Text(
          dado,
          style: TextStyle(
              color: AppColorsProfile.blackFont,
              fontWeight: FontWeight.bold,
              fontSize: 18),
        )
      ],
    );
  }
}

class InteressesLabel extends StatelessWidget {
  final String dado;

  // ignore: use_super_parameters
  const InteressesLabel({
    Key? key,
    required this.dado,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColorsProfile.lightGreyFont),
        ),
        child: Text("#$dado",
            style: TextStyle(
              color: AppColorsProfile.blackFont,
              fontWeight: FontWeight.w600,
            )));
  }
}
