import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/storage/session_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/data_utils.dart';
import '../../../../shared/utils/image_pick_helper.dart';
import '../../data/services/vehicles_service.dart';

class VehicleFormPage extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const VehicleFormPage({super.key, this.initialData});

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
    _ruedasController.text = DataUtils.firstString(data, [
      'cantidadRuedas',
      'cantidad_ruedas',
      'ruedas',
    ]);
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final initialImage = DataUtils.firstImage(widget.initialData ?? {});

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar vehículo' : 'Nuevo vehículo'),
      ),
      body: ListView(
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
                const Text(
                  'Datos del vehículo',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _placaController,
                  decoration: const InputDecoration(labelText: 'Placa'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _chasisController,
                  decoration: const InputDecoration(labelText: 'Chasis'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _marcaController,
                  decoration: const InputDecoration(labelText: 'Marca'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _modeloController,
                  decoration: const InputDecoration(labelText: 'Modelo'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _anioController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Año'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _ruedasController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Cantidad de ruedas',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
                const Text(
                  'Foto',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                if (!_isEditing) ...[
                  if (_photoPath != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.softCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Text(
                        'Imagen seleccionada:\n$_photoPath',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    )
                  else
                    const Text(
                      'Puedes crear el vehículo con foto opcional.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _pickPhoto,
                    icon: const Icon(Icons.add_a_photo_rounded),
                    label: const Text('Elegir foto'),
                  ),
                ] else ...[
                  if (initialImage.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.softCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Text(
                        'La foto actual se cambia desde el detalle del vehículo.',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    )
                  else
                    const Text(
                      'La foto se cambia desde el detalle del vehículo.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
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
