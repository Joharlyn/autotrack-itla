import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/storage/session_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/data_utils.dart';
import '../../../../shared/widgets/access_required_view.dart';
import '../../data/services/catalog_service.dart';

class CatalogDetailPage extends StatefulWidget {
  final int id;
  final String? title;

  const CatalogDetailPage({
    super.key,
    required this.id,
    this.title,
  });

  @override
  State<CatalogDetailPage> createState() => _CatalogDetailPageState();
}

class _CatalogDetailPageState extends State<CatalogDetailPage> {
  final _service = CatalogService();

  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _item;
  int _selectedImageIndex = 0;

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
      final result = await _service.getCatalogDetail(
        id: widget.id,
        token: token,
      );

      setState(() {
        _item = result;
        _selectedImageIndex = 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<String> _galleryOf(Map<String, dynamic> item) {
    final images = DataUtils.extractStringList(
      item,
      ['imagenes', 'fotos', 'galeria', 'gallery'],
    );

    final first = DataUtils.firstImage(item);
    if (images.isEmpty && first.isNotEmpty) return [first];
    if (first.isNotEmpty && !images.contains(first)) {
      return [first, ...images];
    }
    return images;
  }

  Map<String, dynamic> _specsOf(Map<String, dynamic> item) {
    final nestedSpecsRaw = item['especificaciones'];
    Map<String, dynamic> nestedSpecs = {};

    if (nestedSpecsRaw is Map<String, dynamic>) {
      nestedSpecs = nestedSpecsRaw;
    } else if (nestedSpecsRaw is Map) {
      nestedSpecs = Map<String, dynamic>.from(nestedSpecsRaw);
    }

    if (nestedSpecs.isNotEmpty) return nestedSpecs;

    final fallback = Map<String, dynamic>.from(item);
    fallback.removeWhere((key, _) => [
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
        ].contains(key));

    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.watch<SessionProvider>().isLoggedIn;

    if (!isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle catálogo')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            SizedBox(height: 60),
            AccessRequiredView(
              title: 'Detalle del catálogo',
              message: 'Debes iniciar sesión para consultar este módulo según el comportamiento actual del backend.',
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle catálogo')),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.accent),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle catálogo')),
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
    final gallery = _galleryOf(item);
    final specs = _specsOf(item);

    final marca = DataUtils.firstString(item, ['marca']);
    final modelo = DataUtils.firstString(item, ['modelo']);
    final anio = DataUtils.firstString(item, ['anio', 'year']);
    final precio = DataUtils.firstString(item, ['precio']);
    final descripcion = DataUtils.firstString(
      item,
      ['descripcion', 'descripcion_larga', 'resumen'],
      fallback: 'Sin descripción disponible.',
    );

    final title = '$marca $modelo'.trim().isEmpty
        ? (widget.title ?? 'Vehículo')
        : '$marca $modelo'.trim();

    final currentImage =
        gallery.isNotEmpty && _selectedImageIndex < gallery.length
            ? gallery[_selectedImageIndex]
            : '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle catálogo'),
      ),
      body: ListView(
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
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  child: currentImage.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: currentImage,
                          width: double.infinity,
                          height: 250,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            height: 250,
                            color: AppTheme.softCard,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.accent,
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            height: 250,
                            color: AppTheme.softCard,
                            child: const Icon(
                              Icons.image_not_supported_rounded,
                              color: AppTheme.textSecondary,
                              size: 50,
                            ),
                          ),
                        )
                      : Container(
                          height: 250,
                          color: AppTheme.softCard,
                          child: const Center(
                            child: Icon(
                              Icons.directions_car_rounded,
                              color: AppTheme.textSecondary,
                              size: 50,
                            ),
                          ),
                        ),
                ),
                if (gallery.length > 1)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: SizedBox(
                      height: 76,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: gallery.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final image = gallery[index];
                          final selected = index == _selectedImageIndex;

                          return GestureDetector(
                            onTap: () {
                              setState(() => _selectedImageIndex = index);
                            },
                            child: Container(
                              width: 88,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: selected
                                      ? AppTheme.accent
                                      : AppTheme.border,
                                  width: selected ? 1.6 : 1,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: CachedNetworkImage(
                                  imageUrl: image,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Container(
                                    color: AppTheme.softCard,
                                    child: const Icon(
                                      Icons.image_not_supported_rounded,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
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
                          if (anio.isNotEmpty)
                            _DataPill(
                              icon: Icons.calendar_month_rounded,
                              text: anio,
                            ),
                          if (precio.isNotEmpty)
                            _DataPill(
                              icon: Icons.payments_rounded,
                              text: DataUtils.formatMoney(precio),
                            ),
                        ],
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
                  'Descripción',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  descripcion,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 15,
                    height: 1.65,
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
                  'Especificaciones',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                if (specs.isEmpty)
                  const Text(
                    'No hay especificaciones disponibles.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                    ),
                  )
                else
                  ...specs.entries.map((entry) {
                    final value = entry.value?.toString().trim() ?? '';
                    if (value.isEmpty) return const SizedBox.shrink();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.softCard,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.info_outline_rounded,
                              color: AppTheme.accent,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.key,
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  value,
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
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