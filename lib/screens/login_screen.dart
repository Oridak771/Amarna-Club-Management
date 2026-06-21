import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      // Navigate to Dashboard
      context.go('/accueil');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.backgroundPrimary,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double horizontalPadding =
                constraints.maxWidth > 600 ? 64.0 : 24.0;
            final double contentWidth =
                constraints.maxWidth > 600 ? 450.0 : double.infinity;

            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: SizedBox(
                  width: contentWidth,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: 40),
                        // Branded Placeholder Logo
                        Icon(
                          Icons.sports_hockey,
                          size: 64,
                          color: context.colors.accentPrimary,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'AMARNA CLUB',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: context.colors.textPrimary,
                            letterSpacing: 1.5,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Gestion Operationnelle',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: context.colors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 48),

                        // Username / Email Field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(color: context.colors.textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Identifiant / E-mail',
                            labelStyle:
                                TextStyle(color: context.colors.textSecondary),
                            prefixIcon: Icon(Icons.person_outline,
                                color: context.colors.textSecondary),
                            hintText: 'Entrez votre identifiant',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Veuillez saisir votre identifiant';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20),

                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: TextStyle(color: context.colors.textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            labelStyle:
                                TextStyle(color: context.colors.textSecondary),
                            prefixIcon: Icon(Icons.lock_outline,
                                color: context.colors.textSecondary),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: context.colors.textSecondary,
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
                        SizedBox(height: 16),

                        // Remember me toggle
                        Row(
                          children: [
                            SizedBox(
                              height: 24,
                              width: 24,
                              child: Checkbox(
                                value: _rememberMe,
                                activeColor: context.colors.accentPrimary,
                                checkColor: Colors.black,
                                side: BorderSide(
                                    color: context.colors.border, width: 1.5),
                                onChanged: (value) {
                                  setState(() {
                                    _rememberMe = value ?? false;
                                  });
                                },
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Se souvenir de moi',
                              style: TextStyle(
                                color: context.colors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 32),

                        // Login button
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.colors.accentPrimary,
                            foregroundColor: context.colors.textOnAccent,
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _handleLogin,
                          child: Text('Connexion'),
                        ),
                        SizedBox(height: 48),

                        // Biometrics hint
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.fingerprint,
                              color: context.colors.textSecondary
                                  .withValues(alpha: 0.8),
                              size: 24,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Connexion biometrique disponible',
                              style: TextStyle(
                                color: context.colors.textSecondary
                                    .withValues(alpha: 0.8),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
