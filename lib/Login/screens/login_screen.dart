import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data_base/database_helper.dart';
import 'package:scanner_personal/Home/home.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final FocusNode emailFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();

  String? emailError;
  String? passwordError;
  bool isFormValid = false;
  bool showPassword = false;
  bool emailTouched = false;
  bool passwordTouched = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    emailController.addListener(validarFormulario);
    passwordController.addListener(validarFormulario);

    emailFocus.addListener(() {
      if (emailFocus.hasFocus) {
        setState(() => emailTouched = true);
      }
    });
    passwordFocus.addListener(() {
      if (passwordFocus.hasFocus) {
        setState(() => passwordTouched = true);
      }
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    super.dispose();
  }

  bool validarCorreo(String correo) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(correo) && correo.isNotEmpty;
  }

  bool validarPassword(String password) {
    return password.length >= 6; // Relajamos un poco la validación para login
  }

  void validarFormulario() {
    final correo = emailController.text.trim();
    final password = passwordController.text.trim();

    setState(() {
      emailError = validarCorreo(correo) ? null : 'Correo no válido';
      passwordError =
          validarPassword(password)
              ? null
              : 'La contraseña debe tener al menos 6 caracteres';
      isFormValid =
          emailError == null &&
          passwordError == null &&
          correo.isNotEmpty &&
          password.isNotEmpty;
    });
  }

  Future<void> _iniciarSesion() async {
    if (!_formKey.currentState!.validate()) return;

    validarFormulario();
    if (!isFormValid) return;

    setState(() => isLoading = true);

    final correo = emailController.text.trim();
    final password = passwordController.text.trim();

    try {
      final success = await DatabaseHelper.instance.iniciarSesion(
        correo,
        password,
      );

      if (!mounted) return;

      if (success) {
        await DatabaseHelper.instance.guardarSesion(correo);

        // Use pushNamedAndRemoveUntil to clear navigation stack
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      } else {
        _mostrarError('Incorrect credentials. Check your email and password.');
      }
    } catch (e) {
      if (!mounted) return;
      _mostrarError(
        'Connection error. Check your internet connection and try again.',
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _recuperarPassword() async {
    final TextEditingController correoRecuperacion = TextEditingController();

    final bool? enviar = await showDialog<bool>(
      context: context,
      builder: (context) {
        bool isLoadingDialog = false;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Recover password', style: GoogleFonts.poppins()),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: correoRecuperacion,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We will send you a link to reset your password',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed:
                      isLoadingDialog
                          ? null
                          : () => Navigator.pop(context, false),
                  child: Text('Cancel', style: GoogleFonts.poppins()),
                ),
                ElevatedButton(
                  onPressed:
                      isLoadingDialog
                          ? null
                          : () async {
                            final email = correoRecuperacion.text.trim();
                            if (!validarCorreo(email)) {
                              _mostrarError('Please enter a valid email');
                              return;
                            }

                            setStateDialog(() => isLoadingDialog = true);

                            try {
                              final success = await DatabaseHelper.instance
                                  .recuperarPassword(email);
                              Navigator.pop(context, success);
                            } catch (e) {
                              Navigator.pop(context, false);
                            }
                          },
                  child:
                      isLoadingDialog
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : Text('Send', style: GoogleFonts.poppins()),
                ),
              ],
            );
          },
        );
      },
    );

    if (enviar == true) {
      _mostrarExito('Check your email to continue with the password change');
    } else if (enviar == false) {
      _mostrarError('Error sending recovery email');
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF090467);
    const backgroundColor = Color(0xfff5f5fa);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Login',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFeff8ff),
        foregroundColor: primaryColor,
        elevation: 0,
        automaticallyImplyLeading: false, // Remove back button
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Text(
                'Welcome',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to continue',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              TextFormField(
                controller: emailController,
                focusNode: emailFocus,
                keyboardType: TextInputType.emailAddress,
                enabled: !isLoading,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: GoogleFonts.poppins(),
                  errorText: emailTouched ? emailError : null,
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color:
                          emailTouched && emailError != null
                              ? Colors.red
                              : primaryColor,
                    ),
                  ),
                  prefixIcon: const Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!validarCorreo(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: passwordController,
                focusNode: passwordFocus,
                obscureText: !showPassword,
                enabled: !isLoading,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  labelStyle: GoogleFonts.poppins(),
                  errorText: passwordTouched ? passwordError : null,
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color:
                          passwordTouched && passwordError != null
                              ? Colors.red
                              : primaryColor,
                    ),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      showPassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed:
                        () => setState(() => showPassword = !showPassword),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  textStyle: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: (isFormValid && !isLoading) ? _iniciarSesion : null,
                child:
                    isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : const Text(
                          'Sign In',
                          style: TextStyle(color: Colors.white),
                        ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed:
                    isLoading
                        ? null
                        : () => Navigator.pushNamed(context, '/registro'),
                child: Text(
                  'Create account',
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.blue),
                ),
              ),
              TextButton(
                onPressed: isLoading ? null : _recuperarPassword,
                child: Text(
                  'Forgot my password',
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
