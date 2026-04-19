import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<void> _openPhone() async {
    final uri = Uri.parse('tel:${AppConstants.developerPhone}');
    await launchUrl(uri);
  }

  Future<void> _openEmail() async {
    final uri = Uri.parse('mailto:${AppConstants.developerEmail}');
    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final hasTelegram = AppConstants.developerTelegram.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Acerca de')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 58,
                backgroundColor: AppTheme.softCard,
                backgroundImage: const AssetImage(AppConstants.developerImage),
              ),
              const SizedBox(height: 16),
              const Text(
                AppConstants.developerName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Desarrollador de la aplicación',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 22),
              _InfoTile(
                icon: Icons.badge_rounded,
                title: 'Matrícula ITLA',
                value: AppConstants.developerMatricula,
              ),
              _InfoTile(
                icon: Icons.email_rounded,
                title: 'Correo',
                value: AppConstants.developerEmail,
                onTap: _openEmail,
              ),
              _InfoTile(
                icon: Icons.phone_rounded,
                title: 'Teléfono',
                value: AppConstants.developerPhone,
                onTap: _openPhone,
              ),
              _InfoTile(
                icon: Icons.telegram_rounded,
                title: 'Telegram',
                value: hasTelegram
                    ? AppConstants.developerTelegram
                    : 'No disponible por el momento',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.softCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppTheme.accent.withValues(alpha: 0.15),
          child: Icon(icon, color: AppTheme.accent),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        trailing: onTap != null
            ? const Icon(
                Icons.open_in_new_rounded,
                color: AppTheme.textSecondary,
              )
            : null,
      ),
    );
  }
}
