import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';

const _resendCooldown = 45;

/// Shown right after sign-up: tells the user to confirm their account and
/// offers to open their inbox or resend the confirmation email.
class CheckEmailScreen extends StatefulWidget {
  const CheckEmailScreen({super.key, required this.email});
  final String email;

  @override
  State<CheckEmailScreen> createState() => _CheckEmailScreenState();
}

class _CheckEmailScreenState extends State<CheckEmailScreen> {
  final _auth = AuthService();
  Timer? _timer;
  int _secondsLeft = 0;
  bool _resending = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _domain => widget.email.split('@').last.toLowerCase();

  /// Returns (label, url) for the inbox button, or a generic mail-app action.
  (String, String?) get _mailButton {
    const webmail = {
      'gmail.com': ('Abrir Gmail', 'https://mail.google.com/mail/'),
      'googlemail.com': ('Abrir Gmail', 'https://mail.google.com/mail/'),
      'outlook.com': ('Abrir Outlook', 'https://outlook.live.com/mail/'),
      'hotmail.com': ('Abrir Outlook', 'https://outlook.live.com/mail/'),
      'live.com': ('Abrir Outlook', 'https://outlook.live.com/mail/'),
      'yahoo.com': ('Abrir Yahoo Mail', 'https://mail.yahoo.com/'),
      'icloud.com': ('Abrir iCloud Mail', 'https://www.icloud.com/mail/'),
      'proton.me': ('Abrir Proton Mail', 'https://mail.proton.me/'),
    };
    final match = webmail[_domain];
    if (match != null) return match;
    return ('Abrir app de correo', null);
  }

  Future<void> _openMail() async {
    final (_, url) = _mailButton;
    final uri = Uri.parse(url ?? 'mailto:');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el correo')),
        );
      }
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      await _auth.resendConfirmation(widget.email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Correo de confirmación reenviado')),
      );
      _startCooldown();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo reenviar. Intenta de nuevo en un momento.')),
        );
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  void _startCooldown() {
    setState(() => _secondsLeft = _resendCooldown);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) {
        t.cancel();
        if (mounted) setState(() => _secondsLeft = 0);
      } else if (mounted) {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (mailLabel, _) = _mailButton;
    final onCooldown = _secondsLeft > 0;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.mark_email_unread_outlined,
                    size: 72, color: theme.colorScheme.primary),
                const SizedBox(height: 20),
                Text('Revisa tu correo',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall),
                const SizedBox(height: 10),
                Text.rich(
                  TextSpan(
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                    children: [
                      const TextSpan(text: 'Enviamos un enlace de confirmación a\n'),
                      TextSpan(
                          text: widget.email,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const TextSpan(
                          text: '.\nÁbrelo para activar tu cuenta y luego inicia sesión.'),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: _openMail,
                  icon: const Icon(Icons.open_in_new),
                  label: Text(mailLabel),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: (onCooldown || _resending) ? null : _resend,
                  child: _resending
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(onCooldown
                          ? 'Reenviar en ${_secondsLeft}s'
                          : 'Reenviar correo de confirmación'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () =>
                      Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false),
                  child: const Text('Volver al inicio de sesión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
