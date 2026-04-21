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

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();

    final items = <_DashboardItem>[
      _DashboardItem(
        icon: Icons.newspaper_rounded,
        title: 'Noticias',
        subtitle: 'Entérate de las últimas novedades del mundo automotriz.',
        tag: 'Público',
        onTap: () => Navigator.pushNamed(context, AppRoutes.news),
      ),
      _DashboardItem(
        icon: Icons.ondemand_video_rounded,
        title: 'Videos',
        subtitle: 'Aprende sobre mantenimiento, frenos y cuidado del motor.',
        tag: 'Público',
        onTap: () => Navigator.pushNamed(context, AppRoutes.videos),
      ),
      _DashboardItem(
        icon: Icons.car_rental_rounded,
        title: 'Catálogo',
        subtitle: 'Explora vehículos y consulta su información general.',
        tag: 'Público',
        onTap: () => Navigator.pushNamed(context, AppRoutes.catalog),
      ),
      _DashboardItem(
        icon: Icons.forum_rounded,
        title: 'Foro público',
        subtitle: 'Lee temas abiertos por la comunidad automotriz.',
        tag: 'Público',
        onTap: () => Navigator.pushNamed(context, AppRoutes.publicForum),
      ),
      if (!session.isLoggedIn)
        _DashboardItem(
          icon: Icons.person_add_alt_1_rounded,
          title: 'Registro',
          subtitle: 'Activa tu cuenta con matrícula y contraseña.',
          tag: 'Cuenta',
          onTap: () => Navigator.pushNamed(context, AppRoutes.registerActivation),
        ),
      if (!session.isLoggedIn)
        _DashboardItem(
          icon: Icons.login_rounded,
          title: 'Iniciar sesión',
          subtitle: 'Accede a todos los módulos privados de la app.',
          tag: 'Cuenta',
          onTap: () => Navigator.pushNamed(context, AppRoutes.login),
        ),
      if (session.isLoggedIn)
        _DashboardItem(
          icon: Icons.person_rounded,
          title: 'Mi perfil',
          subtitle: 'Consulta tus datos y actualiza tu foto.',
          tag: 'Privado',
          onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
        ),
      if (session.isLoggedIn)
        _DashboardItem(
          icon: Icons.directions_car_filled_rounded,
          title: 'Mis vehículos',
          subtitle: 'Crea, edita y administra tus vehículos registrados.',
          tag: 'Privado',
          onTap: () => Navigator.pushNamed(context, AppRoutes.vehicles),
        ),
      if (session.isLoggedIn)
        _DashboardItem(
          icon: Icons.logout_rounded,
          title: 'Cerrar sesión',
          subtitle: 'Finaliza tu sesión actual de forma segura.',
          tag: 'Sistema',
          onTap: () async {
            await context.read<SessionProvider>().clearSession();
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sesión cerrada.')),
            );
          },
        ),
      _DashboardItem(
        icon: Icons.badge_rounded,
        title: 'Acerca de',
        subtitle: 'Información del desarrollador y datos de contacto.',
        tag: 'Info',
        onTap: () => Navigator.pushNamed(context, AppRoutes.about),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('AutoTrack ITLA'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
          children: [
            _TopBanner(session: session),
            const SizedBox(height: 22),
            const _SectionHeader(
              title: 'Panel principal',
              subtitle: 'Accede rápidamente a cada módulo de la aplicación.',
            ),
            const SizedBox(height: 14),
            GridView.builder(
              itemCount: items.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.82,
              ),
              itemBuilder: (context, index) {
                final item = items[index];
                return AppMenuCard(
                  icon: item.icon,
                  title: item.title,
                  subtitle: item.subtitle,
                  tag: item.tag,
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

class _TopBanner extends StatelessWidget {
  final SessionProvider session;

  const _TopBanner({
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.border),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF131A24),
            Color(0xFF0B1017),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CarouselSlider(
            options: CarouselOptions(
              height: 230,
              autoPlay: true,
              viewportFraction: 1,
              enlargeCenterPage: false,
            ),
            items: DashboardPage.sliderImages.map((image) {
              return ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      image,
                      fit: BoxFit.cover,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.72),
                            Colors.black.withOpacity(0.18),
                          ],
                          begin: Alignment.bottomLeft,
                          end: Alignment.topRight,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.15),
                              ),
                            ),
                            child: Text(
                              session.isLoggedIn ? 'Sesión activa' : 'Modo visitante',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            session.isLoggedIn
                                ? 'Bienvenido${session.fullName.isEmpty ? '' : ', ${session.fullName}'}'
                                : 'Control total para tu vehículo',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              height: 1.05,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            session.isLoggedIn
                                ? 'Gestiona mantenimiento, combustible, finanzas y participación en el foro desde un solo lugar.'
                                : 'Explora noticias, videos, catálogo, foro y activa tu cuenta para desbloquear todos los módulos.',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: _MiniStatCard(
                    title: 'Estado',
                    value: session.isLoggedIn ? 'Con acceso' : 'Invitado',
                    icon: session.isLoggedIn
                        ? Icons.verified_user_rounded
                        : Icons.lock_open_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniStatCard(
                    title: 'Módulos',
                    value: session.isLoggedIn ? 'Completos' : 'Públicos',
                    icon: Icons.grid_view_rounded,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MiniStatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.softCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppTheme.accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            icon,
            color: AppTheme.textSecondary,
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.7,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _DashboardItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? tag;
  final VoidCallback onTap;

  _DashboardItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.tag,
  });
}