import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/supabase_config.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  // Necesario antes de usar código async en main
  WidgetsFlutterBinding.ensureInitialized();
  // Carga .env para desarrollo local; en producción no existe y se usa dart-define
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    // Sin .env: las claves vendrán de --dart-define
  }
  // Inicia la conexión con Supabase
  await initSupabase();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Senkai',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      // Si ya hay sesión activa, lo lleva a home
      initialRoute: supabase.auth.currentSession != null ? '/home' : '/login',
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/home': (_) => const HomeScreen(),
      },
    );
  }
}
