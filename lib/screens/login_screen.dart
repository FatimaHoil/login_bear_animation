import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'dart:async';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _obscure = true;
  bool _isLoading = false;

  bool _rememberMe = false;
  bool _rememberAnimating = false;
  late AnimationController _rememberController;
  late Animation<double> _rememberScale;

  StateMachineController? _controller;
  SMIBool? _isChecking;
  SMIBool? _isHandsUp;
  SMITrigger? _trigSuccess;
  SMITrigger? _trigFail;
  SMINumber? _numLook;
  Timer? _typingDebounce;

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  String? emailError;
  String? passError;

  bool isValidEmail(String email) {
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return re.hasMatch(email);
  }

  bool isValidPassword(String pass) {
    return pass.length >= 6;
  }

  void _toggleRememberMe() {
    if (_rememberAnimating) return;
    setState(() {
      _rememberAnimating = true;
      _rememberMe = !_rememberMe;
    });
    _rememberController.forward();
  }

  Future<void> _onLogin() async {
    if (_isLoading) return;

    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    final eError = isValidEmail(email) ? null : "Invalid email";
    final pError = isValidPassword(pass)
        ? null
        : "Password must be at least 6 characters";

    setState(() {
      emailError = eError;
      passError = pError;
    });

    FocusScope.of(context).unfocus();
    _typingDebounce?.cancel();
    _isChecking?.change(false);
    _isHandsUp?.change(false);
    _numLook?.value = 50.0;

    if (eError != null || pError != null) {
      _trigFail?.fire();
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pass,
      );

      _trigSuccess?.fire();
      await Future.delayed(const Duration(milliseconds: 1200));
    } on FirebaseAuthException catch (e) {
      _trigFail?.fire();

      String mensaje = 'Authentication failed';
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        mensaje = 'Incorrect email or password';
      } else if (e.code == 'invalid-email') {
        mensaje = 'Invalid email format';
      } else if (e.code == 'too-many-requests') {
        mensaje = 'Too many attempts. Try again later';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensaje), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();

    _rememberController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _rememberScale = Tween<double>(begin: 1.0, end: 0.80).animate(
      CurvedAnimation(parent: _rememberController, curve: Curves.easeInOut),
    );

    _rememberController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _rememberController.reverse();
      }
      if (status == AnimationStatus.dismissed) {
        if (!mounted) return;
        setState(() {
          _rememberAnimating = false;
        });
      }
    });

    _emailFocus.addListener(() {
      if (_emailFocus.hasFocus) {
        _isChecking?.change(true);
        _isHandsUp?.change(false);
      } else {
        _isChecking?.change(false);
      }
    });

    _passwordFocus.addListener(() {
      if (_passwordFocus.hasFocus) {
        _isChecking?.change(false);
        _isHandsUp?.change(_obscure);
      } else {
        _isHandsUp?.change(false);
      }
    });
  }

  @override
  void dispose() {
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _typingDebounce?.cancel();
    _rememberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    onInit: (artboard) {
                      _controller = StateMachineController.fromArtboard(
                        artboard,
                        'Login Machine',
                      );
                      if (_controller == null) return;
                      artboard.addController(_controller!);

                      _isChecking = _controller!.findSMI('isChecking');
                      _isHandsUp = _controller!.findSMI('isHandsUp');
                      _trigSuccess = _controller!.findSMI('trigSuccess');
                      _trigFail = _controller!.findSMI('trigFail');
                      _numLook = _controller!.findSMI('numLook');
                    },
                  ),
                ),

                const SizedBox(height: 10),

                TextField(
                  controller: _emailCtrl,
                  focusNode: _emailFocus,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (value) {
                    if (_isChecking != null) {
                      _isChecking!.change(true);
                      final look = (value.length / 80.0 * 100.0).clamp(
                        0.0,
                        100.0,
                      );
                      _numLook?.value = look;

                      _typingDebounce?.cancel();
                      _typingDebounce = Timer(const Duration(seconds: 3), () {
                        if (!mounted) return;
                        _isChecking?.change(false);
                      });
                    }
                    if (_isHandsUp != null) {
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

                const SizedBox(height: 10),

                TextField(
                  controller: _passCtrl,
                  focusNode: _passwordFocus,
                  obscureText: _obscure,
                  onChanged: (value) {
                    if (_isHandsUp != null) {
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

                SizedBox(
                  width: size.width,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: _rememberAnimating ? null : _toggleRememberMe,
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          children: [
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
                      const Text(
                        'Forgot Password?',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 13,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 15),

                MaterialButton(
                  minWidth: size.width,
                  height: 50,
                  color: Colors.pinkAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onPressed: _isLoading ? null : _onLogin,
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Login',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                            decoration: TextDecoration.underline,
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
