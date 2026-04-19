import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/storage/session_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/image_pick_helper.dart';
import '../../data/services/profile_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _profileService = ProfileService();

  bool _isLoading = true;
  bool _isUploadingPhoto = false;
  String? _error;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final session = context.read<SessionProvider>();
    final token = session.token;

    if (token == null || token.isEmpty) {
      setState(() {
        _error = 'No hay una sesión activa.';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _profileService.getProfile(token);
      await session.saveProfileData(data);

      if (!mounted) return;

      setState(() {
        _profile = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _changePhoto() async {
    final session = context.read<SessionProvider>();
    final token = session.token;

    if (token == null || token.isEmpty) {
      _showSnack('No hay una sesión activa.');
      return;
    }

    final image = await ImagePickHelper.pickImage(context);
    if (image == null) return;

    setState(() => _isUploadingPhoto = true);

    try {
      final data = await _profileService.uploadProfilePhoto(
        token: token,
        photoPath: image.path,
      );

      if (data.isNotEmpty) {
        await session.saveProfileData(data);
      }

      await _loadProfile();

      if (!mounted) return;
      _showSnack('Foto de perfil actualizada.');
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _value(List<String> keys, [String fallback = '-']) {
    final map = _profile ?? {};
    for (final key in keys) {
      final value = map[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final fotoUrl = _value(['fotoUrl', 'foto', 'image'], '');

    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.accent),
              )
            : _error != null
            ? Center(
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
              )
            : ListView(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      children: [
                        if (fotoUrl.isNotEmpty)
                          CircleAvatar(
                            radius: 56,
                            backgroundImage: NetworkImage(fotoUrl),
                          )
                        else
                          const CircleAvatar(
                            radius: 56,
                            backgroundColor: AppTheme.softCard,
                            child: Icon(
                              Icons.person,
                              color: AppTheme.accent,
                              size: 42,
                            ),
                          ),
                        const SizedBox(height: 16),
                        Text(
                          _value(
                            ['nombre', 'name'],
                            session.fullName.isEmpty
                                ? 'Usuario'
                                : session.fullName,
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _value(['correo', 'email'], session.correo ?? '-'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton.icon(
                          onPressed: _isUploadingPhoto ? null : _changePhoto,
                          icon: const Icon(Icons.camera_alt_rounded),
                          label: Text(
                            _isUploadingPhoto
                                ? 'Subiendo foto...'
                                : 'Cambiar foto',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ProfileInfoTile(title: 'ID', value: _value(['id'])),
                  _ProfileInfoTile(title: 'Nombre', value: _value(['nombre'])),
                  _ProfileInfoTile(
                    title: 'Apellido',
                    value: _value(['apellido']),
                  ),
                  _ProfileInfoTile(title: 'Correo', value: _value(['correo'])),
                  _ProfileInfoTile(
                    title: 'Rol',
                    value: _value(['rol', 'role']),
                  ),
                  _ProfileInfoTile(
                    title: 'Grupo',
                    value: _value(['grupo', 'group']),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _loadProfile,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Recargar perfil'),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ProfileInfoTile extends StatelessWidget {
  final String title;
  final String value;

  const _ProfileInfoTile({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.softCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
