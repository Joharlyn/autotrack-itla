import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/storage/session_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_menu_card.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  static const List<String> sliderImages = [
    'https://images.unsplash.com/photo-1492144534655-ae79c964c9d7?q=80&w=1200&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1503376780353-7e6692767b70?q=80&w=1200&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1489824904134-891ab64532f1?q=80&w=1200&auto=format&fit=crop',
  ];

  void _comingSoon(BuildContext context, String module) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$module lo conectaremos en la siguiente fase.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();

    final items = <_DashboardItem>[
      _DashboardItem(
        icon: Icons.newspaper_rounded,
        title: 'Noticias',
        subtitle: 'Últimas noticias automotrices',
        onTap: () => Navigator.pushNamed(context, AppRoutes.news),
      ),
      _DashboardItem(
        icon: Icons.ondemand_video_rounded,
        title: 'Videos',
        subtitle: 'Contenido educativo vehicular',
        onTap: () => Navigator.pushNamed(context, AppRoutes.videos),
      ),
      _DashboardItem(
        icon: Icons.car_rental_rounded,
        title: 'Catálogo',
        subtitle: 'Explora vehículos disponibles',
        onTap: () => Navigator.pushNamed(context, AppRoutes.catalog),
      ),
      _DashboardItem(
        icon: Icons.forum_rounded,
        title: 'Foro',
        subtitle: 'Temas de la comunidad',
        onTap: () => Navigator.pushNamed(context, AppRoutes.publicForum),
      ),
      if (!session.isLoggedIn)
        _DashboardItem(
          icon: Icons.person_add_alt_1_rounded,
          title: 'Registro',
          subtitle: 'Registrar y activar cuenta',
          onTap: () =>
              Navigator.pushNamed(context, AppRoutes.registerActivation),
        ),
      if (!session.isLoggedIn)
        _DashboardItem(
          icon: Icons.login_rounded,
          title: 'Iniciar sesión',
          subtitle: 'Accede a tus módulos privados',
          onTap: () => Navigator.pushNamed(context, AppRoutes.login),
        ),
      if (session.isLoggedIn)
        _DashboardItem(
          icon: Icons.person_rounded,
          title: 'Mi perfil',
          subtitle: 'Consulta tus datos reales',
          onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
        ),
      if (session.isLoggedIn)
        _DashboardItem(
          icon: Icons.directions_car_filled_rounded,
          title: 'Mis vehículos',
          subtitle: 'Registrar, editar y consultar tus vehículos',
          onTap: () => Navigator.pushNamed(context, AppRoutes.vehicles),
        ),
      if (session.isLoggedIn)
        _DashboardItem(
          icon: Icons.logout_rounded,
          title: 'Cerrar sesión',
          subtitle: 'Eliminar sesión local',
          onTap: () async {
            await context.read<SessionProvider>().clearSession();
            if (!context.mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Sesión cerrada.')));
          },
        ),
      _DashboardItem(
        icon: Icons.badge_rounded,
        title: 'Acerca de',
        subtitle: 'Información del desarrollador',
        onTap: () => Navigator.pushNamed(context, AppRoutes.about),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Vehículos ITLA')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              session.isLoggedIn
                  ? 'Bienvenido ${session.fullName.isEmpty ? '' : session.fullName}'
                  : 'Dashboard',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              session.isLoggedIn
                  ? 'Tu sesión está activa. Ya puedes entrar al perfil y a los módulos privados.'
                  : 'Administra tus vehículos, consulta noticias, videos, foro y más.',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 18),
            CarouselSlider(
              options: CarouselOptions(
                height: 190,
                autoPlay: true,
                viewportFraction: 1,
                enlargeCenterPage: false,
              ),
              items: sliderImages.map((image) {
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    image: DecorationImage(
                      image: NetworkImage(image),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.65),
                          Colors.black.withOpacity(0.15),
                        ],
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                      ),
                    ),
                    padding: const EdgeInsets.all(18),
                    alignment: Alignment.bottomLeft,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cuida tu vehículo',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Lleva control de gastos, mantenimientos y combustible.',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 22),
            GridView.builder(
              itemCount: items.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.95,
              ),
              itemBuilder: (context, index) {
                final item = items[index];
                return AppMenuCard(
                  icon: item.icon,
                  title: item.title,
                  subtitle: item.subtitle,
                  onTap: item.onTap,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  _DashboardItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}
