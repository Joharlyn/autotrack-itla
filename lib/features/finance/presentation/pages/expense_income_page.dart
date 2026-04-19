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
      return DataUtils.firstString(map, [
        'nombre',
        'categoria',
        'title',
        'label',
      ], fallback: 'Categoría');
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

      await _service.createExpense(token: token, data: body);

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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildExpenseTab() {
    return ListView(
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
                'Registrar gasto',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
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
                decoration: const InputDecoration(labelText: 'Categoría'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _expenseMontoController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Monto'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _expenseDescripcionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isSavingExpense ? null : _saveExpense,
                child: Text(
                  _isSavingExpense ? 'Guardando...' : 'Registrar gasto',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (_expenses.isEmpty)
          const Text(
            'No hay gastos registrados.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary),
          )
        else
          ..._expenses.map((item) {
            final categoria = DataUtils.firstString(item, [
              'categoria',
              'nombre_categoria',
              'title',
            ], fallback: 'Gasto');
            final descripcion = DataUtils.firstString(item, [
              'descripcion',
              'concepto',
            ], fallback: 'Sin descripción.');
            final monto = DataUtils.firstString(item, ['monto']);
            final fecha = DataUtils.firstString(item, ['fecha', 'created_at']);

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
                    categoria,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    descripcion,
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DataUtils.formatMoney(monto),
                    style: const TextStyle(color: AppTheme.accent),
                  ),
                  if (fecha.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        DataUtils.formatDate(fecha),
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
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
                'Registrar ingreso',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _incomeConceptoController,
                decoration: const InputDecoration(labelText: 'Concepto'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _incomeMontoController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Monto'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isSavingIncome ? null : _saveIncome,
                child: Text(
                  _isSavingIncome ? 'Guardando...' : 'Registrar ingreso',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (_incomes.isEmpty)
          const Text(
            'No hay ingresos registrados.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary),
          )
        else
          ..._incomes.map((item) {
            final concepto = DataUtils.firstString(item, [
              'concepto',
              'descripcion',
              'title',
            ], fallback: 'Ingreso');
            final monto = DataUtils.firstString(item, ['monto']);
            final fecha = DataUtils.firstString(item, ['fecha', 'created_at']);

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
                    concepto,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    DataUtils.formatMoney(monto),
                    style: const TextStyle(color: AppTheme.accent),
                  ),
                  if (fecha.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        DataUtils.formatDate(fecha),
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
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
        title: Text('Finanzas • ${widget.vehicleName}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Gastos'),
            Tab(text: 'Ingresos'),
          ],
        ),
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
          : TabBarView(
              controller: _tabController,
              children: [_buildExpenseTab(), _buildIncomeTab()],
            ),
    );
  }
}
