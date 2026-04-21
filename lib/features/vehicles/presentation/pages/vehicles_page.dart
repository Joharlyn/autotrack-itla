import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/storage/session_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/data_utils.dart';
import '../../../../shared/widgets/access_required_view.dart';
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
    final created = await Navigator.pushNamed(
      context,
      AppRoutes.vehicleForm,
    );

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
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.accent,
        onPressed: _goToCreate,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Nuevo vehículo',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadVehicles,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 90),
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
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Garage personal',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _vehicles.isEmpty
                          ? 'Administra y organiza todos tus vehículos en un solo lugar.'
                          : 'Tienes ${_vehicles.length} vehículo${_vehicles.length == 1 ? '' : 's'} registrado${_vehicles.length == 1 ? '' : 's'}.',
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
                            title: 'Registrados',
                            value: '${_vehicles.length}',
                            icon: Icons.directions_car_filled_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: _TopStat(
                            title: 'Acciones',
                            value: 'Crear / Editar',
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
              padding: const EdgeInsets.all(18),
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
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Filtra por marca o modelo para encontrar un vehículo más rápido.',
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
                      hintText: 'Ej: Nissan',
                      prefixIcon: Icon(Icons.sell_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _modeloController,
                    decoration: const InputDecoration(
                      labelText: 'Modelo',
                      hintText: 'Ej: Skyline GT-R R34',
                      prefixIcon: Icon(Icons.directions_car_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadVehicles,
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
            const Text(
              'Vehículos registrados',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Selecciona un vehículo para consultar sus módulos y resumen financiero.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
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
            else if (_vehicles.isEmpty)
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
                      Icons.directions_car_outlined,
                      size: 52,
                      color: AppTheme.accent,
                    ),
                    SizedBox(height: 14),
                    Text(
                      'Todavía no has registrado vehículos.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Crea tu primer vehículo para comenzar a gestionar mantenimiento, combustible, finanzas y más.',
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
              ..._vehicles.map((item) {
                final id = DataUtils.firstInt(item, ['id', 'vehiculo_id']);
                final placa =
                    DataUtils.firstString(item, ['placa'], fallback: '-');
                final marca = DataUtils.firstString(item, ['marca']);
                final modelo =
                    DataUtils.firstString(item, ['modelo', 'nombre']);
                final anio = DataUtils.firstString(item, ['anio', 'year']);
                final image = DataUtils.firstImage(item);

                final title = '$marca $modelo'.trim().isEmpty
                    ? 'Vehículo'
                    : '$marca $modelo'.trim();

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.border),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x18000000),
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: id == 0 ? null : () => _goToDetail(id),
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
                                      Icons.directions_car_rounded,
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
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 21,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                  ),
                                  if (anio.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.accent.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        anio,
                                        style: const TextStyle(
                                          color: AppTheme.accent,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.pin_outlined,
                                    color: AppTheme.textSecondary,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Placa: $placa',
                                    style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: const [
                                  Text(
                                    'Ver detalle completo',
                                    style: TextStyle(
                                      color: AppTheme.accent,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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