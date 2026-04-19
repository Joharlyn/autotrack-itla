import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/storage/session_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/api_error_helper.dart';
import '../../../../shared/utils/data_utils.dart';
import '../../../../shared/widgets/access_required_view.dart';
import '../../data/services/news_service.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  final _service = NewsService();

  bool _isLoading = true;
  bool _needsLogin = false;
  String? _error;
  List<Map<String, dynamic>> _news = [];

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    setState(() {
      _isLoading = true;
      _needsLogin = false;
      _error = null;
    });

    try {
      final token = context.read<SessionProvider>().token;
      final result = await _service.getNews(token: token);

      setState(() {
        _news = result;
        _isLoading = false;
      });
    } catch (e) {
      final session = context.read<SessionProvider>();

      if (ApiErrorHelper.isAuthError(e)) {
        setState(() {
          _needsLogin = true;
          _error = ApiErrorHelper.moduleAccessMessage(
            moduleName: 'las noticias',
            isLoggedIn: session.isLoggedIn,
          );
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Noticias')),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.accent),
        ),
      );
    }

    if (_needsLogin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Noticias')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 60),
            AccessRequiredView(
              title: 'Noticias automotrices',
              message:
                  _error ?? 'Debes iniciar sesión para ver este contenido.',
              onRetry: () => _loadNews(),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Noticias')),
        body: ListView(
          children: [
            const SizedBox(height: 120),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Noticias')),
      body: RefreshIndicator(
        onRefresh: _loadNews,
        child: _news.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Text(
                      'No hay noticias disponibles.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _news.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final item = _news[index];
                  final id = DataUtils.firstInt(item, ['id', 'noticia_id']);
                  final title = DataUtils.firstString(item, [
                    'titulo',
                    'title',
                    'nombre',
                  ], fallback: 'Noticia');
                  final summary = DataUtils.firstString(item, [
                    'resumen',
                    'descripcion',
                    'extracto',
                    'contenido',
                  ], fallback: 'Sin resumen disponible.');
                  final image = DataUtils.firstImage(item);
                  final rawDate = DataUtils.firstString(item, [
                    'fecha',
                    'created_at',
                    'published_at',
                  ]);

                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: id == 0
                        ? null
                        : () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.newsDetail,
                              arguments: {'id': id, 'title': title},
                            );
                          },
                    child: Ink(
                      decoration: BoxDecoration(
                        color: AppTheme.card,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (image.isNotEmpty)
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(18),
                              ),
                              child: CachedNetworkImage(
                                imageUrl: image,
                                width: double.infinity,
                                height: 190,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  height: 190,
                                  color: AppTheme.softCard,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: AppTheme.accent,
                                    ),
                                  ),
                                ),
                                errorWidget: (_, __, ___) => Container(
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
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (rawDate.isNotEmpty)
                                  Text(
                                    DataUtils.formatDate(rawDate),
                                    style: const TextStyle(
                                      color: AppTheme.accent,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                if (rawDate.isNotEmpty)
                                  const SizedBox(height: 8),
                                Text(
                                  title,
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  summary,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
