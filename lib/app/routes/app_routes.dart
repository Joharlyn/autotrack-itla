import 'package:flutter/material.dart';

import '../../features/about/presentation/pages/about_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_activation_page.dart';
import '../../features/catalog/presentation/pages/catalog_detail_page.dart';
import '../../features/catalog/presentation/pages/catalog_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/finance/presentation/pages/expense_income_page.dart';
import '../../features/forum/presentation/pages/public_forum_detail_page.dart';
import '../../features/forum/presentation/pages/public_forum_page.dart';
import '../../features/forum_private/presentation/pages/forum_private_detail_page.dart';
import '../../features/forum_private/presentation/pages/forum_private_page.dart';
import '../../features/news/presentation/pages/news_detail_page.dart';
import '../../features/news/presentation/pages/news_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/videos/presentation/pages/videos_page.dart';
import '../../features/vehicle_records/presentation/pages/fuel_oil_page.dart';
import '../../features/vehicle_records/presentation/pages/maintenance_page.dart';
import '../../features/vehicle_records/presentation/pages/tires_page.dart';
import '../../features/vehicles/presentation/pages/vehicle_detail_page.dart';
import '../../features/vehicles/presentation/pages/vehicle_form_page.dart';
import '../../features/vehicles/presentation/pages/vehicles_page.dart';

class AppRoutes {
  static const String splash = '/';
  static const String dashboard = '/dashboard';
  static const String login = '/login';
  static const String registerActivation = '/register-activation';
  static const String profile = '/profile';
  static const String about = '/about';

  static const String news = '/news';
  static const String newsDetail = '/news-detail';
  static const String videos = '/videos';
  static const String catalog = '/catalog';
  static const String catalogDetail = '/catalog-detail';
  static const String publicForum = '/public-forum';
  static const String publicForumDetail = '/public-forum-detail';

  static const String vehicles = '/vehicles';
  static const String vehicleDetail = '/vehicle-detail';
  static const String vehicleForm = '/vehicle-form';

  static const String maintenance = '/maintenance';
  static const String fuelOil = '/fuel-oil';
  static const String tires = '/tires';

  static const String expenseIncome = '/expense-income';
  static const String forumPrivate = '/forum-private';
  static const String forumPrivateDetail = '/forum-private-detail';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashPage());
      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardPage());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case registerActivation:
        return MaterialPageRoute(
          builder: (_) => const RegisterActivationPage(),
        );
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfilePage());
      case about:
        return MaterialPageRoute(builder: (_) => const AboutPage());
      case news:
        return MaterialPageRoute(builder: (_) => const NewsPage());
      case videos:
        return MaterialPageRoute(builder: (_) => const VideosPage());
      case catalog:
        return MaterialPageRoute(builder: (_) => const CatalogPage());
      case publicForum:
        return MaterialPageRoute(builder: (_) => const PublicForumPage());
      case vehicles:
        return MaterialPageRoute(builder: (_) => const VehiclesPage());
      case newsDetail:
        final args = (settings.arguments as Map?) ?? {};
        return MaterialPageRoute(
          builder: (_) => NewsDetailPage(
            id: args['id'] as int? ?? 0,
            title: args['title']?.toString(),
          ),
        );
      case catalogDetail:
        final args = (settings.arguments as Map?) ?? {};
        return MaterialPageRoute(
          builder: (_) => CatalogDetailPage(
            id: args['id'] as int? ?? 0,
            title: args['title']?.toString(),
          ),
        );
      case publicForumDetail:
        final args = (settings.arguments as Map?) ?? {};
        return MaterialPageRoute(
          builder: (_) => PublicForumDetailPage(
            id: args['id'] as int? ?? 0,
            title: args['title']?.toString(),
          ),
        );
      case vehicleDetail:
        final args = (settings.arguments as Map?) ?? {};
        return MaterialPageRoute(
          builder: (_) => VehicleDetailPage(id: args['id'] as int? ?? 0),
        );
      case vehicleForm:
        final args = (settings.arguments as Map?) ?? {};
        return MaterialPageRoute(
          builder: (_) => VehicleFormPage(
            initialData: args['vehicle'] as Map<String, dynamic>?,
          ),
        );
      case maintenance:
        final args = (settings.arguments as Map?) ?? {};
        return MaterialPageRoute(
          builder: (_) => MaintenancePage(
            vehicleId: args['vehicleId'] as int? ?? 0,
            vehicleName: args['vehicleName']?.toString() ?? 'Vehículo',
          ),
        );
      case fuelOil:
        final args = (settings.arguments as Map?) ?? {};
        return MaterialPageRoute(
          builder: (_) => FuelOilPage(
            vehicleId: args['vehicleId'] as int? ?? 0,
            vehicleName: args['vehicleName']?.toString() ?? 'Vehículo',
          ),
        );
      case tires:
        final args = (settings.arguments as Map?) ?? {};
        return MaterialPageRoute(
          builder: (_) => TiresPage(
            vehicleId: args['vehicleId'] as int? ?? 0,
            vehicleName: args['vehicleName']?.toString() ?? 'Vehículo',
          ),
        );
      case expenseIncome:
        final args = (settings.arguments as Map?) ?? {};
        return MaterialPageRoute(
          builder: (_) => ExpenseIncomePage(
            vehicleId: args['vehicleId'] as int? ?? 0,
            vehicleName: args['vehicleName']?.toString() ?? 'Vehículo',
          ),
        );
      case forumPrivate:
        final args = (settings.arguments as Map?) ?? {};
        return MaterialPageRoute(
          builder: (_) => ForumPrivatePage(
            vehicleId: args['vehicleId'] as int? ?? 0,
            vehicleName: args['vehicleName']?.toString() ?? 'Vehículo',
          ),
        );
      case forumPrivateDetail:
        final args = (settings.arguments as Map?) ?? {};
        return MaterialPageRoute(
          builder: (_) => ForumPrivateDetailPage(
            id: args['id'] as int? ?? 0,
            title: args['title']?.toString(),
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Ruta no encontrada'))),
        );
    }
  }
}
