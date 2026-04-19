import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/storage/session_provider.dart';
import '../../../../core/theme/app_theme.dart';
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
      appBar: AppBar(title: const Text('Iniciar sesión')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Acceso',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ingresa con tu matrícula y contraseña.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _matriculaController,
                    decoration: const InputDecoration(
                      labelText: 'Matrícula',
                      hintText: '2023-0181',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      hintText: '******',
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isLoggingIn ? null : _login,
                    child: Text(_isLoggingIn ? 'Entrando...' : 'Entrar'),
                  ),
                  const SizedBox(height: 10),
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
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recuperar contraseña',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Solicita una clave temporal usando tu matrícula.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _forgotMatriculaController,
                    decoration: const InputDecoration(
                      labelText: 'Matrícula',
                      hintText: '2023-0181',
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isRecovering ? null : _forgotPassword,
                    child: Text(_isRecovering ? 'Procesando...' : 'Recuperar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
