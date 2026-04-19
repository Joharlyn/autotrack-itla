import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/storage/session_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/api_error_helper.dart';
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
  bool _needsLogin = false;
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
    setState(() {
      _isLoading = true;
      _needsLogin = false;
      _error = null;
    });

    try {
      final token = context.read<SessionProvider>().token;
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
      final session = context.read<SessionProvider>();

      if (ApiErrorHelper.isAuthError(e)) {
        setState(() {
          _needsLogin = true;
          _error = ApiErrorHelper.moduleAccessMessage(
            moduleName: 'el catálogo de vehículos',
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

  void _clearFilters() {
    _marcaController.clear();
    _modeloController.clear();
    _anioController.clear();
    _precioMinController.clear();
    _precioMaxController.clear();
    _loadCatalog();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo')),
      body: RefreshIndicator(
        onRefresh: _loadCatalog,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filtros',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _marcaController,
                    decoration: const InputDecoration(labelText: 'Marca'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _modeloController,
                    decoration: const InputDecoration(labelText: 'Modelo'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _anioController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Año'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _precioMinController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Precio mínimo',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _precioMaxController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Precio máximo',
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadCatalog,
                    child: const Text('Aplicar filtros'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Limpiar filtros'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.accent),
                ),
              )
            else if (_needsLogin)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: AccessRequiredView(
                  title: 'Catálogo de vehículos',
                  message:
                      _error ?? 'Debes iniciar sesión para ver este contenido.',
                  onRetry: () => _loadCatalog(),
                ),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              )
            else if (_items.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.car_rental_rounded,
                        size: 46,
                        color: AppTheme.accent,
                      ),
                      SizedBox(height: 14),
                      Text(
                        'No hay vehículos disponibles en el catálogo en este momento.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
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
                ),
              )
            else
              ..._items.map((item) {
                final id = DataUtils.firstInt(item, ['id', 'vehiculo_id']);
                final marca = DataUtils.firstString(item, ['marca']);
                final modelo = DataUtils.firstString(item, [
                  'modelo',
                  'nombre',
                ]);
                final anio = DataUtils.firstString(item, ['anio', 'year']);
                final descripcion = DataUtils.firstString(item, [
                  'descripcion',
                  'descripcionCorta',
                  'descripcion_corta',
                  'resumen',
                ], fallback: 'Sin descripción.');
                final precio = DataUtils.firstString(item, [
                  'precio',
                  'precio_venta',
                ]);
                final image = DataUtils.firstImage(item);

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: id == 0
                        ? null
                        : () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.catalogDetail,
                              arguments: {
                                'id': id,
                                'title': '$marca $modelo'.trim(),
                              },
                            );
                          },
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
                                  Icons.car_rental_rounded,
                                  color: AppTheme.textSecondary,
                                  size: 46,
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
                                '$marca $modelo ${anio.isEmpty ? '' : '• $anio'}'
                                    .trim(),
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (precio.isNotEmpty)
                                Text(
                                  DataUtils.formatMoney(precio),
                                  style: const TextStyle(
                                    color: AppTheme.accent,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              if (precio.isNotEmpty) const SizedBox(height: 10),
                              Text(
                                descripcion,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  height: 1.5,
                                ),
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
