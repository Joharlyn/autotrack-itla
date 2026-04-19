import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/data_utils.dart';
import '../../data/services/public_forum_service.dart';

class PublicForumDetailPage extends StatefulWidget {
  final int id;
  final String? title;

  const PublicForumDetailPage({super.key, required this.id, this.title});

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
    _loadTopic();
  }

  Future<void> _loadTopic() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _service.getTopicDetail(widget.id);

      List<Map<String, dynamic>> replies = [];

      final possibleReplies = [
        result['respuestas'],
        result['comentarios'],
        result['replys'],
        result['items'],
      ];

      for (final value in possibleReplies) {
        final extracted = DataUtils.extractList(value, const []);
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
    ], fallback: 'Sin contenido disponible.');
    final author = DataUtils.firstString(topic, [
      'autor',
      'usuario',
      'nombre_usuario',
      'creado_por',
    ], fallback: 'Autor no disponible');
    final vehicle = DataUtils.firstString(topic, [
      'vehiculo',
      'vehiculo_asociado',
      'vehiculo_nombre',
    ]);
    final image = DataUtils.firstImage(topic);

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del tema')),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accent),
            )
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
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
                            height: 220,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              height: 220,
                              color: AppTheme.softCard,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: AppTheme.accent,
                                ),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              height: 220,
                              color: AppTheme.softCard,
                              child: const Icon(
                                Icons.forum_rounded,
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
                            Text(
                              title,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _MetaChip(
                                  icon: Icons.person_rounded,
                                  text: author,
                                ),
                                if (vehicle.isNotEmpty)
                                  _MetaChip(
                                    icon: Icons.directions_car_rounded,
                                    text: vehicle,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
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
                    ],
                  ),
                ),
                const SizedBox(height: 18),
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

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.softCard,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppTheme.accent),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
