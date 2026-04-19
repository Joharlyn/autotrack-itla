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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
      appBar: AppBar(title: const Text('Combustible y aceite')),
      body: RefreshIndicator(
        onRefresh: _loadItems,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
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
                    widget.vehicleName,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
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
                      DropdownMenuItem(value: 'aceite', child: Text('Aceite')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedTipo = value);
                      }
                    },
                    decoration: const InputDecoration(labelText: 'Tipo'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _cantidadController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Cantidad'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedUnidad,
                    items: const [
                      DropdownMenuItem(
                        value: 'galones',
                        child: Text('Galones'),
                      ),
                      DropdownMenuItem(value: 'litros', child: Text('Litros')),
                      DropdownMenuItem(value: 'qt', child: Text('Qt')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedUnidad = value);
                      }
                    },
                    decoration: const InputDecoration(labelText: 'Unidad'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _montoController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Monto'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    child: Text(_isSaving ? 'Guardando...' : 'Registrar'),
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
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              )
            else if (_items.isEmpty)
              const Text(
                'No hay registros todavía.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary),
              )
            else
              ..._items.map((item) {
                final tipo = DataUtils.firstString(item, [
                  'tipo',
                ], fallback: 'Registro');
                final cantidad = DataUtils.firstString(item, ['cantidad']);
                final unidad = DataUtils.firstString(item, ['unidad']);
                final monto = DataUtils.firstString(item, ['monto']);
                final fecha = DataUtils.firstString(item, [
                  'fecha',
                  'created_at',
                ]);

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tipo.toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Cantidad: ${cantidad.isEmpty ? '-' : cantidad} ${unidad.isEmpty ? '' : unidad}',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Monto: ${DataUtils.formatMoney(monto)}',
                        style: const TextStyle(color: AppTheme.accent),
                      ),
                      if (fecha.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'Fecha: ${DataUtils.formatDate(fecha)}',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                            ),
                          ),
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
