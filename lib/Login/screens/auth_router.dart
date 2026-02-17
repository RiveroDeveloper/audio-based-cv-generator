import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:scanner_personal/Login/screens/login_screen.dart';

class AuthRouter extends StatefulWidget {
  const AuthRouter({super.key});

  @override
  State<AuthRouter> createState() => _AuthRouterState();
}

class _AuthRouterState extends State<AuthRouter> {
  late StreamSubscription _authSubscription;
  Timer? _timeoutTimer;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    print('🚀 AuthRouter: Inicializando...');

    // Timeout de emergencia que siempre funciona
    _timeoutTimer = Timer(const Duration(seconds: 5), () {
      print('⏰ TIMEOUT: Navegando a login por timeout');
      _navigateToLogin();
    });

    // Intentar navegación inmediata
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndNavigate();
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _navigateToLogin() {
    if (!_hasNavigated && mounted) {
      _hasNavigated = true;
      _timeoutTimer?.cancel();
      print('🔄 Navegando a LOGIN');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      });
    }
  }

  void _navigateToHome() {
    if (!_hasNavigated && mounted) {
      _hasNavigated = true;
      _timeoutTimer?.cancel();
      print('🔄 Navegando a HOME');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      });
    }
  }

  void _navigateToChangePassword() {
    if (!_hasNavigated && mounted) {
      _hasNavigated = true;
      _timeoutTimer?.cancel();
      print('🔄 Navegando a CAMBIO DE CONTRASEÑA');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/change-password');
        }
      });
    }
  }

  Future<void> _checkAuthAndNavigate() async {
    try {
      print('🔍 Verificando autenticación...');

      // Verificar token de recuperación (Supabase lo envía en el hash #, no en query)
      final uri = Uri.base;
      String? type = uri.queryParameters['type'];
      String? accessToken = uri.queryParameters['access_token'];

      if (uri.fragment.isNotEmpty) {
        final fragmentParams = Uri.splitQueryString(uri.fragment);
        type ??= fragmentParams['type'];
        accessToken ??= fragmentParams['access_token'];
      }

      print('🔗 URI: ${uri.path}');
      print('📩 type: $type');
      print('🔑 access_token: ${accessToken != null ? 'SÍ' : 'NO'}');

      // Si hay recovery token, ir a cambio de contraseña
      if (type == 'recovery' && accessToken != null) {
        print('🛠 Token de recuperación detectado');
        try {
          await Supabase.instance.client.auth.setSession(accessToken);
          _navigateToChangePassword();
          return;
        } catch (e) {
          print('❌ Error con token de recovery: $e');
        }
      }

      // Verificar sesión actual
      final session = Supabase.instance.client.auth.currentSession;
      print('👤 Sesión actual: ${session?.user.email ?? 'NINGUNA'}');

      if (session != null && !session.isExpired) {
        print('✅ Usuario autenticado, navegando a home');
        _navigateToHome();
      } else {
        print('❌ No hay sesión válida, navegando a login');
        _navigateToLogin();
      }

      // Configurar listener DESPUÉS de la navegación inicial
      _setupAuthListener();
    } catch (e, stackTrace) {
      print('❌ Error en verificación: $e');
      print('📍 Stack: $stackTrace');
      _navigateToLogin();
    }
  }

  void _setupAuthListener() {
    try {
      print('🔔 Configurando listener de auth...');
      _authSubscription = Supabase.instance.client.auth.onAuthStateChange
          .listen(
            (data) {
              if (!mounted || _hasNavigated) return;

              final event = data.event;
              final session = data.session;

              print('🔄 Auth cambió: $event');

              switch (event) {
                case AuthChangeEvent.signedIn:
                  if (session != null) {
                    _navigateToHome();
                  }
                  break;
                case AuthChangeEvent.signedOut:
                  _navigateToLogin();
                  break;
                default:
                  break;
              }
            },
            onError: (error) {
              print('❌ Error en auth listener: $error');
              _navigateToLogin();
            },
          );
    } catch (e) {
      print('❌ Error configurando listener: $e');
      _navigateToLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    return const LoginScreen();
  }
}
