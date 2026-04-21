import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/storage/session_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/data_utils.dart';
import '../../../../shared/widgets/access_required_view.dart';
import '../../data/services/forum_private_service.dart';

class ForumPrivateDetailPage extends StatefulWidget {
  final int id;
  final String? title;

  const ForumPrivateDetailPage({
    super.key,
    required this.id,
    this.title,
  });

  @override
  State<ForumPrivateDetailPage> createState() => _ForumPrivateDetailPageState();
}

class _ForumPrivateDetailPageState extends State<ForumPrivateDetailPage> {
  final _service = ForumPrivateService();
  final _replyController = TextEditingController();

  bool _isLoading = true;
  bool _isReplying = false;
  String? _error;

  Map<String, dynamic>? _topic;
  List<Map<String, dynamic>> _replies = [];

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
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
      final result = await _service.getTopicDetail(token, widget.id);

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

  Future<void> _reply() async {
    final token = context.read<SessionProvider>().token;
    if (token == null || token.isEmpty) return;

    final content = _replyController.text.trim();
    if (content.isEmpty) {
      _showSnack('Escribe una respuesta.');
      return;
    }

    setState(() => _isReplying = true);

    try {
      await _service.replyTopic(
        token: token,
        data: {
          'tema_id': widget.id,
          'contenido': content,
        },
      );

      _replyController.clear();
      await _loadDetail();

      if (!mounted) return;
      _showSnack('Respuesta enviada.');
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isReplying = false);
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.watch<SessionProvider>().isLoggedIn;

    if (!isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle del tema')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            SizedBox(height: 60),
            AccessRequiredView(
              title: 'Detalle del tema',
              message: 'Debes iniciar sesión para participar en el foro.',
            ),
          ],
        ),
      );
    }

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del tema'),
      ),
      body: ListView(
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
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_rounded,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        author,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    content,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      height: 1.65,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
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
                  'Responder tema',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Aporta tu opinión o solución dentro de la conversación.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _replyController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Contenido',
                    prefixIcon: Icon(Icons.reply_rounded),
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: _isReplying ? null : _reply,
                  icon: const Icon(Icons.send_rounded),
                  label: Text(
                    _isReplying ? 'Enviando...' : 'Responder',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const _SectionHeader(
            title: 'Respuestas',
            subtitle: 'Consulta todas las participaciones dentro del tema.',
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
            ..._replies.map(
              (reply) => Container(
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
                            DataUtils.firstString(
                              reply,
                              ['autor', 'usuario', 'nombre_usuario', 'creado_por'],
                              fallback: 'Usuario',
                            ),
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
                      DataUtils.firstString(
                        reply,
                        ['contenido', 'descripcion', 'mensaje', 'texto'],
                        fallback: 'Sin contenido.',
                      ),
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        height: 1.55,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
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