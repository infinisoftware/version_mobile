import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../core/i18n.dart';
import '../../theme/app_colors.dart';
import '../shell/language_switcher.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  bool _showPassword = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit(Translate t) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(authProvider.notifier).login(_identifier.text, _password.text);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = apiErrorMessage(
          error,
          t(
            'Invalid email, username or password. Please verify your credentials.',
            "Email, nom d'utilisateur ou mot de passe incorrect. Veuillez vérifier vos identifiants.",
            'Correo, nombre de usuario o contraseña incorrectos. Verifica tus datos.',
          ),
        );
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// Sign-up is not in the app yet: the website's form opens in the browser.
  Future<void> _openSignUp(Translate t) async {
    final opened = await launchUrl(
      Uri.parse('${AppConfig.websiteUrl}/register'),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t(
              'Could not open the browser. Sign up at giftexchangeglobal.com/register',
              "Impossible d'ouvrir le navigateur. Inscrivez-vous sur giftexchangeglobal.com/register",
              'No se pudo abrir el navegador. Regístrate en giftexchangeglobal.com/register',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translateProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 52,
        actions: const [LanguageSwitcher(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  Image.asset('assets/images/logo.png', width: 96, height: 96),
                  const SizedBox(height: 12),
                  const Text(
                    'THE GIFT EXCHANGE',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1.2),
                  ),
                  const Text('Global', style: TextStyle(color: AppColors.action, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_error != null) ...[
                            Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                            const SizedBox(height: 12),
                          ],
                          TextFormField(
                            controller: _identifier,
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.username],
                            decoration: InputDecoration(
                              labelText: t('Email or username', "Email ou nom d'utilisateur", 'Correo o nombre de usuario'),
                            ),
                            validator: (value) => (value ?? '').trim().length < 2
                                ? t(
                                    'Please enter your email or username',
                                    "Veuillez saisir votre email ou nom d'utilisateur",
                                    'Ingresa tu correo o nombre de usuario',
                                  )
                                : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _password,
                            obscureText: !_showPassword,
                            autofillHints: const [AutofillHints.password],
                            onFieldSubmitted: (_) => _submit(t),
                            decoration: InputDecoration(
                              labelText: t('Password', 'Mot de passe', 'Contraseña'),
                              suffixIcon: IconButton(
                                tooltip: _showPassword
                                    ? t('Hide password', 'Masquer le mot de passe', 'Ocultar contraseña')
                                    : t('Show password', 'Afficher le mot de passe', 'Mostrar contraseña'),
                                icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                                onPressed: () => setState(() => _showPassword = !_showPassword),
                              ),
                            ),
                            validator: (value) => (value ?? '').length < 6
                                ? t(
                                    'Password must be at least 6 characters',
                                    'Le mot de passe doit contenir au moins 6 caractères',
                                    'La contraseña debe tener al menos 6 caracteres',
                                  )
                                : null,
                          ),
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: _submitting ? null : () => _submit(t),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _submitting
                                ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : Text(
                                    t('Sign in', 'Se connecter', 'Iniciar sesión'),
                                    style: const TextStyle(fontWeight: FontWeight.w800),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    t("Don't have an account?", "Vous n'avez pas de compte ?", '¿No tienes una cuenta?'),
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => _openSignUp(t),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      foregroundColor: AppColors.action,
                      side: const BorderSide(color: AppColors.action),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      t('Sign up', "S'inscrire", 'Registrarse'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
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
