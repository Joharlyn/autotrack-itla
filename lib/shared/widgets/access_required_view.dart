import 'package:flutter/material.dart';

import '../../app/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';

class AccessRequiredView extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const AccessRequiredView({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppTheme.accent.withOpacity(0.14),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: AppTheme.accent,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.login);
                },
                icon: const Icon(Icons.login_rounded),
                label: const Text('Iniciar sesión'),
              ),
              if (onRetry != null)
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reintentar'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
