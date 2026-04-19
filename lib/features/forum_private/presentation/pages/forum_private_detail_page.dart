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

  const ForumPrivateDetailPage({super.key, required this.id, this.title});

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
        data: {'tema_id': widget.id, 'contenido': content},
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
    final title = DataUtils.firstString(topic, [
      'titulo',
      'title',
      'nombre',
    ], fallback: widget.title ?? 'Tema');
    final content = DataUtils.firstString(topic, [
      'descripcion',
      'contenido',
      'mensaje',
    ], fallback: 'Sin contenido.');
    final author = DataUtils.firstString(topic, [
      'autor',
      'usuario',
      'nombre_usuario',
      'creado_por',
    ], fallback: 'Usuario');

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del tema')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  author,
                  style: const TextStyle(
                    color: AppTheme.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  content,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Responder',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _replyController,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Contenido'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isReplying ? null : _reply,
                  child: Text(_isReplying ? 'Enviando...' : 'Responder'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Respuestas',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          if (_replies.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Text(
                'Este tema todavía no tiene respuestas.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            )
          else
            ..._replies.map(
              (reply) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DataUtils.firstString(reply, [
                        'autor',
                        'usuario',
                        'nombre_usuario',
                        'creado_por',
                      ], fallback: 'Usuario'),
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      DataUtils.firstString(reply, [
                        'contenido',
                        'descripcion',
                        'mensaje',
                        'texto',
                      ], fallback: 'Sin contenido.'),
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        height: 1.5,
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
