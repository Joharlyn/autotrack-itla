import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/storage/session_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/data_utils.dart';
import '../../data/services/videos_service.dart';

class VideosPage extends StatefulWidget {
  const VideosPage({super.key});

  @override
  State<VideosPage> createState() => _VideosPageState();
}

class _VideosPageState extends State<VideosPage> {
  final _service = VideosService();

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    final token = context.read<SessionProvider>().token;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _service.getVideos(token: token);
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

  Future<void> _openVideo(Map<String, dynamic> item) async {
    final directUrl = DataUtils.firstString(item, ['url', 'link']);
    final youtubeId = DataUtils.firstString(item, ['youtubeId', 'youtube_id']);

    final url = directUrl.isNotEmpty
        ? directUrl
        : youtubeId.isNotEmpty
            ? 'https://www.youtube.com/watch?v=$youtubeId'
            : '';

    if (url.isEmpty) {
      _showSnack('Este video no tiene URL disponible.');
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      _showSnack('La URL del video no es válida.');
      return;
    }

    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && mounted) {
      _showSnack('No se pudo abrir el video.');
    }
  }

  void _showVideoSheet(Map<String, dynamic> item) {
    final title = DataUtils.firstString(
      item,
      ['titulo', 'title'],
      fallback: 'Video',
    );
    final description = DataUtils.firstString(
      item,
      ['descripcion', 'description'],
      fallback: 'Sin descripción.',
    );
    final category = DataUtils.firstString(
      item,
      ['categoria', 'category'],
      fallback: 'General',
    );
    final thumbnail = DataUtils.firstString(
      item,
      ['thumbnail', 'imagen', 'image'],
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (thumbnail.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CachedNetworkImage(
                    imageUrl: thumbnail,
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
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: _DataPill(
                  icon: Icons.category_rounded,
                  text: category,
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  description,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    height: 1.55,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _openVideo(item);
                },
                icon: const Icon(Icons.play_circle_fill_rounded),
                label: const Text('Ver video'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Videos'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadVideos,
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
                      'Videos educativos',
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
                          ? 'Aprende sobre mantenimiento, frenos, aceite y buenas prácticas para tu vehículo.'
                          : 'Hay ${_items.length} video${_items.length == 1 ? '' : 's'} disponible${_items.length == 1 ? '' : 's'} para explorar.',
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
                            title: 'Videos',
                            value: '${_items.length}',
                            icon: Icons.ondemand_video_rounded,
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
              title: 'Biblioteca de aprendizaje',
              subtitle: 'Abre cualquier video para consultar su información y reproducirlo.',
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
                      Icons.ondemand_video_rounded,
                      size: 50,
                      color: AppTheme.accent,
                    ),
                    SizedBox(height: 14),
                    Text(
                      'No hay videos disponibles.',
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
                  fallback: 'Video',
                );
                final description = DataUtils.firstString(
                  item,
                  ['descripcion', 'description'],
                  fallback: 'Sin descripción disponible.',
                );
                final category = DataUtils.firstString(
                  item,
                  ['categoria', 'category'],
                  fallback: 'General',
                );
                final thumbnail = DataUtils.firstString(
                  item,
                  ['thumbnail', 'imagen', 'image'],
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
                    onTap: () => _showVideoSheet(item),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (thumbnail.isNotEmpty)
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                            child: Stack(
                              children: [
                                CachedNetworkImage(
                                  imageUrl: thumbnail,
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
                                Positioned.fill(
                                  child: Container(
                                    color: Colors.black.withOpacity(0.16),
                                  ),
                                ),
                                const Positioned(
                                  right: 14,
                                  bottom: 14,
                                  child: CircleAvatar(
                                    radius: 22,
                                    backgroundColor: AppTheme.accent,
                                    child: Icon(
                                      Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                ),
                              ],
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
                              const SizedBox(height: 12),
                              _DataPill(
                                icon: Icons.category_rounded,
                                text: category,
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
                              Row(
                                children: const [
                                  Text(
                                    'Ver detalles',
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

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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