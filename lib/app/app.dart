import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/storage/session_provider.dart';
import '../core/theme/app_theme.dart';
import 'routes/app_routes.dart';

class VehiculosItlaApp extends StatelessWidget {
  const VehiculosItlaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SessionProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Vehículos ITLA',
        theme: AppTheme.darkTheme,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}
