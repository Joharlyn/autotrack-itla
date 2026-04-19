import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/storage/session_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/data_utils.dart';
import '../../../../shared/utils/image_pick_helper.dart';
import '../../../../shared/widgets/access_required_view.dart';
import '../../data/services/vehicles_service.dart';

class VehicleDetailPage extends StatefulWidget {
  final int id;

  const VehicleDetailPage({super.key, required this.id});

  @override
  State<VehicleDetailPage> createState() => _VehicleDetailPageState();
}

class _VehicleDetailPageState extends State<VehicleDetailPage> {
  final _service = VehiclesService();

  bool _isLoading = true;
  bool _isUpdatingPhoto = false;
  String? _error;
  Map<String, dynamic>? _vehicle;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
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
      final result = await _service.getVehicleDetail(token, widget.id);
      setState(() {
        _vehicle = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _changePhoto() async {
    final session = context.read<SessionProvider>();
    final token = session.token;

    if (token == null || token.isEmpty) {
      _showSnack('No hay una sesión activa.');
      return;
    }

    final image = await ImagePickHelper.pickImage(context);
    if (image == null) return;

    setState(() => _isUpdatingPhoto = true);

    try {
      await _service.updateVehiclePhoto(
        token: token,
        vehicleId: widget.id,
        photoPath: image.path,
      );

      await _loadDetail();

      if (!mounted) return;
      _showSnack('Foto del vehículo actualizada.');
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isUpdatingPhoto = false);
      }
    }
  }

  Future<void> _goToEdit() async {
    final updated = await Navigator.pushNamed(
      context,
      AppRoutes.vehicleForm,
      arguments: {'vehicle': _vehicle},
    );

    if (updated == true) {
      _loadDetail();
    }
  }

  Map<String, dynamic> _financialMap(Map<String, dynamic> item) {
    final candidates = [
      item['resumen_financiero'],
      item['resumenFinanciero'],
      item['totales'],
      item['resumen'],
      item['balance_financiero'],
    ];

    for (final candidate in candidates) {
      if (candidate is Map<String, dynamic>) return candidate;
      if (candidate is Map) return Map<String, dynamic>.from(candidate);
    }

    final map = <String, dynamic>{
      'total_mantenimientos':
          item['total_mantenimientos'] ?? item['totalMantenimientos'],
      'total_combustible':
          item['total_combustible'] ?? item['totalCombustible'],
      'total_gastos': item['total_gastos'] ?? item['totalGastos'],
      'total_ingresos': item['total_ingresos'] ?? item['totalIngresos'],
      'balance': item['balance'],
    };

    map.removeWhere(
      (key, value) => value == null || value.toString().trim().isEmpty,
    );
    return map;
  }

  String get _vehicleName {
    final item = _vehicle ?? {};
    final marca = DataUtils.firstString(item, ['marca']);
    final modelo = DataUtils.firstString(item, ['modelo', 'nombre']);
    final full = '$marca $modelo'.trim();
    return full.isEmpty ? 'Vehículo' : full;
  }

  void _openModule(String route) {
    Navigator.pushNamed(
      context,
      route,
      arguments: {'vehicleId': widget.id, 'vehicleName': _vehicleName},
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();

    if (!session.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle vehículo')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            SizedBox(height: 60),
            AccessRequiredView(
              title: 'Detalle del vehículo',
              message: 'Debes iniciar sesión para ver este contenido.',
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle vehículo')),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.accent),
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

    final item = _vehicle ?? {};
    final image = DataUtils.firstImage(item);
    final placa = DataUtils.firstString(item, ['placa'], fallback: '-');
    final chasis = DataUtils.firstString(item, ['chasis'], fallback: '-');
    final marca = DataUtils.firstString(item, ['marca']);
    final modelo = DataUtils.firstString(item, ['modelo', 'nombre']);
    final anio = DataUtils.firstString(item, ['anio', 'year'], fallback: '-');
    final ruedas = DataUtils.firstString(item, [
      'cantidadRuedas',
      'cantidad_ruedas',
      'ruedas',
    ], fallback: '-');

    final financial = _financialMap(item);

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle vehículo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
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
                      height: 230,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        height: 230,
                        color: AppTheme.softCard,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.accent,
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        height: 230,
                        color: AppTheme.softCard,
                        child: const Icon(
                          Icons.directions_car_rounded,
                          color: AppTheme.textSecondary,
                          size: 44,
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
                        _vehicleName,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _goToEdit,
                            icon: const Icon(Icons.edit_rounded),
                            label: const Text('Editar datos'),
                          ),
                          ElevatedButton.icon(
                            onPressed: _isUpdatingPhoto ? null : _changePhoto,
                            icon: const Icon(Icons.photo_camera_rounded),
                            label: Text(
                              _isUpdatingPhoto
                                  ? 'Cambiando foto...'
                                  : 'Cambiar foto',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _InfoCard(
            title: 'Módulos del vehículo',
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _openModule(AppRoutes.maintenance),
                    icon: const Icon(Icons.build_rounded),
                    label: const Text('Mantenimientos'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _openModule(AppRoutes.fuelOil),
                    icon: const Icon(Icons.local_gas_station_rounded),
                    label: const Text('Combustible/Aceite'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _openModule(AppRoutes.tires),
                    icon: const Icon(Icons.tire_repair_rounded),
                    label: const Text('Estado de gomas'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _openModule(AppRoutes.expenseIncome),
                    icon: const Icon(Icons.payments_rounded),
                    label: const Text('Gastos/Ingresos'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _openModule(AppRoutes.forumPrivate),
                    icon: const Icon(Icons.forum_rounded),
                    label: const Text('Foro'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InfoCard(
            title: 'Datos principales',
            children: [
              _InfoRow(label: 'Placa', value: placa),
              _InfoRow(label: 'Chasis', value: chasis),
              _InfoRow(label: 'Marca', value: marca.isEmpty ? '-' : marca),
              _InfoRow(label: 'Modelo', value: modelo.isEmpty ? '-' : modelo),
              _InfoRow(label: 'Año', value: anio),
              _InfoRow(label: 'Cantidad de ruedas', value: ruedas),
            ],
          ),
          const SizedBox(height: 16),
          _InfoCard(
            title: 'Resumen financiero',
            children: financial.isEmpty
                ? const [
                    Text(
                      'No hay resumen financiero disponible todavía.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ]
                : [
                    _InfoRow(
                      label: 'Mantenimientos',
                      value: DataUtils.formatMoney(
                        financial['total_mantenimientos'] ??
                            financial['totalMantenimientos'],
                      ),
                    ),
                    _InfoRow(
                      label: 'Combustible',
                      value: DataUtils.formatMoney(
                        financial['total_combustible'] ??
                            financial['totalCombustible'],
                      ),
                    ),
                    _InfoRow(
                      label: 'Gastos',
                      value: DataUtils.formatMoney(
                        financial['total_gastos'] ?? financial['totalGastos'],
                      ),
                    ),
                    _InfoRow(
                      label: 'Ingresos',
                      value: DataUtils.formatMoney(
                        financial['total_ingresos'] ??
                            financial['totalIngresos'],
                      ),
                    ),
                    _InfoRow(
                      label: 'Balance',
                      value: DataUtils.formatMoney(financial['balance']),
                    ),
                  ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 145,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
