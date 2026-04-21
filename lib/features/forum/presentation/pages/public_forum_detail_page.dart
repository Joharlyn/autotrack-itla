import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/data_utils.dart';
import '../../data/services/public_forum_service.dart';

class PublicForumDetailPage extends StatefulWidget {
  final int id;
  final String? title;

  const PublicForumDetailPage({
    super.key,
    required this.id,
    this.title,
  });

  @override
  State<PublicForumDetailPage> createState() => _PublicForumDetailPageState();
}

class _PublicForumDetailPageState extends State<PublicForumDetailPage> {
  final _service = PublicForumService();

  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _topic;
  List<Map<String, dynamic>> _replies = [];

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _service.getTopicDetail(widget.id);

      List<Map<String, dynamic>> replies = [];
      final candidates = [
        result['respuestas'],
        result['comentarios'],
        result['replys'],
        result['items'],
      ];

      for (final candidate in candidates) {
        final extracted = DataUtils.extractList(candidate, const []);
        if (extracted.isNotEmpty) {
          replies = extracted;
          break;
        }
      }

      setState(() {
        _topic = result;
        _replies = replies;
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
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle del tema')),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.accent),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle del tema')),
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

    final topic = _topic ?? {};
    final title = DataUtils.firstString(
      topic,
      ['titulo', 'title', 'nombre'],
      fallback: widget.title ?? 'Tema',
    );
    final content = DataUtils.firstString(
      topic,
      ['descripcion', 'contenido', 'mensaje'],
      fallback: 'Sin contenido.',
    );
    final author = DataUtils.firstString(
      topic,
      ['autor', 'usuario', 'nombre_usuario', 'creado_por'],
      fallback: 'Usuario',
    );
    final date = DataUtils.firstString(
      topic,
      ['fecha', 'created_at'],
      fallback: '',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del tema'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadDetail,
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
                        _DataPill(
                          icon: Icons.person_rounded,
                          text: author,
                        ),
                        if (date.isNotEmpty)
                          _DataPill(
                            icon: Icons.calendar_month_rounded,
                            text: DataUtils.formatDate(date),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      content,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 15,
                        height: 1.65,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            const _SectionHeader(
              title: 'Respuestas',
              subtitle: 'Consulta las participaciones realizadas dentro del tema.',
            ),
            const SizedBox(height: 16),
            if (_replies.isEmpty)
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
                      Icons.chat_bubble_outline_rounded,
                      size: 50,
                      color: AppTheme.accent,
                    ),
                    SizedBox(height: 14),
                    Text(
                      'Este tema todavía no tiene respuestas.',
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
              ..._replies.map((reply) {
                final replyAuthor = DataUtils.firstString(
                  reply,
                  ['autor', 'usuario', 'nombre_usuario', 'creado_por'],
                  fallback: 'Usuario',
                );
                final replyContent = DataUtils.firstString(
                  reply,
                  ['contenido', 'descripcion', 'mensaje', 'texto'],
                  fallback: 'Sin contenido.',
                );

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              color: AppTheme.accent,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              replyAuthor,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        replyContent,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          height: 1.55,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
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