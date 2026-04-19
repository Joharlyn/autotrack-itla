import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/storage/session_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/services/auth_service.dart';

class RegisterActivationPage extends StatefulWidget {
  const RegisterActivationPage({super.key});

  @override
  State<RegisterActivationPage> createState() => _RegisterActivationPageState();
}

class _RegisterActivationPageState extends State<RegisterActivationPage> {
  final _registerMatriculaController = TextEditingController();
  final _activateTokenController = TextEditingController();
  final _activatePasswordController = TextEditingController();

  final _authService = AuthService();

  bool _isRegistering = false;
  bool _isActivating = false;

  @override
  void dispose() {
    _registerMatriculaController.dispose();
    _activateTokenController.dispose();
    _activatePasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final matricula = _registerMatriculaController.text.trim();

    if (matricula.isEmpty) {
      _showSnack('Escribe tu matrícula.');
      return;
    }

    setState(() => _isRegistering = true);

    try {
      final data = await _authService.register(matricula);
      final tempToken = data['token']?.toString() ?? '';

      if (tempToken.isNotEmpty) {
        _activateTokenController.text = tempToken;
      }

      _showSnack('Registro exitoso. Ya puedes activar la cuenta.');
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isRegistering = false);
      }
    }
  }

  Future<void> _activate() async {
    final token = _activateTokenController.text.trim();
    final password = _activatePasswordController.text.trim();

    if (token.isEmpty || password.isEmpty) {
      _showSnack('Completa el token y la contraseña.');
      return;
    }

    if (password.length < 6) {
      _showSnack('La contraseña debe tener mínimo 6 caracteres.');
      return;
    }

    setState(() => _isActivating = true);

    try {
      final data = await _authService.activate(
        token: token,
        contrasena: password,
      );

      if (!mounted) return;

      await context.read<SessionProvider>().saveAuthData(data);

      _showSnack('Cuenta activada correctamente.');

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
        setState(() => _isActivating = false);
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
      appBar: AppBar(title: const Text('Registro y activación')),
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
                    '1) Registro',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Envía tu matrícula para recibir el token temporal.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _registerMatriculaController,
                    decoration: const InputDecoration(
                      labelText: 'Matrícula',
                      hintText: '2023-0181',
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: _isRegistering ? null : _register,
                    child: Text(_isRegistering ? 'Procesando...' : 'Registrar'),
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
                    '2) Activación',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Usa el token temporal y define tu contraseña definitiva.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _activateTokenController,
                    decoration: const InputDecoration(
                      labelText: 'Token temporal',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _activatePasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      hintText: 'Mínimo 6 caracteres',
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: _isActivating ? null : _activate,
                    child: Text(
                      _isActivating ? 'Activando...' : 'Activar cuenta',
                    ),
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
