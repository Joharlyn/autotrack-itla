import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/storage/session_provider.dart';
import '../../../../core/theme/app_theme.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final session = context.read<SessionProvider>();
    await session.init();

    await Future.delayed(const Duration(milliseconds: 1400));

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF090909), Color(0xFF121212), Color(0xFF1A1208)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.directions_car_rounded,
                size: 72,
                color: AppTheme.accent,
              ),
              SizedBox(height: 18),
              Text(
                AppConstants.appName,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Gestión vehicular para ITLA',
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              ),
              SizedBox(height: 24),
              CircularProgressIndicator(color: AppTheme.accent),
            ],
          ),
        ),
      ),
    );
  }
}
