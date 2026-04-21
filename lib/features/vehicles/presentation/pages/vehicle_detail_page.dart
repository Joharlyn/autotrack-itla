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

  const VehicleDetailPage({
    super.key,
    required this.id,
  });

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
      arguments: {
        'vehicle': _vehicle,
      },
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
      'total_mantenimientos': item['total_mantenimientos'] ?? item['totalMantenimientos'],
      'total_combustible': item['total_combustible'] ?? item['totalCombustible'],
      'total_gastos': item['total_gastos'] ?? item['totalGastos'],
      'total_ingresos': item['total_ingresos'] ?? item['totalIngresos'],
      'balance': item['balance'],
    };

    map.removeWhere((key, value) => value == null || value.toString().trim().isEmpty);
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
      arguments: {
        'vehicleId': widget.id,
        'vehicleName': _vehicleName,
      },
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
    final anio = DataUtils.firstString(
      item,
      ['anio', 'year'],
      fallback: '-',
    );
    final ruedas = DataUtils.firstString(
      item,
      ['cantidadRuedas', 'cantidad_ruedas', 'ruedas'],
      fallback: '-',
    );

    final financial = _financialMap(item);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle vehículo'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppTheme.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x18000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (image.isNotEmpty)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: image,
                      width: double.infinity,
                      height: 240,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        height: 240,
                        color: AppTheme.softCard,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.accent,
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        height: 240,
                        color: AppTheme.softCard,
                        child: const Icon(
                          Icons.directions_car_rounded,
                          color: AppTheme.textSecondary,
                          size: 44,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    height: 220,
                    decoration: const BoxDecoration(
                      color: AppTheme.softCard,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.directions_car_rounded,
                        color: AppTheme.textSecondary,
                        size: 50,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _vehicleName,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.8,
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
                      const SizedBox(height: 10),
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
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _ActionButton(
                            icon: Icons.edit_rounded,
                            label: 'Editar datos',
                            onTap: _goToEdit,
                          ),
                          _ActionButton(
                            icon: Icons.photo_camera_rounded,
                            label: _isUpdatingPhoto
                                ? 'Cambiando foto...'
                                : 'Cambiar foto',
                            onTap: _isUpdatingPhoto ? null : _changePhoto,
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
          const _SectionHeader(
            title: 'Módulos del vehículo',
            subtitle: 'Accede a cada área de gestión relacionada con este vehículo.',
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _ModuleCard(
                icon: Icons.build_rounded,
                title: 'Mantenimientos',
                subtitle: 'Registra y consulta servicios realizados.',
                onTap: () => _openModule(AppRoutes.maintenance),
              ),
              _ModuleCard(
                icon: Icons.local_gas_station_rounded,
                title: 'Combustible / Aceite',
                subtitle: 'Controla consumo y registros relacionados.',
                onTap: () => _openModule(AppRoutes.fuelOil),
              ),
              _ModuleCard(
                icon: Icons.tire_repair_rounded,
                title: 'Estado de gomas',
                subtitle: 'Actualiza estado y registra pinchazos.',
                onTap: () => _openModule(AppRoutes.tires),
              ),
              _ModuleCard(
                icon: Icons.payments_rounded,
                title: 'Gastos / Ingresos',
                subtitle: 'Gestiona finanzas del vehículo.',
                onTap: () => _openModule(AppRoutes.expenseIncome),
              ),
              _ModuleCard(
                icon: Icons.forum_rounded,
                title: 'Foro',
                subtitle: 'Participa en discusiones asociadas.',
                onTap: () => _openModule(AppRoutes.forumPrivate),
              ),
            ],
          ),
          const SizedBox(height: 22),
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
          const SizedBox(height: 18),
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
                    _FinanceTile(
                      label: 'Mantenimientos',
                      value: DataUtils.formatMoney(
                        financial['total_mantenimientos'] ??
                            financial['totalMantenimientos'],
                      ),
                      icon: Icons.build_rounded,
                    ),
                    _FinanceTile(
                      label: 'Combustible',
                      value: DataUtils.formatMoney(
                        financial['total_combustible'] ??
                            financial['totalCombustible'],
                      ),
                      icon: Icons.local_gas_station_rounded,
                    ),
                    _FinanceTile(
                      label: 'Gastos',
                      value: DataUtils.formatMoney(
                        financial['total_gastos'] ?? financial['totalGastos'],
                      ),
                      icon: Icons.receipt_long_rounded,
                    ),
                    _FinanceTile(
                      label: 'Ingresos',
                      value: DataUtils.formatMoney(
                        financial['total_ingresos'] ?? financial['totalIngresos'],
                      ),
                      icon: Icons.payments_rounded,
                    ),
                    _FinanceTile(
                      label: 'Balance',
                      value: DataUtils.formatMoney(financial['balance']),
                      icon: Icons.account_balance_wallet_rounded,
                      highlight: true,
                    ),
                  ],
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 44) / 2,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: AppTheme.accent),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

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
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinanceTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool highlight;

  const _FinanceTile({
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight ? AppTheme.accent.withOpacity(0.08) : AppTheme.softCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlight ? AppTheme.accent.withOpacity(0.28) : AppTheme.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: highlight ? AppTheme.accentSoft : AppTheme.accent,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: highlight ? AppTheme.accentSoft : AppTheme.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}