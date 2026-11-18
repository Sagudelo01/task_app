import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase credentials are injected at build time with `--dart-define`
/// (or `--dart-define-from-file=env.json` for local development).
const _url = String.fromEnvironment('SUPABASE_URL');
const _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

/// Where Supabase sends users after they confirm their email. Must match an
/// entry in the project's Redirect URLs. Empty falls back to the Site URL.
const supabaseRedirectUrl = String.fromEnvironment('SUPABASE_REDIRECT_URL');

Future<void> initSupabase() async {
  assert(
    _url.isNotEmpty && _anonKey.isNotEmpty,
    'Missing SUPABASE_URL / SUPABASE_ANON_KEY. Pass them with --dart-define.',
  );
  await Supabase.initialize(url: _url, publishableKey: _anonKey);
}

/// Global Supabase client, available across the app.
final supabase = Supabase.instance.client;
