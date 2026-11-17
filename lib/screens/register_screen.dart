import 'package:flutter/material.dart';
import '../services/auth_service.dart';

// Pantalla de registro de nuevos usuarios
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controladores y estado del formulario
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _error;

  // Valida el formulario y crea la cuenta en Supabase
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _authService.signUp(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registro exitoso. Revisa tu email para confirmar la cuenta.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _error = 'Error al registrarse. Intenta con otro email.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Libera los controladores al cerrar la pantalla
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          // Formulario de registro: email y contraseña con validación
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_add_outlined, size: 80,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 16),
                Text('Crear cuenta', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text('Senkai', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa tu email';
                    }
                    // Verifica formato básico de email (texto@texto.texto)
                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                        .hasMatch(value.trim())) {
                      return 'Ingresa un email válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _register(),
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: Icon(Icons.lock_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa tu contraseña';
                    }
                    if (value.length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _register,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Registrarse'),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('¿Ya tienes cuenta? Inicia sesión'),
                ),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }
}
