import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/storage/session_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/data_utils.dart';
import '../../../../shared/utils/multi_image_pick_helper.dart';
import '../../../../shared/widgets/access_required_view.dart';
import '../../data/services/vehicle_records_service.dart';

class MaintenancePage extends StatefulWidget {
  final int vehicleId;
  final String vehicleName;

  const MaintenancePage({
    super.key,
    required this.vehicleId,
    required this.vehicleName,
  });

  @override
  State<MaintenancePage> createState() => _MaintenancePageState();
}

class _MaintenancePageState extends State<MaintenancePage> {
  final _service = VehicleRecordsService();

  final _tipoController = TextEditingController();
  final _costoController = TextEditingController();
  final _piezasController = TextEditingController();
  final _fechaController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  List<Map<String, dynamic>> _items = [];
  List<XFile> _selectedPhotos = [];

  @override
  void initState() {
    super.initState();
    _loadMaintenances();
  }

  @override
  void dispose() {
    _tipoController.dispose();
    _costoController.dispose();
    _piezasController.dispose();
    _fechaController.dispose();
    super.dispose();
  }

  Future<void> _loadMaintenances() async {
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
      final result = await _service.getMaintenances(token, widget.vehicleId);
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );

    if (picked != null) {
      _fechaController.text =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _pickPhotos() async {
    final remaining = 5 - _selectedPhotos.length;
    if (remaining <= 0) {
      _showSnack('Solo puedes subir hasta 5 fotos.');
      return;
    }

    final files = await MultiImagePickHelper.pickImages(
      context,
      maxImages: remaining,
    );

    if (files.isEmpty) return;

    setState(() {
      _selectedPhotos = [..._selectedPhotos, ...files].take(5).toList();
    });
  }

  void _removePhotoAt(int index) {
    setState(() {
      _selectedPhotos.removeAt(index);
    });
  }

  Future<void> _saveMaintenance() async {
    final token = context.read<SessionProvider>().token;

    if (token == null || token.isEmpty) {
      _showSnack('No hay una sesión activa.');
      return;
    }

    final tipo = _tipoController.text.trim();
    final costo = double.tryParse(_costoController.text.trim());
    final piezas = _piezasController.text.trim();
    final fecha = _fechaController.text.trim();

    if (tipo.isEmpty || costo == null || fecha.isEmpty) {
      _showSnack('Completa tipo, costo y fecha.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _service.createMaintenance(
        token: token,
        data: {
          'vehiculo_id': widget.vehicleId,
          'tipo': tipo,
          'costo': costo,
          'piezas': piezas,
          'fecha': fecha,
        },
        photoPaths: _selectedPhotos.map((e) => e.path).toList(),
      );

      _tipoController.clear();
      _costoController.clear();
      _piezasController.clear();
      _fechaController.clear();
      setState(() {
        _selectedPhotos = [];
      });

      await _loadMaintenances();

      if (!mounted) return;
      _showSnack('Mantenimiento registrado.');
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  List<String> _photosOf(Map<String, dynamic> item) {
    final photos = DataUtils.extractStringList(item, [
      'fotos',
      'imagenes',
      'galeria',
      'gallery',
    ]);

    final single = DataUtils.firstImage(item);
    if (photos.isEmpty && single.isNotEmpty) return [single];
    if (single.isNotEmpty && !photos.contains(single)) {
      return [single, ...photos];
    }
    return photos;
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
        appBar: AppBar(title: const Text('Mantenimientos')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            SizedBox(height: 60),
            AccessRequiredView(
              title: 'Mantenimientos',
              message: 'Debes iniciar sesión para gestionar este módulo.',
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mantenimientos')),
      body: RefreshIndicator(
        onRefresh: _loadMaintenances,
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
                  const SizedBox(height: 8),
                  const Text(
                    'Registrar mantenimiento',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _tipoController,
                    decoration: const InputDecoration(
                      labelText: 'Tipo',
                      hintText: 'Ej: Cambio de aceite',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _costoController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Costo'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _piezasController,
                    decoration: const InputDecoration(
                      labelText: 'Piezas (opcional)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _fechaController,
                    readOnly: true,
                    onTap: _pickDate,
                    decoration: const InputDecoration(
                      labelText: 'Fecha',
                      suffixIcon: Icon(Icons.calendar_month_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickPhotos,
                        icon: const Icon(Icons.add_a_photo_rounded),
                        label: Text('Fotos (${_selectedPhotos.length}/5)'),
                      ),
                    ],
                  ),
                  if (_selectedPhotos.isNotEmpty) const SizedBox(height: 12),
                  if (_selectedPhotos.isNotEmpty)
                    Column(
                      children: List.generate(_selectedPhotos.length, (index) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.softCard,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedPhotos[index].name,
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => _removePhotoAt(index),
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveMaintenance,
                    child: Text(
                      _isSaving ? 'Guardando...' : 'Registrar mantenimiento',
                    ),
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
                'No hay mantenimientos registrados.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary),
              )
            else
              ..._items.map((item) {
                final tipo = DataUtils.firstString(item, [
                  'tipo',
                  'nombre',
                ], fallback: 'Mantenimiento');
                final costo = DataUtils.firstString(item, ['costo', 'monto']);
                final fecha = DataUtils.firstString(item, [
                  'fecha',
                  'created_at',
                ]);
                final piezas = DataUtils.firstString(item, ['piezas']);
                final photos = _photosOf(item);

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
                        tipo,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (costo.isNotEmpty)
                        Text(
                          'Costo: ${DataUtils.formatMoney(costo)}',
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
                      if (piezas.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'Piezas: $piezas',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      if (photos.isNotEmpty) const SizedBox(height: 12),
                      if (photos.isNotEmpty)
                        SizedBox(
                          height: 84,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: photos.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 10),
                            itemBuilder: (context, index) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  photos[index],
                                  width: 84,
                                  height: 84,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) {
                                    return Container(
                                      width: 84,
                                      height: 84,
                                      color: AppTheme.softCard,
                                      child: const Icon(
                                        Icons.image_not_supported_rounded,
                                        color: AppTheme.textSecondary,
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
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
