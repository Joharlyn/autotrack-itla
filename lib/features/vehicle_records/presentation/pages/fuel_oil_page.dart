import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/storage/session_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/data_utils.dart';
import '../../../../shared/widgets/access_required_view.dart';
import '../../data/services/vehicle_records_service.dart';

class FuelOilPage extends StatefulWidget {
  final int vehicleId;
  final String vehicleName;

  const FuelOilPage({
    super.key,
    required this.vehicleId,
    required this.vehicleName,
  });

  @override
  State<FuelOilPage> createState() => _FuelOilPageState();
}

class _FuelOilPageState extends State<FuelOilPage> {
  final _service = VehicleRecordsService();

  final _cantidadController = TextEditingController();
  final _montoController = TextEditingController();

  String _selectedTipo = 'combustible';
  String _selectedUnidad = 'galones';

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _montoController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
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
      final result = await _service.getFuelOilEntries(token, widget.vehicleId);
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

  Future<void> _save() async {
    final token = context.read<SessionProvider>().token;

    if (token == null || token.isEmpty) {
      _showSnack('No hay una sesión activa.');
      return;
    }

    final cantidad = double.tryParse(_cantidadController.text.trim());
    final monto = double.tryParse(_montoController.text.trim());

    if (cantidad == null || monto == null) {
      _showSnack('Completa cantidad y monto correctamente.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _service.createFuelOilEntry(
        token: token,
        data: {
          'vehiculo_id': widget.vehicleId,
          'tipo': _selectedTipo,
          'cantidad': cantidad,
          'unidad': _selectedUnidad,
          'monto': monto,
        },
      );

      _cantidadController.clear();
      _montoController.clear();

      await _loadItems();

      if (!mounted) return;
      _showSnack('Registro guardado.');
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Color _typeColor(String tipo) {
    return tipo.toLowerCase() == 'aceite'
        ? AppTheme.accentBlue
        : AppTheme.accent;
  }

  IconData _typeIcon(String tipo) {
    return tipo.toLowerCase() == 'aceite'
        ? Icons.oil_barrel_rounded
        : Icons.local_gas_station_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.watch<SessionProvider>().isLoggedIn;

    if (!isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Combustible y aceite')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            SizedBox(height: 60),
            AccessRequiredView(
              title: 'Combustible y aceite',
              message: 'Debes iniciar sesión para gestionar este módulo.',
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Combustible y aceite'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadItems,
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
                    Text(
                      widget.vehicleName,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Controla cargas de combustible y registros de aceite del vehículo.',
                      style: TextStyle(
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
                            title: 'Registros',
                            value: '${_items.length}',
                            icon: Icons.receipt_long_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TopStat(
                            title: 'Tipo actual',
                            value: _selectedTipo.toUpperCase(),
                            icon: _typeIcon(_selectedTipo),
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
                    'Registrar carga',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Guarda los datos del abastecimiento o cambio de aceite realizado.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedTipo,
                    items: const [
                      DropdownMenuItem(
                        value: 'combustible',
                        child: Text('Combustible'),
                      ),
                      DropdownMenuItem(
                        value: 'aceite',
                        child: Text('Aceite'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedTipo = value);
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Tipo',
                      prefixIcon: Icon(Icons.category_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _cantidadController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Cantidad',
                      prefixIcon: Icon(Icons.straighten_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedUnidad,
                    items: const [
                      DropdownMenuItem(
                        value: 'galones',
                        child: Text('Galones'),
                      ),
                      DropdownMenuItem(
                        value: 'litros',
                        child: Text('Litros'),
                      ),
                      DropdownMenuItem(
                        value: 'qt',
                        child: Text('Qt'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedUnidad = value);
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Unidad',
                      prefixIcon: Icon(Icons.square_foot_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _montoController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Monto',
                      prefixIcon: Icon(Icons.payments_rounded),
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: const Icon(Icons.save_rounded),
                    label: Text(_isSaving ? 'Guardando...' : 'Registrar'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const _SectionHeader(
              title: 'Historial de registros',
              subtitle: 'Consulta cada carga o cambio de aceite realizado.',
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
                      Icons.local_gas_station_outlined,
                      size: 50,
                      color: AppTheme.accent,
                    ),
                    SizedBox(height: 14),
                    Text(
                      'No hay registros todavía.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Registra la primera carga para comenzar a llevar el control del vehículo.',
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
                final tipo = DataUtils.firstString(
                  item,
                  ['tipo'],
                  fallback: 'Registro',
                );
                final cantidad = DataUtils.firstString(item, ['cantidad']);
                final unidad = DataUtils.firstString(item, ['unidad']);
                final monto = DataUtils.firstString(item, ['monto']);
                final fecha = DataUtils.firstString(item, ['fecha', 'created_at']);
                final color = _typeColor(tipo);

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              _typeIcon(tipo),
                              color: color,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              tipo.toUpperCase(),
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _DataPill(
                            icon: Icons.straighten_rounded,
                            text:
                                '${cantidad.isEmpty ? '-' : cantidad} ${unidad.isEmpty ? '' : unidad}',
                          ),
                          _DataPill(
                            icon: Icons.payments_rounded,
                            text: DataUtils.formatMoney(monto),
                          ),
                          if (fecha.isNotEmpty)
                            _DataPill(
                              icon: Icons.calendar_month_rounded,
                              text: DataUtils.formatDate(fecha),
                            ),
                        ],
                      ),
                    ],
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