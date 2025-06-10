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

// Helper function to get environment variables across platforms
String? getEnvironmentVariable(String key) {
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

    // Try to load .env file (works for development)
    if (!kIsWeb) {
      await dotenv.load(fileName: ".env");
    }

    // Get environment variables using our helper function
    supabaseUrl = getEnvironmentVariable('SUPABASE_URL');
    supabaseAnonKey = getEnvironmentVariable('SUPABASE_ANON_KEY');

    print('✅ Environment variables loaded');
    print('📡 URL: ${supabaseUrl?.substring(0, 20)}...');
    print('🔑 Key: ${supabaseAnonKey?.substring(0, 20)}...');
  } catch (e) {
    print('⚠️ Error loading environment variables: $e');
    print('🔄 Using hardcoded credentials as fallback...');

    // Fallback to hardcoded credentials if everything fails
    supabaseUrl = 'https://pjibtcshdaewixdcvdtx.supabase.co';
    supabaseAnonKey =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBqaWJ0Y3NoZGFld2l4ZGN2ZHR4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk1MTg5NDcsImV4cCI6MjA2NTA5NDk0N30.jEfczCIWrpnQBuDrIPlX8z6xX1L_UqGGIR1AGLHfR0A';
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
