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
  List<Map<String, dynamic>> _items = [];

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
    final id = DataUtils.firstInt(item, ['id', 'tema_id']);
    final title = DataUtils.firstString(
      item,
      ['titulo', 'title', 'nombre'],
      fallback: 'Tema',
    );

    Navigator.pushNamed(
      context,
      AppRoutes.publicForumDetail,
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
        title: const Text('Foro público'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadTopics,
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
                      'Foro comunitario',
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
                          ? 'Consulta temas y conversaciones abiertas por la comunidad automotriz.'
                          : 'Hay ${_items.length} tema${_items.length == 1 ? '' : 's'} disponible${_items.length == 1 ? '' : 's'} para leer.',
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
                            title: 'Temas',
                            value: '${_items.length}',
                            icon: Icons.forum_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: _TopStat(
                            title: 'Acceso',
                            value: 'Solo lectura',
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
              title: 'Conversaciones abiertas',
              subtitle: 'Explora los temas públicos y consulta sus respuestas.',
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
                      Icons.forum_outlined,
                      size: 50,
                      color: AppTheme.accent,
                    ),
                    SizedBox(height: 14),
                    Text(
                      'No hay temas públicos disponibles.',
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
                  ['titulo', 'title', 'nombre'],
                  fallback: 'Tema',
                );
                final description = DataUtils.firstString(
                  item,
                  ['descripcion', 'contenido', 'mensaje'],
                  fallback: 'Sin descripción.',
                );
                final author = DataUtils.firstString(
                  item,
                  ['autor', 'usuario', 'nombre_usuario', 'creado_por'],
                  fallback: 'Usuario',
                );
                final fecha = DataUtils.firstString(
                  item,
                  ['fecha', 'created_at'],
                  fallback: '',
                );

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
                    child: Padding(
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
                          Text(
                            description,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              height: 1.55,
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
                              if (fecha.isNotEmpty)
                                _DataPill(
                                  icon: Icons.calendar_month_rounded,
                                  text: DataUtils.formatDate(fecha),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: const [
                              Text(
                                'Ver tema',
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