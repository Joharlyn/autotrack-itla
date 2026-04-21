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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
      appBar: AppBar(
        title: const Text('Mi perfil'),
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
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: AppTheme.border),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF151C27),
                            Color(0xFF0D1219),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x22000000),
                            blurRadius: 22,
                            offset: Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          children: [
                            Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppTheme.accent.withOpacity(0.7),
                                      width: 2,
                                    ),
                                  ),
                                  child: fotoUrl.isNotEmpty
                                      ? CircleAvatar(
                                          radius: 54,
                                          backgroundImage: NetworkImage(fotoUrl),
                                        )
                                      : const CircleAvatar(
                                          radius: 54,
                                          backgroundColor: AppTheme.softCard,
                                          child: Icon(
                                            Icons.person_rounded,
                                            color: AppTheme.accent,
                                            size: 42,
                                          ),
                                        ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.accent,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppTheme.background,
                                      width: 3,
                                    ),
                                  ),
                                  child: IconButton(
                                    onPressed: _isUploadingPhoto ? null : _changePhoto,
                                    icon: _isUploadingPhoto
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.camera_alt_rounded,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Text(
                              _value(
                                ['nombre', 'name'],
                                session.fullName.isEmpty ? 'Usuario' : session.fullName,
                              ),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.7,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _value(['correo', 'email'], session.correo ?? '-'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: _MiniInfoChip(
                                    label: 'Rol',
                                    value: _value(['rol', 'role']),
                                    icon: Icons.verified_user_rounded,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _MiniInfoChip(
                                    label: 'Grupo',
                                    value: _value(['grupo', 'group']),
                                    icon: Icons.groups_rounded,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _isUploadingPhoto ? null : _changePhoto,
                              icon: const Icon(Icons.photo_camera_back_rounded),
                              label: Text(
                                _isUploadingPhoto
                                    ? 'Subiendo foto...'
                                    : 'Actualizar foto de perfil',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const _SectionTitle(
                      title: 'Información personal',
                      subtitle: 'Datos principales asociados a tu cuenta.',
                    ),
                    const SizedBox(height: 14),
                    _ProfileInfoTile(
                      title: 'ID',
                      value: _value(['id']),
                      icon: Icons.badge_rounded,
                    ),
                    _ProfileInfoTile(
                      title: 'Nombre',
                      value: _value(['nombre']),
                      icon: Icons.person_rounded,
                    ),
                    _ProfileInfoTile(
                      title: 'Apellido',
                      value: _value(['apellido']),
                      icon: Icons.person_outline_rounded,
                    ),
                    _ProfileInfoTile(
                      title: 'Correo',
                      value: _value(['correo']),
                      icon: Icons.email_rounded,
                    ),
                    _ProfileInfoTile(
                      title: 'Rol',
                      value: _value(['rol', 'role']),
                      icon: Icons.verified_user_rounded,
                    ),
                    _ProfileInfoTile(
                      title: 'Grupo',
                      value: _value(['grupo', 'group']),
                      icon: Icons.groups_rounded,
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _loadProfile,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Recargar perfil'),
                    ),
                  ],
                ),
    );
  }
}

class _MiniInfoChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MiniInfoChip({
    required this.label,
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
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.accent, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
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

class _ProfileInfoTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _ProfileInfoTile({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.softCard,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: AppTheme.accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}