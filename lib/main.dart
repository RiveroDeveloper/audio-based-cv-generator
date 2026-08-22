import 'package:flutter/material.dart';
import 'package:scanner_personal/Perfil_Cv/perfill.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:scanner_personal/Login/screens/auth_router.dart';
import 'package:scanner_personal/Login/screens/change_password_screen.dart';
import 'package:scanner_personal/Login/screens/login_screen.dart';
import 'package:scanner_personal/Login/screens/registro_screen.dart';
import 'package:scanner_personal/Home/home.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:js' as js;

import '../Configuracion/mainConfig.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Compile-time defines (--dart-define) work on all platforms, including web
String? _fromDartDefine(String key) {
  switch (key) {
    case 'SUPABASE_URL':
      return const String.fromEnvironment('SUPABASE_URL');
    case 'SUPABASE_ANON_KEY':
      return const String.fromEnvironment('SUPABASE_ANON_KEY');
    case 'ELEVENLABS_API_KEY':
      return const String.fromEnvironment('ELEVENLABS_API_KEY');
    case 'OPENROUTER_API_KEY':
      return const String.fromEnvironment('OPENROUTER_API_KEY');
    default:
      return null;
  }
}

// Helper function to get environment variables across platforms
String? getEnvironmentVariable(String key) {
  final fromDefines = _fromDartDefine(key);
  if (fromDefines != null && fromDefines.isNotEmpty) {
    return fromDefines;
  }

  if (kIsWeb) {
    try {
      // For web builds, try to get from window.ENV first
      final env = js.context['ENV'];
      if (env != null) {
        return env[key];
      }
    } catch (e) {
      print('Error accessing window.ENV: $e');
    }
  }

  // For other platforms or fallback, use dotenv
  return dotenv.env[key];
}

Future<void> main() async {
  usePathUrlStrategy();

  WidgetsFlutterBinding.ensureInitialized();

  // Cargar variables de entorno con mejor manejo de errores
  String? supabaseUrl;
  String? supabaseAnonKey;

  try {
    print('🔄 Loading environment variables...');

    // Load .env file (bundled as an asset on web, from disk on other platforms)
    await dotenv.load(fileName: ".env");

    // Get environment variables using our helper function
    supabaseUrl = getEnvironmentVariable('SUPABASE_URL');
    supabaseAnonKey = getEnvironmentVariable('SUPABASE_ANON_KEY');

    print('✅ Environment variables loaded');
    print('📡 URL: ${supabaseUrl != null && supabaseUrl!.length > 20 ? supabaseUrl!.substring(0, 20) : supabaseUrl}...');
    print('🔑 Key: ${supabaseAnonKey != null && supabaseAnonKey!.length > 20 ? supabaseAnonKey!.substring(0, 20) : supabaseAnonKey}...');
  } catch (e) {
    print('⚠️ Error loading environment variables: $e');
    print('🔄 Using hardcoded credentials as fallback...');

    // Fallback to hardcoded credentials if everything fails (must match .env)
    supabaseUrl = 'https://mujuqbmzksvvqmhssvls.supabase.co';
    supabaseAnonKey =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im11anVxYm16a3N2dnFtaHNzdmxzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEzNDkwMjYsImV4cCI6MjA4NjkyNTAyNn0._-AV69Jgc0iWjCVCTb9Te-d0MyNhy1qfJKTDmSGrHsY';
  }

  // Ensure we have valid credentials
  if (supabaseUrl == null || supabaseAnonKey == null) {
    throw Exception('Supabase credentials are required but not found');
  }

  try {
    print('🚀 Initializing Supabase...');
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
    print('✅ Supabase initialized successfully');
  } catch (e) {
    print('❌ Error initializing Supabase: $e');
    throw Exception('Error initializing Supabase: $e');
  }

  print('🎯 Starting application...');
  runApp(MyApp());
}

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      initialRoute: '/',
      routes: {
        '/': (_) => const AuthRouter(),
        '/login': (_) => const LoginScreen(),
        '/registro': (_) => RegistroScreen(),
        '/home': (_) => HomeScreen(),
        '/change-password': (_) => CambiarPasswordScreen(),
        '/perfil': (_) => ProfileScreen(),
      },
      onGenerateRoute: (settings) {
        print('🔀 Navigating to: ${settings.name}');
        return null; // Use default routes
      },
    );
  }
}
