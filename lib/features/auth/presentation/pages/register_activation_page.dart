import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/storage/session_provider.dart';
import '../../../../shared/widgets/auth_header_card.dart';
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
      appBar: AppBar(
        title: const Text('Registro y activación'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
        children: [
          const AuthHeaderCard(
            icon: Icons.verified_user_rounded,
            title: 'Activa tu cuenta',
            subtitle:
                'Completa el registro con tu matrícula y luego activa tu acceso con el token temporal.',
          ),
          const SizedBox(height: 22),
          AuthSectionCard(
            title: '1) Registro',
            subtitle:
                'Envía tu matrícula para recibir el token temporal necesario para activar la cuenta.',
            children: [
              TextField(
                controller: _registerMatriculaController,
                decoration: const InputDecoration(
                  labelText: 'Matrícula',
                  hintText: '2023-0181',
                  prefixIcon: Icon(Icons.badge_rounded),
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _isRegistering ? null : _register,
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: Text(
                  _isRegistering ? 'Procesando...' : 'Registrar',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          AuthSectionCard(
            title: '2) Activación',
            subtitle:
                'Usa el token temporal y define tu contraseña definitiva para completar el acceso.',
            children: [
              TextField(
                controller: _activateTokenController,
                decoration: const InputDecoration(
                  labelText: 'Token temporal',
                  prefixIcon: Icon(Icons.key_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _activatePasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  hintText: 'Mínimo 6 caracteres',
                  prefixIcon: Icon(Icons.lock_rounded),
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _isActivating ? null : _activate,
                icon: const Icon(Icons.verified_rounded),
                label: Text(
                  _isActivating ? 'Activando...' : 'Activar cuenta',
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, AppRoutes.login);
                },
                child: const Text('Ya tengo acceso, ir a iniciar sesión'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}