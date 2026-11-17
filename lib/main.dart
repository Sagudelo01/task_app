import 'package:flutter/material.dart';
import 'config/supabase_config.dart';
import 'controllers/theme_controller.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSupabase();
  await themeController.load();
  runApp(const SenkaiApp());
}

class SenkaiApp extends StatelessWidget {
  const SenkaiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: themeController,
      builder: (context, mode, _) => MaterialApp(
        title: 'Senkai',
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: mode,
        initialRoute: supabase.auth.currentSession != null ? '/home' : '/login',
        routes: {
          '/login': (_) => const LoginScreen(),
          '/register': (_) => const RegisterScreen(),
          '/home': (_) => const HomeScreen(),
        },
      ),
    );
  }
}
