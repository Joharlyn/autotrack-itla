import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/storage/session_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/data_utils.dart';
import '../../../../shared/widgets/access_required_view.dart';
import '../../data/services/vehicle_records_service.dart';

class TiresPage extends StatefulWidget {
  final int vehicleId;
  final String vehicleName;

  const TiresPage({
    super.key,
    required this.vehicleId,
    required this.vehicleName,
  });

  @override
  State<TiresPage> createState() => _TiresPageState();
}

class _TiresPageState extends State<TiresPage> {
  final _service = VehicleRecordsService();

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _loadTires();
  }

  Future<void> _loadTires() async {
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
      final result = await _service.getTires(token, widget.vehicleId);
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

  Future<void> _updateStatus(int gomaId, String estado) async {
    final token = context.read<SessionProvider>().token;
    if (token == null || token.isEmpty) return;

    try {
      await _service.updateTireStatus(
        token: token,
        gomaId: gomaId,
        estado: estado,
      );
      await _loadTires();
      if (!mounted) return;
      _showSnack('Estado actualizado.');
    } catch (e) {
      _showSnack(e.toString());
    }
  }

  Future<void> _registerPuncture(int gomaId) async {
    final token = context.read<SessionProvider>().token;
    if (token == null || token.isEmpty) return;

    final descripcionController = TextEditingController();
    String? fecha;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              backgroundColor: AppTheme.card,
              title: const Text(
                'Registrar pinchazo',
                style: TextStyle(color: AppTheme.textPrimary),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: descripcionController,
                    decoration: const InputDecoration(labelText: 'Descripción'),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        initialDate: DateTime.now(),
                      );

                      if (picked != null) {
                        setLocalState(() {
                          fecha =
                              '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                        });
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.softCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Text(
                        fecha == null ? 'Seleccionar fecha' : 'Fecha: $fecha',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true) return;

    final descripcion = descripcionController.text.trim();
    if (descripcion.isEmpty) {
      _showSnack('Escribe una descripción.');
      return;
    }

    try {
      await _service.createPuncture(
        token: token,
        gomaId: gomaId,
        descripcion: descripcion,
        fecha: fecha,
      );
      await _loadTires();
      if (!mounted) return;
      _showSnack('Pinchazo registrado.');
    } catch (e) {
      _showSnack(e.toString());
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
        appBar: AppBar(title: const Text('Estado de gomas')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            SizedBox(height: 60),
            AccessRequiredView(
              title: 'Estado de gomas',
              message: 'Debes iniciar sesión para gestionar este módulo.',
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Estado de gomas')),
      body: RefreshIndicator(
        onRefresh: _loadTires,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              widget.vehicleName,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
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
                'No hay gomas disponibles.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary),
              )
            else
              ..._items.map((item) {
                final gomaId = DataUtils.firstInt(item, ['id', 'goma_id']);
                final posicion = DataUtils.firstString(item, [
                  'posicion',
                  'position',
                ], fallback: 'Sin posición');
                final eje = DataUtils.firstString(item, [
                  'eje',
                  'axle',
                ], fallback: '-');
                final estado = DataUtils.firstString(item, [
                  'estado',
                  'status',
                ], fallback: 'regular');

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
                        posicion,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Eje: $eje',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: estado,
                        items: const [
                          DropdownMenuItem(
                            value: 'buena',
                            child: Text('Buena'),
                          ),
                          DropdownMenuItem(
                            value: 'regular',
                            child: Text('Regular'),
                          ),
                          DropdownMenuItem(value: 'mala', child: Text('Mala')),
                          DropdownMenuItem(
                            value: 'reemplazada',
                            child: Text('Reemplazada'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null && gomaId != 0) {
                            _updateStatus(gomaId, value);
                          }
                        },
                        decoration: const InputDecoration(labelText: 'Estado'),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: gomaId == 0
                            ? null
                            : () => _registerPuncture(gomaId),
                        icon: const Icon(Icons.build_circle_rounded),
                        label: const Text('Registrar pinchazo'),
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
