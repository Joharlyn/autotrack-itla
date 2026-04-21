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
    final photos = DataUtils.extractStringList(
      item,
      ['fotos', 'imagenes', 'galeria', 'gallery'],
    );

    final single = DataUtils.firstImage(item);
    if (photos.isEmpty && single.isNotEmpty) return [single];
    if (single.isNotEmpty && !photos.contains(single)) {
      return [single, ...photos];
    }
    return photos;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
      appBar: AppBar(
        title: const Text('Mantenimientos'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadMaintenances,
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
                      'Registra servicios, cambios y reparaciones realizados al vehículo.',
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
                            title: 'Historial',
                            value: '${_items.length} registros',
                            icon: Icons.build_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TopStat(
                            title: 'Fotos',
                            value: '${_selectedPhotos.length}/5',
                            icon: Icons.photo_library_rounded,
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
                    'Registrar mantenimiento',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Completa los datos del servicio y agrega evidencias fotográficas si las tienes.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _tipoController,
                    decoration: const InputDecoration(
                      labelText: 'Tipo',
                      hintText: 'Ej: Cambio de aceite',
                      prefixIcon: Icon(Icons.handyman_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _costoController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Costo',
                      prefixIcon: Icon(Icons.payments_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _piezasController,
                    decoration: const InputDecoration(
                      labelText: 'Piezas (opcional)',
                      prefixIcon: Icon(Icons.inventory_2_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _fechaController,
                    readOnly: true,
                    onTap: _pickDate,
                    decoration: const InputDecoration(
                      labelText: 'Fecha',
                      prefixIcon: Icon(Icons.calendar_month_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: _pickPhotos,
                    icon: const Icon(Icons.add_a_photo_rounded),
                    label: Text('Agregar fotos (${_selectedPhotos.length}/5)'),
                  ),
                  if (_selectedPhotos.isNotEmpty) const SizedBox(height: 14),
                  if (_selectedPhotos.isNotEmpty)
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: List.generate(_selectedPhotos.length, (index) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.softCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.image_rounded,
                                color: AppTheme.accent,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 140),
                                child: Text(
                                  _selectedPhotos[index].name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () => _removePhotoAt(index),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: AppTheme.danger,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveMaintenance,
                    icon: const Icon(Icons.save_rounded),
                    label: Text(
                      _isSaving
                          ? 'Guardando...'
                          : 'Registrar mantenimiento',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const _SectionHeader(
              title: 'Historial de mantenimiento',
              subtitle: 'Consulta todos los servicios registrados para este vehículo.',
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
                      Icons.build_circle_outlined,
                      size: 50,
                      color: AppTheme.accent,
                    ),
                    SizedBox(height: 14),
                    Text(
                      'No hay mantenimientos registrados.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Registra el primer servicio para comenzar a construir el historial del vehículo.',
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
                  ['tipo', 'nombre'],
                  fallback: 'Mantenimiento',
                );
                final costo = DataUtils.firstString(item, ['costo', 'monto']);
                final fecha = DataUtils.firstString(item, ['fecha', 'created_at']);
                final piezas = DataUtils.firstString(item, ['piezas']);
                final photos = _photosOf(item);

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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.build_rounded,
                              color: AppTheme.accent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              tipo,
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
                          if (costo.isNotEmpty)
                            _DataPill(
                              icon: Icons.payments_rounded,
                              text: DataUtils.formatMoney(costo),
                            ),
                          if (fecha.isNotEmpty)
                            _DataPill(
                              icon: Icons.calendar_month_rounded,
                              text: DataUtils.formatDate(fecha),
                            ),
                        ],
                      ),
                      if (piezas.isNotEmpty) const SizedBox(height: 14),
                      if (piezas.isNotEmpty)
                        Text(
                          'Piezas: $piezas',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      if (photos.isNotEmpty) const SizedBox(height: 16),
                      if (photos.isNotEmpty)
                        SizedBox(
                          height: 90,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: photos.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 10),
                            itemBuilder: (context, index) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  photos[index],
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) {
                                    return Container(
                                      width: 90,
                                      height: 90,
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