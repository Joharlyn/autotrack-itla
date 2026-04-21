import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/storage/session_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/data_utils.dart';
import '../../data/services/news_service.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  final _service = NewsService();

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    final token = context.read<SessionProvider>().token;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _service.getNews(token: token);
      setState(() {
        _items = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _openDetail(Map<String, dynamic> item) {
    final id = DataUtils.firstInt(item, ['id']);
    final title = DataUtils.firstString(item, ['titulo', 'title'], fallback: 'Noticia');

    Navigator.pushNamed(
      context,
      AppRoutes.newsDetail,
      arguments: {
        'id': id,
        'title': title,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Noticias'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadNews,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
          children: [
            Container(
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
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Noticias automotrices',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _items.isEmpty
                          ? 'Consulta las últimas novedades del mundo automotriz dominicano.'
                          : 'Hay ${_items.length} noticia${_items.length == 1 ? '' : 's'} disponible${_items.length == 1 ? '' : 's'} ahora mismo.',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _TopStat(
                            title: 'Noticias',
                            value: '${_items.length}',
                            icon: Icons.newspaper_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: _TopStat(
                            title: 'Acceso',
                            value: 'Lista pública',
                            icon: Icons.public_rounded,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            const _SectionHeader(
              title: 'Últimas publicaciones',
              subtitle: 'Abre cualquier noticia para consultar su detalle y contenido completo.',
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.accent),
                ),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Center(
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              )
            else if (_items.isEmpty)
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.newspaper_rounded,
                      size: 50,
                      color: AppTheme.accent,
                    ),
                    SizedBox(height: 14),
                    Text(
                      'No hay noticias disponibles.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._items.map((item) {
                final title = DataUtils.firstString(
                  item,
                  ['titulo', 'title'],
                  fallback: 'Noticia',
                );
                final summary = DataUtils.firstString(
                  item,
                  ['resumen', 'descripcion', 'summary'],
                  fallback: 'Sin resumen disponible.',
                );
                final image = DataUtils.firstImage(item);
                final fecha = DataUtils.firstString(item, ['fecha', 'created_at']);
                final fuente = DataUtils.firstString(item, ['fuente', 'source']);

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => _openDetail(item),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (image.isNotEmpty)
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                            child: CachedNetworkImage(
                              imageUrl: image,
                              width: double.infinity,
                              height: 190,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                width: double.infinity,
                                height: 190,
                                color: AppTheme.softCard,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: AppTheme.accent,
                                  ),
                                ),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                width: double.infinity,
                                height: 190,
                                color: AppTheme.softCard,
                                child: const Icon(
                                  Icons.image_not_supported_rounded,
                                  color: AppTheme.textSecondary,
                                  size: 42,
                                ),
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  if (fecha.isNotEmpty)
                                    _DataPill(
                                      icon: Icons.calendar_month_rounded,
                                      text: DataUtils.formatDate(fecha),
                                    ),
                                  if (fuente.isNotEmpty)
                                    _DataPill(
                                      icon: Icons.language_rounded,
                                      text: fuente,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Text(
                                summary,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  height: 1.55,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: const [
                                  Text(
                                    'Leer noticia',
                                    style: TextStyle(
                                      color: AppTheme.accent,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    color: AppTheme.accent,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _TopStat extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _TopStat({
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.accent, size: 18),
          const SizedBox(height: 12),
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
            letterSpacing: -0.6,
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

class _DataPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DataPill({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppTheme.softCard,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppTheme.accent),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}