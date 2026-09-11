import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    //Para obtener el tamaño de la pantalla
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              SizedBox(
                width: size.width,
                height: 200,
                child: RiveAnimation.asset('assets/login-bear.riv'),
              ), // SizedBox
              //Para separar espacios
              SizedBox(height: 10),
              TextField(
                //Para mostrar el tipo de teclado
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    //Para redondear los bordes
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              //Espacio entre Email y Contraseña
              SizedBox(height: 10),
              //campo de texto para contraseña
              TextField(
                obscureText: _obscure,
                decoration: InputDecoration(
                  hintText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    //operador ternario
                    icon: Icon(
                      _obscure ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      //Refrescar el icono
                      setState(() {
                        _obscure = !_obscure;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    //Para redondear los bordes
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ), // Column
        ), // Padding
      ), // SafeArea
    ); // Scaffold
  }
}
