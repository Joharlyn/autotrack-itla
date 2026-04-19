import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/storage/session_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/data_utils.dart';
import '../../../../shared/widgets/access_required_view.dart';
import '../../data/services/forum_private_service.dart';

class ForumPrivatePage extends StatefulWidget {
  final int vehicleId;
  final String vehicleName;

  const ForumPrivatePage({
    super.key,
    required this.vehicleId,
    required this.vehicleName,
  });

  @override
  State<ForumPrivatePage> createState() => _ForumPrivatePageState();
}

class _ForumPrivatePageState extends State<ForumPrivatePage>
    with SingleTickerProviderStateMixin {
  final _service = ForumPrivateService();
  late TabController _tabController;

  bool _isLoading = true;
  bool _isCreating = false;
  String? _error;

  List<Map<String, dynamic>> _topics = [];
  List<Map<String, dynamic>> _myTopics = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
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
        _service.getTopics(token),
        _service.getMyTopics(token),
      ]);

      setState(() {
        _topics = results[0];
        _myTopics = results[1];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _createTopic() async {
    final token = context.read<SessionProvider>().token;
    if (token == null || token.isEmpty) return;

    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.card,
          title: const Text(
            'Crear tema',
            style: TextStyle(color: AppTheme.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Título'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Descripción'),
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
              child: const Text('Crear'),
            ),
          ],
        );
      },
    );

    if (result != true) return;

    final title = titleController.text.trim();
    final description = descriptionController.text.trim();

    if (title.isEmpty || description.isEmpty) {
      _showSnack('Completa título y descripción.');
      return;
    }

    setState(() => _isCreating = true);

    try {
      await _service.createTopic(
        token: token,
        data: {
          'vehiculo_id': widget.vehicleId,
          'titulo': title,
          'descripcion': description,
        },
      );

      await _loadAll();

      if (!mounted) return;
      _showSnack('Tema creado.');
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  void _openDetail(int id, String title) {
    Navigator.pushNamed(
      context,
      AppRoutes.forumPrivateDetail,
      arguments: {'id': id, 'title': title},
    ).then((_) => _loadAll());
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildList(List<Map<String, dynamic>> items, String emptyText) {
    if (items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 80),
          Center(
            child: Text(
              emptyText,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final item = items[index];
        final id = DataUtils.firstInt(item, ['id', 'tema_id']);
        final title = DataUtils.firstString(item, [
          'titulo',
          'title',
          'nombre',
        ], fallback: 'Tema');
        final description = DataUtils.firstString(item, [
          'descripcion',
          'contenido',
          'mensaje',
        ], fallback: 'Sin descripción.');
        final author = DataUtils.firstString(item, [
          'autor',
          'usuario',
          'nombre_usuario',
          'creado_por',
        ], fallback: 'Usuario');

        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: id == 0 ? null : () => _openDetail(id, title),
          child: Ink(
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
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  author,
                  style: const TextStyle(
                    color: AppTheme.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.watch<SessionProvider>().isLoggedIn;

    if (!isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Foro')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            SizedBox(height: 60),
            AccessRequiredView(
              title: 'Foro autenticado',
              message: 'Debes iniciar sesión para participar en el foro.',
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Foro • ${widget.vehicleName}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Todos'),
            Tab(text: 'Mis temas'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.accent,
        onPressed: _isCreating ? null : _createTopic,
        icon: const Icon(Icons.add_comment_rounded, color: Colors.white),
        label: Text(
          _isCreating ? 'Creando...' : 'Nuevo tema',
          style: const TextStyle(color: Colors.white),
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
              children: [
                _buildList(_topics, 'No hay temas disponibles.'),
                _buildList(_myTopics, 'Todavía no has creado temas.'),
              ],
            ),
    );
  }
}
