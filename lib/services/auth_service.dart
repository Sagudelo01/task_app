import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Authentication against Supabase Auth.
class AuthService {
  static String? get _redirect =>
      supabaseRedirectUrl.isNotEmpty ? supabaseRedirectUrl : null;

  Future<void> signIn(String email, String password) =>
      supabase.auth.signInWithPassword(email: email, password: password);

  Future<AuthResponse> signUp(String email, String password) =>
      supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: _redirect,
      );

  /// Resends the sign-up confirmation email.
  Future<void> resendConfirmation(String email) => supabase.auth.resend(
        type: OtpType.signup,
        email: email,
        emailRedirectTo: _redirect,
      );

  Future<void> signOut() => supabase.auth.signOut();
}
