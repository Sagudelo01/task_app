import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'controllers/theme_controller.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';

final _navigatorKey = GlobalKey<NavigatorState>();

// Captured before Supabase initializes, since it may clear the redirect URL.
String? _linkError;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _linkError = _parseLinkError(Uri.base);
  await initSupabase();
  await themeController.load();
  runApp(const SenkaiApp());
}

/// Reads an auth error returned in the redirect URL (e.g. an expired link).
String? _parseLinkError(Uri uri) {
  final params = {...uri.queryParameters, ...Uri.splitQueryString(uri.fragment)};
  if (params['error'] == null && params['error_code'] == null) return null;
  return (params['error_code'] ?? '').contains('expired')
      ? 'El enlace de confirmación expiró. Solicita uno nuevo.'
      : 'El enlace de confirmación no es válido o ya se usó. Solicita uno nuevo.';
}

class SenkaiApp extends StatefulWidget {
  const SenkaiApp({super.key});

  @override
  State<SenkaiApp> createState() => _SenkaiAppState();
}

class _SenkaiAppState extends State<SenkaiApp> {
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    // Routes the user as sessions appear or clear — this makes the email
    // confirmation link land straight on the task list.
    _authSub = supabase.auth.onAuthStateChange.listen((state) {
      final nav = _navigatorKey.currentState;
      if (nav == null) return;
      if (state.event == AuthChangeEvent.signedIn) {
        nav.pushNamedAndRemoveUntil('/home', (_) => false);
      } else if (state.event == AuthChangeEvent.signedOut) {
        nav.pushNamedAndRemoveUntil('/login', (_) => false);
      }
    });

    if (_linkError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showLinkError(_linkError!));
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  void _showLinkError(String message) {
    final ctx = _navigatorKey.currentContext;
    if (ctx == null) return;
    showDialog<void>(
      context: ctx,
      builder: (dctx) => AlertDialog(
        title: const Text('Enlace no válido'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dctx), child: const Text('Cerrar')),
          FilledButton(
            onPressed: () {
              Navigator.pop(dctx);
              _navigatorKey.currentState?.pushNamed('/register');
            },
            child: const Text('Solicitar nuevo'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: themeController,
      builder: (context, mode, _) => MaterialApp(
        title: 'Senkai',
        navigatorKey: _navigatorKey,
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
