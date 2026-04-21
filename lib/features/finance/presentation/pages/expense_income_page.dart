import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/storage/session_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/data_utils.dart';
import '../../../../shared/widgets/access_required_view.dart';
import '../../data/services/finance_service.dart';

class ExpenseIncomePage extends StatefulWidget {
  final int vehicleId;
  final String vehicleName;

  const ExpenseIncomePage({
    super.key,
    required this.vehicleId,
    required this.vehicleName,
  });

  @override
  State<ExpenseIncomePage> createState() => _ExpenseIncomePageState();
}

class _ExpenseIncomePageState extends State<ExpenseIncomePage>
    with SingleTickerProviderStateMixin {
  final _service = FinanceService();

  late TabController _tabController;

  final _expenseMontoController = TextEditingController();
  final _expenseDescripcionController = TextEditingController();

  final _incomeMontoController = TextEditingController();
  final _incomeConceptoController = TextEditingController();

  bool _isLoading = true;
  bool _isSavingExpense = false;
  bool _isSavingIncome = false;
  String? _error;

  List<dynamic> _categories = [];
  dynamic _selectedCategory;

  List<Map<String, dynamic>> _expenses = [];
  List<Map<String, dynamic>> _incomes = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _expenseMontoController.dispose();
    _expenseDescripcionController.dispose();
    _incomeMontoController.dispose();
    _incomeConceptoController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
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
      final results = await Future.wait([
        _service.getExpenseCategories(token),
        _service.getExpenses(token, widget.vehicleId),
        _service.getIncomes(token, widget.vehicleId),
      ]);

      final categories = results[0] as List<dynamic>;
      final expenses = results[1] as List<Map<String, dynamic>>;
      final incomes = results[2] as List<Map<String, dynamic>>;

      setState(() {
        _categories = categories;
        _selectedCategory = categories.isNotEmpty ? categories.first : null;
        _expenses = expenses;
        _incomes = incomes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _categoryLabel(dynamic item) {
    if (item is String) return item;
    if (item is Map) {
      final map = Map<String, dynamic>.from(item);
      return DataUtils.firstString(
        map,
        ['nombre', 'categoria', 'title', 'label'],
        fallback: 'Categoría',
      );
    }
    return item.toString();
  }

  dynamic _categoryId(dynamic item) {
    if (item is Map) {
      final map = Map<String, dynamic>.from(item);
      return map['id'] ?? map['categoria_id'];
    }
    return null;
  }

  Future<void> _saveExpense() async {
    final token = context.read<SessionProvider>().token;
    if (token == null || token.isEmpty) return;

    final monto = double.tryParse(_expenseMontoController.text.trim());
    final descripcion = _expenseDescripcionController.text.trim();

    if (monto == null || _selectedCategory == null) {
      _showSnack('Completa la categoría y el monto.');
      return;
    }

    setState(() => _isSavingExpense = true);

    try {
      final body = <String, dynamic>{
        'vehiculo_id': widget.vehicleId,
        'monto': monto,
        'descripcion': descripcion,
      };

      final categoryId = _categoryId(_selectedCategory);
      final categoryLabel = _categoryLabel(_selectedCategory);

      if (categoryId != null) {
        body['categoria_id'] = categoryId;
      }
      body['categoria'] = categoryLabel;

      await _service.createExpense(
        token: token,
        data: body,
      );

      _expenseMontoController.clear();
      _expenseDescripcionController.clear();

      await _loadAll();

      if (!mounted) return;
      _showSnack('Gasto registrado.');
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isSavingExpense = false);
      }
    }
  }

  Future<void> _saveIncome() async {
    final token = context.read<SessionProvider>().token;
    if (token == null || token.isEmpty) return;

    final monto = double.tryParse(_incomeMontoController.text.trim());
    final concepto = _incomeConceptoController.text.trim();

    if (monto == null || concepto.isEmpty) {
      _showSnack('Completa concepto y monto.');
      return;
    }

    setState(() => _isSavingIncome = true);

    try {
      await _service.createIncome(
        token: token,
        data: {
          'vehiculo_id': widget.vehicleId,
          'monto': monto,
          'concepto': concepto,
        },
      );

      _incomeMontoController.clear();
      _incomeConceptoController.clear();

      await _loadAll();

      if (!mounted) return;
      _showSnack('Ingreso registrado.');
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isSavingIncome = false);
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildExpenseTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      children: [
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
                'Registrar gasto',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Guarda gastos relacionados con el vehículo y clasifícalos correctamente.',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<dynamic>(
                value: _selectedCategory,
                items: _categories
                    .map(
                      (e) => DropdownMenuItem<dynamic>(
                        value: e,
                        child: Text(_categoryLabel(e)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedCategory = value);
                },
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  prefixIcon: Icon(Icons.category_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _expenseMontoController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  prefixIcon: Icon(Icons.payments_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _expenseDescripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  prefixIcon: Icon(Icons.description_rounded),
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _isSavingExpense ? null : _saveExpense,
                icon: const Icon(Icons.save_rounded),
                label: Text(
                  _isSavingExpense ? 'Guardando...' : 'Registrar gasto',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const _SectionHeader(
          title: 'Historial de gastos',
          subtitle: 'Consulta cada gasto registrado para este vehículo.',
        ),
        const SizedBox(height: 16),
        if (_expenses.isEmpty)
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
                  Icons.receipt_long_rounded,
                  size: 50,
                  color: AppTheme.accent,
                ),
                SizedBox(height: 14),
                Text(
                  'No hay gastos registrados.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Registra el primer gasto para comenzar a llevar control financiero.',
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
          ..._expenses.map((item) {
            final categoria = DataUtils.firstString(
              item,
              ['categoria', 'nombre_categoria', 'title'],
              fallback: 'Gasto',
            );
            final descripcion = DataUtils.firstString(
              item,
              ['descripcion', 'concepto'],
              fallback: 'Sin descripción.',
            );
            final monto = DataUtils.firstString(item, ['monto']);
            final fecha = DataUtils.firstString(item, ['fecha', 'created_at']);

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
                          color: AppTheme.accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.receipt_long_rounded,
                          color: AppTheme.accent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          categoria,
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
                  Text(
                    descripcion,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
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
    );
  }

  Widget _buildIncomeTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      children: [
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
                'Registrar ingreso',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Guarda ganancias o ingresos asociados a este vehículo.',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _incomeConceptoController,
                decoration: const InputDecoration(
                  labelText: 'Concepto',
                  prefixIcon: Icon(Icons.attach_money_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _incomeMontoController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  prefixIcon: Icon(Icons.payments_rounded),
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _isSavingIncome ? null : _saveIncome,
                icon: const Icon(Icons.save_rounded),
                label: Text(
                  _isSavingIncome ? 'Guardando...' : 'Registrar ingreso',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const _SectionHeader(
          title: 'Historial de ingresos',
          subtitle: 'Consulta todas las entradas monetarias registradas.',
        ),
        const SizedBox(height: 16),
        if (_incomes.isEmpty)
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
                  Icons.account_balance_wallet_rounded,
                  size: 50,
                  color: AppTheme.accentBlue,
                ),
                SizedBox(height: 14),
                Text(
                  'No hay ingresos registrados.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Registra el primer ingreso para completar el control financiero del vehículo.',
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
          ..._incomes.map((item) {
            final concepto = DataUtils.firstString(
              item,
              ['concepto', 'descripcion', 'title'],
              fallback: 'Ingreso',
            );
            final monto = DataUtils.firstString(item, ['monto']);
            final fecha = DataUtils.firstString(item, ['fecha', 'created_at']);

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
                          color: AppTheme.accentBlue.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: AppTheme.accentBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          concepto,
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
                        icon: Icons.payments_rounded,
                        text: DataUtils.formatMoney(monto),
                        accentColor: AppTheme.accentBlue,
                      ),
                      if (fecha.isNotEmpty)
                        _DataPill(
                          icon: Icons.calendar_month_rounded,
                          text: DataUtils.formatDate(fecha),
                          accentColor: AppTheme.accentBlue,
                        ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.watch<SessionProvider>().isLoggedIn;

    if (!isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gastos e ingresos')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            SizedBox(height: 60),
            AccessRequiredView(
              title: 'Gastos e ingresos',
              message: 'Debes iniciar sesión para gestionar este módulo.',
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gastos e ingresos'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accent),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      child: Container(
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
                                'Gestiona el flujo financiero del vehículo de forma organizada y visual.',
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
                                      title: 'Gastos',
                                      value: '${_expenses.length}',
                                      icon: Icons.receipt_long_rounded,
                                      color: AppTheme.accent,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _TopStat(
                                      title: 'Ingresos',
                                      value: '${_incomes.length}',
                                      icon: Icons.account_balance_wallet_rounded,
                                      color: AppTheme.accentBlue,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TabBar(
                      controller: _tabController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      tabs: const [
                        Tab(text: 'Gastos'),
                        Tab(text: 'Ingresos'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildExpenseTab(),
                          _buildIncomeTab(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _TopStat extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _TopStat({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
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
          Icon(icon, color: color, size: 18),
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
  final Color accentColor;

  const _DataPill({
    required this.icon,
    required this.text,
    this.accentColor = AppTheme.accent,
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
          Icon(icon, size: 15, color: accentColor),
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