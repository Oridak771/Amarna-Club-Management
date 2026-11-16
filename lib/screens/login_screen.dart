import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_layout.dart';

/// Connexion — the single sign-in form. Large fields and a 56dp primary
/// button, so it can be used with a tablet held in one hand.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      await ref.read(authProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text,
            rememberMe: _rememberMe,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final authState = ref.watch(authProvider);
    final authenticating = authState.status == AuthStatus.authenticating;

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : ${next.errorMessage}'),
            backgroundColor: colors.danger,
          ),
        );
      } else if (next.status == AuthStatus.authenticated) {
        context.go('/accueil');
      }
    });

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Center(
                      child: Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          color: colors.accentPrimary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: Icon(
                          Icons.sports_hockey_rounded,
                          size: 44,
                          color: colors.accentPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'AMARNA CLUB',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: colors.textPrimary,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Gestion opérationnelle',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 36),
                    AppPanel(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            style: TextStyle(
                                color: colors.textPrimary, fontSize: 16),
                            decoration: InputDecoration(
                              labelText: 'Identifiant / E-mail',
                              labelStyle:
                                  TextStyle(color: colors.textSecondary),
                              prefixIcon: Icon(Icons.person_outline_rounded,
                                  color: colors.textSecondary),
                              hintText: 'Entrez votre identifiant',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Veuillez saisir votre identifiant';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            onFieldSubmitted: (_) => _handleLogin(),
                            style: TextStyle(
                                color: colors.textPrimary, fontSize: 16),
                            decoration: InputDecoration(
                              labelText: 'Mot de passe',
                              labelStyle:
                                  TextStyle(color: colors.textSecondary),
                              prefixIcon: Icon(Icons.lock_outline_rounded,
                                  color: colors.textSecondary),
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword
                                    ? 'Afficher le mot de passe'
                                    : 'Masquer le mot de passe',
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: colors.textSecondary,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              hintText: 'Entrez votre mot de passe',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez saisir votre mot de passe';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          // Whole row toggles the option; the box is 48dp.
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => setState(() => _rememberMe = !_rememberMe),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 48),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: _rememberMe,
                                    activeColor: colors.accentPrimary,
                                    checkColor: colors.textOnAccent,
                                    side: BorderSide(
                                        color: colors.border, width: 1.5),
                                    onChanged: (value) {
                                      setState(() {
                                        _rememberMe = value ?? false;
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Se souvenir de moi',
                                      style: TextStyle(
                                        color: colors.textSecondary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: colors.accentPrimary,
                              foregroundColor: colors.textOnAccent,
                              minimumSize: const Size.fromHeight(56),
                              textStyle: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w800),
                            ),
                            onPressed: authenticating ? null : _handleLogin,
                            child: authenticating
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: colors.textOnAccent,
                                    ),
                                  )
                                : const Text('Connexion'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.fingerprint_rounded,
                          color: colors.textSecondary.withValues(alpha: 0.8),
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Connexion biométrique disponible',
                          style: TextStyle(
                            color: colors.textSecondary.withValues(alpha: 0.8),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
