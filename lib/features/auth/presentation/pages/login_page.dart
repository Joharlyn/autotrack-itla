import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/storage/session_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/auth_header_card.dart';
import '../../data/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _matriculaController = TextEditingController();
  final _passwordController = TextEditingController();
  final _forgotMatriculaController = TextEditingController();

  final _authService = AuthService();

  bool _isLoggingIn = false;
  bool _isRecovering = false;

  @override
  void dispose() {
    _matriculaController.dispose();
    _passwordController.dispose();
    _forgotMatriculaController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final matricula = _matriculaController.text.trim();
    final contrasena = _passwordController.text.trim();

    if (matricula.isEmpty || contrasena.isEmpty) {
      _showSnack('Completa matrícula y contraseña.');
      return;
    }

    setState(() => _isLoggingIn = true);

    try {
      final data = await _authService.login(
        matricula: matricula,
        contrasena: contrasena,
      );

      if (!mounted) return;

      await context.read<SessionProvider>().saveAuthData(data);

      _showSnack('Sesión iniciada correctamente.');

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.dashboard,
        (_) => false,
      );
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoggingIn = false);
      }
    }
  }

  Future<void> _forgotPassword() async {
    final matricula = _forgotMatriculaController.text.trim();

    if (matricula.isEmpty) {
      _showSnack('Escribe la matrícula para recuperar la contraseña.');
      return;
    }

    setState(() => _isRecovering = true);

    try {
      await _authService.forgotPassword(matricula);
      _showSnack(
        'Se generó una contraseña temporal. Revisa la respuesta del backend y prueba iniciar sesión.',
      );
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isRecovering = false);
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar sesión'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
        children: [
          const AuthHeaderCard(
            icon: Icons.login_rounded,
            title: 'Bienvenido de vuelta',
            subtitle:
                'Inicia sesión para acceder a tus vehículos, mantenimientos, finanzas y foro privado.',
          ),
          const SizedBox(height: 22),
          AuthSectionCard(
            title: 'Acceso a la cuenta',
            subtitle:
                'Ingresa con tu matrícula y contraseña para continuar dentro de la aplicación.',
            children: [
              TextField(
                controller: _matriculaController,
                decoration: const InputDecoration(
                  labelText: 'Matrícula',
                  hintText: '2023-0181',
                  prefixIcon: Icon(Icons.badge_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  hintText: '******',
                  prefixIcon: Icon(Icons.lock_rounded),
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _isLoggingIn ? null : _login,
                icon: const Icon(Icons.login_rounded),
                label: Text(
                  _isLoggingIn ? 'Entrando...' : 'Iniciar sesión',
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.registerActivation,
                  );
                },
                child: const Text('¿No has activado tu cuenta todavía?'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          AuthSectionCard(
            title: 'Recuperar contraseña',
            subtitle:
                'Solicita una clave temporal usando tu matrícula institucional.',
            children: [
              TextField(
                controller: _forgotMatriculaController,
                decoration: const InputDecoration(
                  labelText: 'Matrícula',
                  hintText: '2023-0181',
                  prefixIcon: Icon(Icons.key_rounded),
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _isRecovering ? null : _forgotPassword,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(
                  _isRecovering ? 'Procesando...' : 'Recuperar contraseña',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}