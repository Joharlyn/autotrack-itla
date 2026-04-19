import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/storage/session_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/api_error_helper.dart';
import '../../../../shared/utils/data_utils.dart';
import '../../../../shared/widgets/access_required_view.dart';
import '../../data/services/catalog_service.dart';

class CatalogDetailPage extends StatefulWidget {
  final int id;
  final String? title;

  const CatalogDetailPage({super.key, required this.id, this.title});

  @override
  State<CatalogDetailPage> createState() => _CatalogDetailPageState();
}

class _CatalogDetailPageState extends State<CatalogDetailPage> {
  final _service = CatalogService();

  bool _isLoading = true;
  bool _needsLogin = false;
  String? _error;
  Map<String, dynamic>? _item;

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
      final result = await _service.getCatalogDetail(
        id: widget.id,
        token: token,
      );

      setState(() {
        _item = result;
        _isLoading = false;
      });
    } catch (e) {
      final session = context.read<SessionProvider>();

      if (ApiErrorHelper.isAuthError(e)) {
        setState(() {
          _needsLogin = true;
          _error = ApiErrorHelper.moduleAccessMessage(
            moduleName: 'el detalle del vehículo',
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

  List<String> _images(Map<String, dynamic> item) {
    final gallery = DataUtils.extractStringList(item, [
      'imagenes',
      'fotos',
      'galeria',
      'gallery',
    ]);

    final mainImage = DataUtils.firstImage(item);
    if (gallery.isEmpty && mainImage.isNotEmpty) return [mainImage];
    if (mainImage.isNotEmpty && !gallery.contains(mainImage)) {
      return [mainImage, ...gallery];
    }
    return gallery;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle vehículo')),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.accent),
        ),
      );
    }

    if (_needsLogin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle vehículo')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 60),
            AccessRequiredView(
              title: 'Detalle del vehículo',
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
        appBar: AppBar(title: const Text('Detalle vehículo')),
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
    final marca = DataUtils.firstString(item, ['marca']);
    final modelo = DataUtils.firstString(item, ['modelo', 'nombre']);
    final anio = DataUtils.firstString(item, ['anio', 'year']);
    final descripcion = DataUtils.firstString(item, [
      'descripcion',
      'descripcion_larga',
      'resumen',
    ], fallback: 'Sin descripción disponible.');
    final precio = DataUtils.firstString(item, ['precio', 'precio_venta']);
    final images = _images(item);

    final nestedSpecsRaw = item['especificaciones'];
    Map<String, dynamic> nestedSpecs = {};

    if (nestedSpecsRaw is Map<String, dynamic>) {
      nestedSpecs = nestedSpecsRaw;
    } else if (nestedSpecsRaw is Map) {
      nestedSpecs = Map<String, dynamic>.from(nestedSpecsRaw);
    }

    final specs = nestedSpecs.isNotEmpty
        ? nestedSpecs
        : (Map<String, dynamic>.from(item)..removeWhere(
            (key, _) => [
              'id',
              'imagen',
              'image',
              'foto',
              'fotoUrl',
              'thumbnail',
              'thumb',
              'portada',
              'banner',
              'url',
              'imagenUrl',
              'imagenes',
              'fotos',
              'galeria',
              'gallery',
              'descripcion',
              'descripcion_larga',
              'resumen',
              'especificaciones',
            ].contains(key),
          ));

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle vehículo')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (images.isNotEmpty)
            CarouselSlider(
              options: CarouselOptions(
                height: 260,
                viewportFraction: 1,
                autoPlay: true,
              ),
              items: images.map((image) {
                return CachedNetworkImage(
                  imageUrl: image,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: AppTheme.softCard,
                    child: const Center(
                      child: CircularProgressIndicator(color: AppTheme.accent),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: AppTheme.softCard,
                    child: const Icon(
                      Icons.car_rental_rounded,
                      color: AppTheme.textSecondary,
                      size: 46,
                    ),
                  ),
                );
              }).toList(),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
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
                    '$marca $modelo ${anio.isEmpty ? '' : '• $anio'}'.trim(),
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (precio.isNotEmpty) const SizedBox(height: 10),
                  if (precio.isNotEmpty)
                    Text(
                      DataUtils.formatMoney(precio),
                      style: const TextStyle(
                        color: AppTheme.accent,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    descripcion,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (specs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
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
                      'Especificaciones',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...specs.entries.map(
                      (entry) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.softCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              entry.value?.toString() ?? '-',
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
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
