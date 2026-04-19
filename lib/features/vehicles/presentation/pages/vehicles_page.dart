import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/storage/session_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/access_required_view.dart';
import '../../../../shared/utils/data_utils.dart';
import '../../data/services/vehicles_service.dart';

class VehiclesPage extends StatefulWidget {
  const VehiclesPage({super.key});

  @override
  State<VehiclesPage> createState() => _VehiclesPageState();
}

class _VehiclesPageState extends State<VehiclesPage> {
  final _service = VehiclesService();

  final _marcaController = TextEditingController();
  final _modeloController = TextEditingController();

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _vehicles = [];

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  @override
  void dispose() {
    _marcaController.dispose();
    _modeloController.dispose();
    super.dispose();
  }

  Future<void> _loadVehicles() async {
    final session = context.read<SessionProvider>();
    final token = session.token;

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
      final result = await _service.getVehicles(
        token,
        marca: _marcaController.text,
        modelo: _modeloController.text,
      );

      setState(() {
        _vehicles = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _goToCreate() async {
    final created = await Navigator.pushNamed(context, AppRoutes.vehicleForm);

    if (created == true) {
      _loadVehicles();
    }
  }

  Future<void> _goToDetail(int id) async {
    final updated = await Navigator.pushNamed(
      context,
      AppRoutes.vehicleDetail,
      arguments: {'id': id},
    );

    if (updated == true) {
      _loadVehicles();
    }
  }

  void _clearFilters() {
    _marcaController.clear();
    _modeloController.clear();
    _loadVehicles();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();

    if (!session.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mis vehículos')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            SizedBox(height: 60),
            AccessRequiredView(
              title: 'Mis vehículos',
              message: 'Debes iniciar sesión para gestionar tus vehículos.',
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis vehículos'),
        actions: [
          IconButton(
            onPressed: _goToCreate,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.accent,
        onPressed: _goToCreate,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _loadVehicles,
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
                    'Búsqueda',
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
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadVehicles,
                    child: const Text('Buscar'),
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
            else if (_vehicles.isEmpty)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.directions_car_outlined,
                      size: 48,
                      color: AppTheme.accent,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Todavía no has registrado vehículos.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._vehicles.map((item) {
                final id = DataUtils.firstInt(item, ['id', 'vehiculo_id']);
                final placa = DataUtils.firstString(item, [
                  'placa',
                ], fallback: '-');
                final marca = DataUtils.firstString(item, ['marca']);
                final modelo = DataUtils.firstString(item, [
                  'modelo',
                  'nombre',
                ]);
                final anio = DataUtils.firstString(item, ['anio', 'year']);
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
                    onTap: id == 0 ? null : () => _goToDetail(id),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(18),
                          ),
                          child: image.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: image,
                                  width: 110,
                                  height: 110,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(
                                    width: 110,
                                    height: 110,
                                    color: AppTheme.softCard,
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: AppTheme.accent,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (_, __, ___) => Container(
                                    width: 110,
                                    height: 110,
                                    color: AppTheme.softCard,
                                    child: const Icon(
                                      Icons.directions_car_rounded,
                                      color: AppTheme.textSecondary,
                                      size: 34,
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 110,
                                  height: 110,
                                  color: AppTheme.softCard,
                                  child: const Icon(
                                    Icons.directions_car_rounded,
                                    color: AppTheme.textSecondary,
                                    size: 34,
                                  ),
                                ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$marca $modelo'.trim().isEmpty
                                      ? 'Vehículo'
                                      : '$marca $modelo'.trim(),
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Placa: $placa',
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Año: ${anio.isEmpty ? '-' : anio}',
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: Icon(
                            Icons.chevron_right_rounded,
                            color: AppTheme.textSecondary,
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
