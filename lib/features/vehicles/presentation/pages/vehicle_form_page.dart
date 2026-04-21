import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/storage/session_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/data_utils.dart';
import '../../../../shared/utils/image_pick_helper.dart';
import '../../data/services/vehicles_service.dart';

class VehicleFormPage extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const VehicleFormPage({
    super.key,
    this.initialData,
  });

  @override
  State<VehicleFormPage> createState() => _VehicleFormPageState();
}

class _VehicleFormPageState extends State<VehicleFormPage> {
  final _service = VehiclesService();

  final _placaController = TextEditingController();
  final _chasisController = TextEditingController();
  final _marcaController = TextEditingController();
  final _modeloController = TextEditingController();
  final _anioController = TextEditingController();
  final _ruedasController = TextEditingController();

  bool _isSaving = false;
  String? _photoPath;

  bool get _isEditing => widget.initialData != null;

  int get _vehicleId =>
      DataUtils.firstInt(widget.initialData ?? {}, ['id', 'vehiculo_id']);

  @override
  void initState() {
    super.initState();

    final data = widget.initialData ?? {};
    _placaController.text = DataUtils.firstString(data, ['placa']);
    _chasisController.text = DataUtils.firstString(data, ['chasis']);
    _marcaController.text = DataUtils.firstString(data, ['marca']);
    _modeloController.text = DataUtils.firstString(data, ['modelo', 'nombre']);
    _anioController.text = DataUtils.firstString(data, ['anio', 'year']);
    _ruedasController.text = DataUtils.firstString(
      data,
      ['cantidadRuedas', 'cantidad_ruedas', 'ruedas'],
    );
  }

  @override
  void dispose() {
    _placaController.dispose();
    _chasisController.dispose();
    _marcaController.dispose();
    _modeloController.dispose();
    _anioController.dispose();
    _ruedasController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final file = await ImagePickHelper.pickImage(context);
    if (file == null) return;

    setState(() {
      _photoPath = file.path;
    });
  }

  Future<void> _save() async {
    final session = context.read<SessionProvider>();
    final token = session.token;

    if (token == null || token.isEmpty) {
      _showSnack('No hay una sesión activa.');
      return;
    }

    final placa = _placaController.text.trim();
    final chasis = _chasisController.text.trim();
    final marca = _marcaController.text.trim();
    final modelo = _modeloController.text.trim();
    final anio = int.tryParse(_anioController.text.trim());
    final ruedas = int.tryParse(_ruedasController.text.trim());

    if (placa.isEmpty ||
        chasis.isEmpty ||
        marca.isEmpty ||
        modelo.isEmpty ||
        anio == null ||
        ruedas == null) {
      _showSnack('Completa todos los campos obligatorios correctamente.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (_isEditing) {
        await _service.editVehicle(
          token: token,
          data: {
            'id': _vehicleId,
            'placa': placa,
            'chasis': chasis,
            'marca': marca,
            'modelo': modelo,
            'anio': anio,
            'cantidadRuedas': ruedas,
          },
        );
      } else {
        await _service.createVehicle(
          token: token,
          data: {
            'placa': placa,
            'chasis': chasis,
            'marca': marca,
            'modelo': modelo,
            'anio': anio,
            'cantidadRuedas': ruedas,
          },
          photoPath: _photoPath,
        );
      }

      if (!mounted) return;
      _showSnack(_isEditing ? 'Vehículo actualizado.' : 'Vehículo creado.');
      Navigator.pop(context, true);
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

  @override
  Widget build(BuildContext context) {
    final initialImage = DataUtils.firstImage(widget.initialData ?? {});

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar vehículo' : 'Nuevo vehículo'),
      ),
      body: ListView(
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
                    _isEditing ? 'Actualiza tu vehículo' : 'Registra un nuevo vehículo',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isEditing
                        ? 'Modifica la información principal y mantén actualizado tu garage.'
                        : 'Completa los datos principales para agregar un nuevo vehículo a la app.',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      height: 1.45,
                    ),
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
                  'Datos del vehículo',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _placaController,
                  decoration: const InputDecoration(
                    labelText: 'Placa',
                    prefixIcon: Icon(Icons.pin_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _chasisController,
                  decoration: const InputDecoration(
                    labelText: 'Chasis',
                    prefixIcon: Icon(Icons.qr_code_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _marcaController,
                  decoration: const InputDecoration(
                    labelText: 'Marca',
                    prefixIcon: Icon(Icons.sell_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _modeloController,
                  decoration: const InputDecoration(
                    labelText: 'Modelo',
                    prefixIcon: Icon(Icons.directions_car_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _anioController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Año',
                    prefixIcon: Icon(Icons.calendar_month_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _ruedasController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Cantidad de ruedas',
                    prefixIcon: Icon(Icons.tire_repair_rounded),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
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
                  'Foto del vehículo',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                if (!_isEditing) ...[
                  if (_photoPath != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.softCard,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Text(
                        'Imagen seleccionada:\n$_photoPath',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    )
                  else
                    const Text(
                      'Puedes registrar el vehículo con una foto opcional para darle una mejor presentación visual.',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: _pickPhoto,
                    icon: const Icon(Icons.add_a_photo_rounded),
                    label: const Text('Seleccionar foto'),
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.softCard,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          initialImage.isNotEmpty
                              ? 'La foto actual se cambia desde el detalle del vehículo.'
                              : 'Puedes cambiar la foto desde la pantalla de detalle del vehículo.',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: const Icon(Icons.save_rounded),
            label: Text(
              _isSaving
                  ? 'Guardando...'
                  : _isEditing
                      ? 'Guardar cambios'
                      : 'Crear vehículo',
            ),
          ),
        ],
      ),
    );
  }
}