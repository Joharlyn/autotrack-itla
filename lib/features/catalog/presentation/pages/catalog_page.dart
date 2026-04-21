import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/storage/session_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/data_utils.dart';
import '../../../../shared/widgets/access_required_view.dart';
import '../../data/services/catalog_service.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final _service = CatalogService();

  final _marcaController = TextEditingController();
  final _modeloController = TextEditingController();
  final _anioController = TextEditingController();
  final _precioMinController = TextEditingController();
  final _precioMaxController = TextEditingController();

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  @override
  void dispose() {
    _marcaController.dispose();
    _modeloController.dispose();
    _anioController.dispose();
    _precioMinController.dispose();
    _precioMaxController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    final token = context.read<SessionProvider>().token;

    if (token == null || token.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = null;
        _items = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _service.getCatalog(
        token: token,
        marca: _marcaController.text,
        modelo: _modeloController.text,
        anio: _anioController.text,
        precioMin: _precioMinController.text,
        precioMax: _precioMaxController.text,
      );

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

  void _clearFilters() {
    _marcaController.clear();
    _modeloController.clear();
    _anioController.clear();
    _precioMinController.clear();
    _precioMaxController.clear();
    _loadCatalog();
  }

  void _openDetail(Map<String, dynamic> item) {
    final id = DataUtils.firstInt(item, ['id']);
    final title = '${DataUtils.firstString(item, ['marca'])} ${DataUtils.firstString(item, ['modelo'])}'.trim();

    Navigator.pushNamed(
      context,
      AppRoutes.catalogDetail,
      arguments: {
        'id': id,
        'title': title,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.watch<SessionProvider>().isLoggedIn;

    if (!isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Catálogo')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            SizedBox(height: 60),
            AccessRequiredView(
              title: 'Catálogo',
              message: 'Debes iniciar sesión para consultar este módulo según el comportamiento actual del backend.',
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadCatalog,
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
                      'Explora el catálogo',
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
                          ? 'Busca por marca, modelo, año o rango de precio para encontrar vehículos.'
                          : 'Se encontraron ${_items.length} vehículo${_items.length == 1 ? '' : 's'} para tu consulta.',
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
                            title: 'Resultados',
                            value: '${_items.length}',
                            icon: Icons.car_rental_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: _TopStat(
                            title: 'Búsqueda',
                            value: 'Filtros activos',
                            icon: Icons.tune_rounded,
                          ),
                        ),
                      ],
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
                    'Buscar vehículos',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Usa los filtros para refinar la búsqueda dentro del catálogo.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _marcaController,
                    decoration: const InputDecoration(
                      labelText: 'Marca',
                      prefixIcon: Icon(Icons.sell_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _modeloController,
                    decoration: const InputDecoration(
                      labelText: 'Modelo',
                      prefixIcon: Icon(Icons.directions_car_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _anioController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Año',
                      prefixIcon: Icon(Icons.calendar_month_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _precioMinController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Precio mínimo',
                      prefixIcon: Icon(Icons.trending_down_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _precioMaxController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Precio máximo',
                      prefixIcon: Icon(Icons.trending_up_rounded),
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: _loadCatalog,
                    icon: const Icon(Icons.search_rounded),
                    label: const Text('Buscar vehículos'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Limpiar filtros'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const _SectionHeader(
              title: 'Vehículos del catálogo',
              subtitle: 'Selecciona un vehículo para ver más detalles, galería e información técnica.',
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
                      Icons.car_rental_rounded,
                      size: 50,
                      color: AppTheme.accent,
                    ),
                    SizedBox(height: 14),
                    Text(
                      'No hay vehículos disponibles en el catálogo en este momento.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Prueba ajustando los filtros o vuelve a intentarlo más tarde.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._items.map((item) {
                final image = DataUtils.firstImage(item);
                final marca = DataUtils.firstString(item, ['marca']);
                final modelo = DataUtils.firstString(item, ['modelo']);
                final anio = DataUtils.firstString(item, ['anio', 'year']);
                final precio = DataUtils.firstString(item, ['precio']);
                final descripcion = DataUtils.firstString(
                  item,
                  ['descripcion', 'descripcionCorta', 'descripcion_corta', 'resumen'],
                  fallback: 'Sin descripción.',
                );

                final title = '$marca $modelo'.trim().isEmpty
                    ? 'Vehículo'
                    : '$marca $modelo'.trim();

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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                          child: image.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: image,
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
                                )
                              : Container(
                                  width: double.infinity,
                                  height: 190,
                                  color: AppTheme.softCard,
                                  child: const Icon(
                                    Icons.directions_car_rounded,
                                    color: AppTheme.textSecondary,
                                    size: 42,
                                  ),
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
                              const SizedBox(height: 14),
                              Text(
                                descripcion,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: const [
                                  Text(
                                    'Ver detalle',
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