import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Inicia Supabase. Las claves se toman de dart-define en producción,
// o de dotenv (.env) como respaldo en desarrollo local.
Future<void> initSupabase() async {
  // Producción: definidas con --dart-define al hacer build
  const prodUrl = String.fromEnvironment('SUPABASE_URL');
  const prodKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  // Si dart-define está vacío, se usa dotenv (desarrollo local)
  final url = prodUrl.isNotEmpty ? prodUrl : dotenv.env['SUPABASE_URL']!;
  final publishableKey =
      prodKey.isNotEmpty ? prodKey : dotenv.env['SUPABASE_ANON_KEY']!;

  await Supabase.initialize(
    url: url,
    publishableKey: publishableKey,
  );
}

// Acceso rápido desde cualquier parte de la app
final supabase = Supabase.instance.client;
