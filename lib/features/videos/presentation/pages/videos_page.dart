import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/storage/session_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/api_error_helper.dart';
import '../../../../shared/utils/data_utils.dart';
import '../../../../shared/widgets/access_required_view.dart';
import '../../data/services/videos_service.dart';

class VideosPage extends StatefulWidget {
  const VideosPage({super.key});

  @override
  State<VideosPage> createState() => _VideosPageState();
}

class _VideosPageState extends State<VideosPage> {
  final _service = VideosService();

  bool _isLoading = true;
  bool _needsLogin = false;
  String? _error;
  List<Map<String, dynamic>> _videos = [];

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    setState(() {
      _isLoading = true;
      _needsLogin = false;
      _error = null;
    });

    try {
      final session = context.read<SessionProvider>();
      final result = await _service.getVideos(token: session.token);

      setState(() {
        _videos = result;
        _isLoading = false;
      });
    } catch (e) {
      final session = context.read<SessionProvider>();

      if (ApiErrorHelper.isAuthError(e)) {
        setState(() {
          _needsLogin = true;
          _error = ApiErrorHelper.moduleAccessMessage(
            moduleName: 'los videos educativos',
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

  String _buildVideoUrl(Map<String, dynamic> item) {
    final directUrl = DataUtils.firstString(item, ['url', 'videoUrl', 'link']);
    if (directUrl.isNotEmpty) return directUrl;

    final youtubeId = DataUtils.firstString(item, [
      'youtubeId',
      'youtube_id',
      'idYoutube',
    ]);
    if (youtubeId.isNotEmpty) {
      return 'https://www.youtube.com/watch?v=$youtubeId';
    }

    return '';
  }

  Future<void> _openVideo(Map<String, dynamic> item) async {
    final url = _buildVideoUrl(item);

    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este video no tiene enlace disponible.')),
      );
      return;
    }

    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Videos educativos')),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.accent),
        ),
      );
    }

    if (_needsLogin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Videos educativos')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 60),
            AccessRequiredView(
              title: 'Videos educativos',
              message:
                  _error ?? 'Debes iniciar sesión para ver este contenido.',
              onRetry: () => _loadVideos(),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Videos educativos')),
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
      appBar: AppBar(title: const Text('Videos educativos')),
      body: RefreshIndicator(
        onRefresh: _loadVideos,
        child: _videos.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Text(
                      'No hay videos disponibles.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _videos.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final item = _videos[index];
                  final title = DataUtils.firstString(item, [
                    'titulo',
                    'title',
                    'nombre',
                  ], fallback: 'Video');
                  final description = DataUtils.firstString(item, [
                    'descripcion',
                    'description',
                    'resumen',
                  ], fallback: 'Sin descripción.');
                  final category = DataUtils.firstString(item, [
                    'categoria',
                    'category',
                  ]);
                  final image = DataUtils.firstString(item, [
                    'thumbnail',
                    'thumb',
                    'imagen',
                    'image',
                    'foto',
                  ]);

                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => _openVideo(item),
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
                            Stack(
                              alignment: Alignment.center,
                              children: [
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
                                        Icons.ondemand_video_rounded,
                                        color: AppTheme.textSecondary,
                                        size: 46,
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 58,
                                  height: 58,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.55),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow_rounded,
                                    size: 34,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (category.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accent.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      category,
                                      style: const TextStyle(
                                        color: AppTheme.accent,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                if (category.isNotEmpty)
                                  const SizedBox(height: 10),
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
                                ElevatedButton.icon(
                                  onPressed: () => _openVideo(item),
                                  icon: const Icon(Icons.open_in_new_rounded),
                                  label: const Text('Ver video'),
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
