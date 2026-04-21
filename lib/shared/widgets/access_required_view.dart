import 'package:flutter/material.dart';

import '../../app/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';

class AccessRequiredView extends StatelessWidget {
  final String title;
  final String message;

  const AccessRequiredView({
    super.key,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.border),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF141B26),
            Color(0xFF0B1017),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [
                  AppTheme.accent,
                  AppTheme.accentSoft,
                ],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33FF7A00),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.lock_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.login);
            },
            icon: const Icon(Icons.login_rounded),
            label: const Text('Ir a iniciar sesión'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              Navigator.maybePop(context);
            },
            child: const Text('Volver'),
          ),
        ],
      ),
    );
  }
}