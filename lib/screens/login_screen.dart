import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

import 'dart:async'; // 3.1 Importar el timer

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _obscure = true;

  // ADA 9.1 Estado de Remember me
  bool _rememberMe = false;

  // ADA 9.2 Bandera para saber si la animación está en ejecución
  bool _rememberAnimating = false;

  // ADA 9.3 Controlador de la animación de Remember me
  late AnimationController _rememberController;

  // ADA 9.4 Animación para el efecto del checkbox
  late Animation<double> _rememberScale;

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

  // ADA 9.5 Dar acción al botón Remember me
  void _toggleRememberMe() {
    // ADA 9.6 Si la animación está en curso,
    // ignorar los nuevos clics
    if (_rememberAnimating) return;

    setState(() {
      // ADA 9.7 Bloquear la interacción
      _rememberAnimating = true;

      // ADA 9.8 Cambiar el estado local de Remember me
      _rememberMe = !_rememberMe;
    });

    // ADA 9.9 Iniciar la animación
    _rememberController.forward();
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

    // ADA 9.10 Crear el controlador de la animación
    _rememberController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    // ADA 9.11 Crear efecto de presión en el checkbox
    _rememberScale = Tween<double>(begin: 1.0, end: 0.80).animate(
      CurvedAnimation(parent: _rememberController, curve: Curves.easeInOut),
    );

    // ADA 9.12 Escuchar el estado de la animación
    _rememberController.addStatusListener((status) {
      // ADA 9.13 Cuando llega al final,
      // regresar a su tamaño normal
      if (status == AnimationStatus.completed) {
        _rememberController.reverse();
      }

      // ADA 9.14 Cuando regresó completamente
      // a su estado de reposo
      if (status == AnimationStatus.dismissed) {
        if (!mounted) return;

        setState(() {
          // ADA 9.15 Volver a habilitar los clics
          _rememberAnimating = false;
        });
      }
    });

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

    // ADA 9.16 Liberar el controlador de Remember me
    _rememberController.dispose();

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

                const SizedBox(height: 12),

                // ADA 9.17 Remember me y texto olvidé la contraseña
                SizedBox(
                  width: size.width,

                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,

                    children: [
                      // ADA 9.18 Botón Remember me
                      GestureDetector(
                        // ADA 9.19 Si la animación
                        // está en curso, onTap queda
                        // deshabilitado para evitar spam
                        onTap: _rememberAnimating ? null : _toggleRememberMe,

                        behavior: HitTestBehavior.opaque,

                        child: Row(
                          children: [
                            // ADA 9.20 Animación visual del checkbox
                            ScaleTransition(
                              scale: _rememberScale,

                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),

                                curve: Curves.easeInOut,

                                width: 20,

                                height: 20,

                                decoration: BoxDecoration(
                                  color: _rememberMe
                                      ? Colors.pinkAccent
                                      : Colors.transparent,

                                  borderRadius: BorderRadius.circular(4),

                                  border: Border.all(
                                    color: _rememberMe
                                        ? Colors.pinkAccent
                                        : Colors.black54,

                                    width: 1.5,
                                  ),
                                ),

                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 150),

                                  child: _rememberMe
                                      ? const Icon(
                                          Icons.check,

                                          key: ValueKey('checked'),

                                          size: 15,

                                          color: Colors.white,
                                        )
                                      : const SizedBox(
                                          key: ValueKey('unchecked'),
                                        ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 7),

                            const Text(
                              'Remember me',

                              style: TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),

                      // 4.12 Texto olvidé la contraseña (CORREGIDO)
                      const Text(
                        'Forgot Password?',

                        textAlign: TextAlign.right, // Debe ir dentro del Text

                        style: TextStyle(
                          fontSize: 13,

                          decoration: TextDecoration.underline,
                        ), // Debe ir dentro del Text
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 15),

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
