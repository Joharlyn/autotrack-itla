import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/storage/session_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/data_utils.dart';
import '../../../../shared/widgets/access_required_view.dart';
import '../../data/services/news_service.dart';

class NewsDetailPage extends StatefulWidget {
  final int id;
  final String? title;

  const NewsDetailPage({
    super.key,
    required this.id,
    this.title,
  });

  @override
  State<NewsDetailPage> createState() => _NewsDetailPageState();
}

class _NewsDetailPageState extends State<NewsDetailPage> {
  final _service = NewsService();

  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _item;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    final token = context.read<SessionProvider>().token;

    if (token == null || token.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _service.getNewsDetail(
        id: widget.id,
        token: token,
      );

      setState(() {
        _item = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();

    if (!session.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle noticia')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            SizedBox(height: 60),
            AccessRequiredView(
              title: 'Detalle de noticia',
              message:
                  'La lista de noticias es pública, pero el detalle completo requiere iniciar sesión según el comportamiento actual del backend.',
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle noticia')),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.accent),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle noticia')),
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

    final item = _item ?? {};
    final title = DataUtils.firstString(
      item,
      ['titulo', 'title'],
      fallback: widget.title ?? 'Noticia',
    );
    final summary = DataUtils.firstString(
      item,
      ['resumen', 'summary'],
      fallback: '',
    );
    final content = DataUtils.firstString(
      item,
      ['contenido', 'descripcion', 'detalle', 'cuerpo', 'texto'],
      fallback: '',
    );
    final source = DataUtils.firstString(
      item,
      ['fuente', 'source'],
      fallback: '',
    );
    final date = DataUtils.firstString(
      item,
      ['fecha', 'created_at'],
      fallback: '',
    );
    final image = DataUtils.firstImage(item);

    final finalBody = content.isNotEmpty
        ? content
        : (summary.isNotEmpty ? summary : 'Sin contenido disponible.');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle noticia'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadDetail,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (image.isNotEmpty)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: image,
                        width: double.infinity,
                        height: 230,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          height: 230,
                          color: AppTheme.softCard,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.accent,
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          height: 230,
                          color: AppTheme.softCard,
                          child: const Icon(
                            Icons.image_not_supported_rounded,
                            color: AppTheme.textSecondary,
                            size: 44,
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            if (date.isNotEmpty)
                              _DataPill(
                                icon: Icons.calendar_month_rounded,
                                text: DataUtils.formatDate(date),
                              ),
                            if (source.isNotEmpty)
                              _DataPill(
                                icon: Icons.language_rounded,
                                text: source,
                              ),
                          ],
                        ),
                        if (summary.isNotEmpty) const SizedBox(height: 16),
                        if (summary.isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.softCard,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Text(
                              summary,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                height: 1.55,
                                fontSize: 14,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contenido',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    finalBody,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 15,
                      height: 1.7,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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