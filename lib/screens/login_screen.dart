import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

import 'dart:async'; // 3.1 Importar el timer

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscure = true;

  // 1.1 Crear el cerebro de la animación
  StateMachineController? _controller;

  // SMI: State Machine Input / Entrada de máquina de estado
  SMIBool? _isChecking;
  SMIBool? _isHandsUp;
  SMITrigger? _trigSuccess;
  SMITrigger? _trigFail;

  // 3.2 Variable del recorrido de la mirada
  SMINumber? _numLook;

  // 3.3 Timer para detener la mirada al dejar de escribir
  Timer? _typingDebounce;

  // 2.1 Crear las variables para FocusNode
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  // 4.1 Controllers que manipulan lo que el usuario escribe (corregidos con guion bajo)
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  // 4.2 Errores para mostrarlos en la UI
  String? emailError;
  String? passError;

  // 4.3 Validadores
  bool isValidEmail(String email) {
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return re.hasMatch(email);
  }

  bool isValidPassword(String pass) {
    final re = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$',
    );
    return re.hasMatch(pass);
  }

  // 4.4 Dar acción al botón
  void _onLogin() {
    // De lo que escribió el usuario, quitar espacios en blanco
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    // 4.6 Evaluar los errores
    final eError = isValidEmail(email) ? null : "Invalid email";
    final pError = isValidPassword(pass) ? null : "Invalid password";

    // 4.7 Avisar que hubo cambios
    setState(() {
      emailError = eError;
      passError = pError;
    });

    // 4.8 Cerrar el teclado y bajar las manos
    FocusScope.of(context).unfocus(); // Quita el foco
    _typingDebounce?.cancel();
    _isChecking?.change(false);
    _isHandsUp?.change(false);
    _numLook?.value = 50.0;

    // 4.9 Activar triggers
    if (eError == null && pError == null) {
      _trigSuccess?.fire();
    } else {
      _trigFail?.fire();
    }
  }

  // 2.2 Listeners (escuchadores de foco)
  @override
  void initState() {
    super.initState();

    _emailFocus.addListener(() {
      if (_emailFocus.hasFocus) {
        // Al tomar foco el email, el oso mira el texto y baja las manos
        _isChecking?.change(true);
        _isHandsUp?.change(false);
      } else {
        // Al perder el foco, quita la mirada activa
        _isChecking?.change(false);
      }
    });

    _passwordFocus.addListener(() {
      // Manos arriba si la contraseña tiene el foco y está oculta
      if (_passwordFocus.hasFocus) {
        _isChecking?.change(false);
        _isHandsUp?.change(_obscure);
      } else {
        _isHandsUp?.change(false);
      }
    });
  }

  // 2.4 Liberar espacio en memoria
  @override
  void dispose() {
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _typingDebounce?.cancel(); // 3.9 Eliminar el timer
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Para obtener el tamaño de la pantalla
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                SizedBox(
                  width: size.width,
                  height: 200,
                  child: RiveAnimation.asset(
                    'assets/login-bear.riv',
                    stateMachines: const ['Login Machine'],

                    // 1.2 Vincular animación
                    onInit: (artboard) {
                      _controller = StateMachineController.fromArtboard(
                        artboard,
                        'Login Machine',
                      );

                      // 1.3 Verificar que inició bien
                      if (_controller == null) return;

                      // Agrega el controlador al escenario / tablero
                      artboard.addController(_controller!);

                      // Vinculamos variables de Rive
                      _isChecking = _controller!.findSMI('isChecking');
                      _isHandsUp = _controller!.findSMI('isHandsUp');
                      _trigSuccess = _controller!.findSMI('trigSuccess');
                      _trigFail = _controller!.findSMI('trigFail');
                      _numLook = _controller!.findSMI('numLook');
                    },
                  ),
                ),

                // Espacio entre animación y campos
                const SizedBox(height: 10),

                // Campo de texto para Email
                TextField(
                  // 4.10 Enlazar controller
                  controller: _emailCtrl,

                  // 2.3 Asignar foco al campo de texto
                  focusNode: _emailFocus,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (value) {
                    if (_isChecking != null) {
                      // Activar modo mirar el texto
                      _isChecking!.change(true);

                      // 3.6 Calcular posición de la mirada según longitud del texto (rango 0 a 100)
                      final look = (value.length / 80.0 * 100.0).clamp(
                        0.0,
                        100.0,
                      );
                      _numLook?.value = look;

                      // 3.7 Debounce: si vuelve a teclear, reinicia el temporizador
                      _typingDebounce?.cancel();
                      _typingDebounce = Timer(const Duration(seconds: 3), () {
                        if (!mounted) return;
                        // Transcurridos 3 seg sin teclear, deshabilita la mirada activa
                        _isChecking?.change(false);
                      });
                    }

                    if (_isHandsUp != null) {
                      // Asegurar manos abajo en el email
                      _isHandsUp!.change(false);
                    }
                  },
                  decoration: InputDecoration(
                    errorText: emailError,
                    hintText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                // Espacio entre Email y Contraseña
                const SizedBox(height: 10),

                // Campo de texto para contraseña
                TextField(
                  // 4.10 Enlazar controller
                  controller: _passCtrl,

                  // 2.3 Asignar foco al campo de texto
                  focusNode: _passwordFocus,
                  obscureText: _obscure,
                  onChanged: (value) {
                    if (_isHandsUp != null) {
                      // Taparse los ojos si la contraseña está oculta
                      _isHandsUp!.change(_obscure);
                    }

                    if (_isChecking != null) {
                      _isChecking!.change(false);
                    }
                  },
                  decoration: InputDecoration(
                    errorText: passError,
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscure = !_obscure;

                          // Si muestra la contraseña, baja las manos; si la oculta, se tapa los ojos
                          if (_isHandsUp != null) {
                            _isHandsUp!.change(_obscure);
                          }
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // 4.12 Texto olvidé la contraseña (CORREGIDO)
                SizedBox(
                  width: size.width,
                  child: const Text(
                    'Forgot password?',
                    textAlign: TextAlign.right, // Debe ir dentro del Text
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                    ), // Debe ir dentro del Text
                  ),
                ),
                const SizedBox(height: 10),

                // 4.13 Boton de login (CORREGIDO)
                MaterialButton(
                  minWidth: size.width,
                  height: 50,
                  color: Colors.pinkAccent,
                  shape: const RoundedRectangleBorder(), // Ahora está vacío y correcto
                  onPressed: _onLogin, // Debe ir fuera del shape
                  child: const Text(
                    'Login',
                    style: TextStyle(color: Colors.white),
                  ), // Debe ir fuera del shape
                ),
                const SizedBox(height: 10),

                SizedBox(
                  width: size.width,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? "),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'Sign up',
                          style: TextStyle(
                            color: Colors.black,
                            // Subrayado
                            decoration: TextDecoration.underline,
                            // Negritas
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
