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
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                    ),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _normalizeEstado(String estado) {
    const valid = ['buena', 'regular', 'mala', 'reemplazada'];
    final value = estado.toLowerCase().trim();
    return valid.contains(value) ? value : 'regular';
  }

  Color _statusColor(String estado) {
    switch (_normalizeEstado(estado)) {
      case 'buena':
        return AppTheme.success;
      case 'mala':
        return AppTheme.danger;
      case 'reemplazada':
        return AppTheme.accentBlue;
      default:
        return AppTheme.warning;
    }
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
      appBar: AppBar(
        title: const Text('Estado de gomas'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadTires,
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
                      'Consulta y actualiza el estado de cada goma del vehículo.',
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
                            title: 'Gomas',
                            value: '${_items.length}',
                            icon: Icons.tire_repair_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TopStat(
                            title: 'Acciones',
                            value: 'Estado / Pinchazo',
                            icon: Icons.build_circle_rounded,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            const _SectionHeader(
              title: 'Estado actual',
              subtitle: 'Actualiza el estado o registra incidencias en cualquier goma.',
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
                      Icons.tire_repair_rounded,
                      size: 50,
                      color: AppTheme.accent,
                    ),
                    SizedBox(height: 14),
                    Text(
                      'No hay gomas disponibles.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Cuando el backend devuelva la información, aquí podrás controlar el estado de cada goma.',
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
                final gomaId = DataUtils.firstInt(item, ['id', 'goma_id']);
                final posicion = DataUtils.firstString(
                  item,
                  ['posicion', 'position'],
                  fallback: 'Sin posición',
                );
                final eje = DataUtils.firstString(
                  item,
                  ['eje', 'axle'],
                  fallback: '-',
                );
                final estado = _normalizeEstado(
                  DataUtils.firstString(
                    item,
                    ['estado', 'status'],
                    fallback: 'regular',
                  ),
                );
                final color = _statusColor(estado);

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
                              Icons.tire_repair_rounded,
                              color: color,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              posicion,
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
                            icon: Icons.sync_alt_rounded,
                            text: 'Eje: $eje',
                          ),
                          _DataPill(
                            icon: Icons.verified_rounded,
                            text: estado.toUpperCase(),
                            textColor: color,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: estado,
                        items: const [
                          DropdownMenuItem(value: 'buena', child: Text('Buena')),
                          DropdownMenuItem(value: 'regular', child: Text('Regular')),
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
                        decoration: const InputDecoration(
                          labelText: 'Estado',
                          prefixIcon: Icon(Icons.tune_rounded),
                        ),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        onPressed:
                            gomaId == 0 ? null : () => _registerPuncture(gomaId),
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
  final Color? textColor;

  const _DataPill({
    required this.icon,
    required this.text,
    this.textColor,
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
            style: TextStyle(
              color: textColor ?? AppTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}