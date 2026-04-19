import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/data_utils.dart';
import '../../data/services/public_forum_service.dart';

class PublicForumPage extends StatefulWidget {
  const PublicForumPage({super.key});

  @override
  State<PublicForumPage> createState() => _PublicForumPageState();
}

class _PublicForumPageState extends State<PublicForumPage> {
  final _service = PublicForumService();

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _topics = [];

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  Future<void> _loadTopics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _service.getTopics();
      setState(() {
        _topics = result;
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
    return Scaffold(
      appBar: AppBar(title: const Text('Foro comunitario')),
      body: RefreshIndicator(
        onRefresh: _loadTopics,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.accent),
              )
            : _error != null
            ? ListView(
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
              )
            : _topics.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Text(
                      'No hay temas disponibles.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _topics.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final item = _topics[index];
                  final id = DataUtils.firstInt(item, ['id', 'tema_id']);
                  final title = DataUtils.firstString(item, [
                    'titulo',
                    'title',
                    'nombre',
                  ], fallback: 'Tema');
                  final description = DataUtils.firstString(item, [
                    'descripcion',
                    'contenido',
                    'mensaje',
                  ], fallback: 'Sin descripción.');
                  final author = DataUtils.firstString(item, [
                    'autor',
                    'usuario',
                    'nombre_usuario',
                    'creado_por',
                  ], fallback: 'Autor no disponible');
                  final vehicle = DataUtils.firstString(item, [
                    'vehiculo',
                    'vehiculo_asociado',
                    'vehiculo_nombre',
                  ]);
                  final image = DataUtils.firstImage(item);
                  final replies = DataUtils.firstInt(item, [
                    'cantidad_respuestas',
                    'respuestas_count',
                    'total_respuestas',
                  ]);

                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: id == 0
                        ? null
                        : () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.publicForumDetail,
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
                                height: 180,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  height: 180,
                                  color: AppTheme.softCard,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: AppTheme.accent,
                                    ),
                                  ),
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  height: 180,
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
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  description,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _ChipText(
                                      text: author,
                                      icon: Icons.person_rounded,
                                    ),
                                    if (vehicle.isNotEmpty)
                                      _ChipText(
                                        text: vehicle,
                                        icon: Icons.directions_car_rounded,
                                      ),
                                    _ChipText(
                                      text: '$replies respuestas',
                                      icon: Icons.comment_rounded,
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
                },
              ),
      ),
    );
  }
}

class _ChipText extends StatelessWidget {
  final String text;
  final IconData icon;

  const _ChipText({required this.text, required this.icon});

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
