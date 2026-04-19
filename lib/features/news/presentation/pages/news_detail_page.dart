import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';

import '../../../../core/storage/session_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/api_error_helper.dart';
import '../../../../shared/utils/data_utils.dart';
import '../../../../shared/widgets/access_required_view.dart';
import '../../data/services/news_service.dart';

class NewsDetailPage extends StatefulWidget {
  final int id;
  final String? title;

  const NewsDetailPage({super.key, required this.id, this.title});

  @override
  State<NewsDetailPage> createState() => _NewsDetailPageState();
}

class _NewsDetailPageState extends State<NewsDetailPage> {
  final _service = NewsService();

  bool _isLoading = true;
  bool _needsLogin = false;
  String? _error;
  Map<String, dynamic>? _news;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _needsLogin = false;
      _error = null;
    });

    try {
      final token = context.read<SessionProvider>().token;
      final result = await _service.getNewsDetail(id: widget.id, token: token);

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
            moduleName: 'el detalle de la noticia',
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
        appBar: AppBar(title: const Text('Detalle')),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.accent),
        ),
      );
    }

    if (_needsLogin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 60),
            AccessRequiredView(
              title: 'Detalle de noticia',
              message:
                  _error ?? 'Debes iniciar sesión para ver este contenido.',
              onRetry: () => _loadDetail(),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        ),
      );
    }

    final item = _news ?? {};
    final title = DataUtils.firstString(item, [
      'titulo',
      'title',
      'nombre',
    ], fallback: widget.title ?? 'Detalle de noticia');
    final image = DataUtils.firstImage(item);
    final date = DataUtils.firstString(item, [
      'fecha',
      'created_at',
      'published_at',
    ]);
    final html = DataUtils.firstString(item, [
      'contenido_html',
      'html',
      'contenido',
      'detalle',
      'body',
    ], fallback: '<p>No hay contenido disponible.</p>');

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (image.isNotEmpty)
              CachedNetworkImage(
                imageUrl: image,
                width: double.infinity,
                height: 240,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: 240,
                  color: AppTheme.softCard,
                  child: const Center(
                    child: CircularProgressIndicator(color: AppTheme.accent),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  height: 240,
                  color: AppTheme.softCard,
                  child: const Icon(
                    Icons.image_not_supported_rounded,
                    color: AppTheme.textSecondary,
                    size: 42,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (date.isNotEmpty)
                      Text(
                        DataUtils.formatDate(date),
                        style: const TextStyle(
                          color: AppTheme.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    if (date.isNotEmpty) const SizedBox(height: 10),
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Html(
                      data: html,
                      style: {
                        'body': Style(
                          color: Colors.white70,
                          fontSize: FontSize(15),
                          lineHeight: LineHeight.number(1.6),
                          margin: Margins.zero,
                          padding: HtmlPaddings.zero,
                        ),
                        'p': Style(margin: Margins.only(bottom: 14)),
                        'h1': Style(color: Colors.white),
                        'h2': Style(color: Colors.white),
                        'h3': Style(color: Colors.white),
                        'li': Style(color: Colors.white70),
                        'strong': Style(color: Colors.white),
                        'a': Style(color: AppTheme.accent),
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
