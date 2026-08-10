import '../../config/supabase_config.dart';

class AuthService {
  // Inicia sesión con email y contraseña
  Future<void> signIn(String email, String password) async {
    await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  // Registra un nuevo usuario
  Future<void> signUp(String email, String password) async {
    await supabase.auth.signUp(
      email: email,
      password: password,
    );
  }

  // Cierra la sesión actual
  Future<void> signOut() async {
    await supabase.auth.signOut();
  }
}
