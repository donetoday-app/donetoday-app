import 'dart:convert';
import 'dart:typed_data';
import 'package:done_today/theme/app_theme.dart';
import 'package:done_today/theme/ui_constants.dart';
import 'package:done_today/ui/widgets/settings/data_export_picker.dart';
import 'package:done_today/providers/auth/auth_notifier.dart';
import 'package:done_today/state/auth/auth_state.dart';
import 'package:done_today/ui/widgets/app_dialog.dart';
import 'package:done_today/ui/widgets/section_header.dart';
import 'package:done_today/utils/responsive_helper.dart';
import 'package:done_today/ui/widgets/custom_card.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:done_today/providers/logs/logs_notifier.dart';
import 'package:done_today/providers/challenges/challenges_notifier.dart';
import 'package:done_today/state/logs/logs_state.dart';
import 'package:done_today/state/challenges/challenges_state.dart';
import 'package:done_today/services/update_service.dart';
import 'package:done_today/ui/widgets/update_dialogs.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';

class UserDetailsScreen extends ConsumerWidget {
  const UserDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: ResponsiveConstraints(
          maxWidth: ResponsiveHelper.isDesktop(context)
              ? ResponsiveHelper.maxFullWidth
              : ResponsiveHelper.maxContentWidth,
          child: authState is AuthLoggedIn
              ? _UserDetailsContent(userDetails: authState.userDetails)
              : const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}

class _UserDetailsContent extends ConsumerStatefulWidget {
  final Map<String, dynamic> userDetails;

  const _UserDetailsContent({required this.userDetails});

  @override
  ConsumerState<_UserDetailsContent> createState() =>
      _UserDetailsContentState();
}

class _UserDetailsContentState extends ConsumerState<_UserDetailsContent> {
  bool _isSaving = false;
  Map<String, dynamic>? _userAccess;
  bool _isFetchingAccess = false;

  @override
  void initState() {
    super.initState();
    _fetchAccess();
  }

  Future<void> _fetchAccess() async {
    final authState = ref.read(authNotifierProvider);

    if (mounted) setState(() => _isFetchingAccess = true);
    try {
      if (mounted) {
        setState(() {
          _userAccess = authState is AuthLoggedIn
              ? authState.userDetails['access'] as Map<String, dynamic>?
              : null;
        });
      }
    } catch (e) {
      // safe fallback
    } finally {
      if (mounted) {
        setState(() => _isFetchingAccess = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authNotifierProvider);
    final logsState = ref.watch(logsNotifierProvider);
    final challengesState = ref.watch(challengesNotifierProvider);

    if (authState is! AuthLoggedIn) return const SizedBox.shrink();

    final name = widget.userDetails['name'] as String? ?? 'User';
    final email = widget.userDetails['email'] as String? ?? '';

    // Calculate stats
    int totalLogs = 0;
    int activeChallenges = 0;
    int currentStreak = 0;

    if (logsState is LogsLoaded) {
      totalLogs = logsState.logs.length;
      currentStreak = logsState.stats?.streak ?? 0;
    }

    if (challengesState is ChallengesLoaded) {
      activeChallenges = challengesState.challenges
          .where((c) => !c.isDeleted)
          .length;
    }

    return ListView(
      padding: AppSpacing.screenPadding,
      physics: const BouncingScrollPhysics(),
      children: [
        // Unified Master Identity Card
        Stack(
          children: [
            CustomCard(
              padding: const EdgeInsets.all(AppSpacing.sm),
              borderRadius: AppRadius.md,
              child: Column(
                children: [
                  Row(
                    children: [
                      _ProfileAvatar(
                        userDetails: widget.userDetails,
                        isSaving: _isSaving,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              email,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.7,
                                ),
                                fontSize: 12,
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(width: 36),
                    ],
                  ),                  
                  const SizedBox(height: AppSpacing.sm),
                  Divider(
                    height: 1,
                    color: theme.colorScheme.onSurface.withOpacity(0.08),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      _StatItem(label: "LOGS", value: totalLogs.toString()),
                      _StatItem(label: "STREAK", value: "$currentStreak"),
                      _StatItem(
                        label: "CHALLENGES",
                        value: activeChallenges.toString(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: Icon(
                  Icons.edit_rounded,
                  size: 22,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                onPressed: _showEditProfileDialog,
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.onSurface.withOpacity(
                    0.04,
                  ),
                  padding: const EdgeInsets.all(6),
                  minimumSize: const Size(32, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        const SectionHeader(title: "PREFERENCES & SYSTEM"),
        const SizedBox(height: AppSpacing.sm),
        CustomCard(
          padding: EdgeInsets.zero,
          borderRadius: AppRadius.md,
          child: Column(
            children: [
              _AccountTile(
                icon: Icons.settings_rounded,
                title: "App Settings",
                subtitle: "Theme, back up & backup data",
                onTap: () => context.push('/settings'),
              ),
              if (!kIsWeb) ...[
                Divider(
                  height: 1,
                  color: theme.colorScheme.onSurface.withOpacity(0.05),
                  indent: 45,
                ),
                const _UpdateCheckTile(),
              ],
              Divider(
                height: 1,
                color: theme.colorScheme.onSurface.withOpacity(0.05),
                indent: 45,
              ),
              _AccountTile(
                icon: Icons.logout_rounded,
                title: "Log Out",
                subtitle: "Securely Log Out",
                isDestructive: true,
                onTap: _handleSignOut,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  void _handleSignOut() {
    final theme = Theme.of(context);

    AppDialog.show(
      context: context,
      title: "Confirm Log Out",
      confirmLabel: "Log Out",
      isDestructive: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Are you sure you want to sign out? Signing out will permanently delete your local logs and challenges from this device. Please back up your data first to keep it safe!",
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () async {
              showDialog(
                context: context,
                builder: (context) => const DataExportPicker(),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 12,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.settings_backup_restore_rounded,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Export Local Backup File First",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      onConfirm: () {
        Navigator.of(context, rootNavigator: true).pop();
        ref.read(authNotifierProvider.notifier).logout();
      },
    );
  }

  Future<void> _showEditProfileDialog() async {
    await showDialog(
      context: context,
      builder: (context) => _EditProfileDialog(
        userDetails: widget.userDetails,
        onSave: (newName, newAvatar, avatarBytes) async {
          await ref
              .read(authNotifierProvider.notifier)
              .updateProfile(
                name: newName,
                avatarUrl: newAvatar,
                avatarBytes: avatarBytes,
              );
        },
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontWeight: FontWeight.w600,
              fontSize: 20,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withOpacity(0.65),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;
  final bool isDestructive;

  const _AccountTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = AppTheme.of(context);
    return Theme(
      data: theme.copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDestructive
                  ? customColors.error.withOpacity(0.1)
                  : theme.colorScheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 18,
              color: isDestructive
                  ? customColors.error
                  : theme.colorScheme.primary,
            ),
          ),
          title: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: isDestructive ? customColors.error : null,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.65),
            ),
          ),
          trailing:
              trailing ??
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: theme.colorScheme.onSurface.withOpacity(0.55),
              ),
          onTap: onTap,
        ),
      ),
    );
  }
}

// Keep original EditProfile and Avatar components but update their styling slightly
class _EditProfileDialog extends StatefulWidget {
  final Map<String, dynamic> userDetails;
  final Future<void> Function(
    String name,
    String? avatarUrl,
    Uint8List? avatarBytes,
  )
  onSave;

  const _EditProfileDialog({required this.userDetails, required this.onSave});

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late TextEditingController _nameController;
  PlatformFile? _selectedImage;
  bool _isSaving = false;
  String? _currentAvatar;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.userDetails['name'] as String? ?? '',
    );
    _currentAvatar = widget.userDetails['avatar'] as String?;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarData = widget.userDetails['avatar_data'] as String?;

    return AppDialogFrame(
      title: "Edit Profile",
      confirmLabel: _isSaving ? "Saving..." : "Save Changes",
      onConfirm: _isSaving ? () {} : _handleSave,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    backgroundImage: _selectedImage != null
                        ? MemoryImage(_selectedImage!.bytes!)
                        : (avatarData != null
                                  ? MemoryImage(base64Decode(avatarData))
                                  : (_currentAvatar != null
                                        ? NetworkImage(_currentAvatar!)
                                        : null))
                              as ImageProvider?,
                    child:
                        _selectedImage == null &&
                            _currentAvatar == null &&
                            avatarData == null
                        ? Icon(
                            Icons.camera_alt_rounded,
                            size: 32,
                            color: theme.colorScheme.onSurfaceVariant,
                          )
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _nameController,
            style: const TextStyle(fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: 'Display Name',
              hintText: 'What should we call you?',
              prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerLow,
            ),
          ),
          if (_isSaving) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
          ],
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null && result.files.first.bytes != null) {
      setState(() => _selectedImage = result.files.first);
    }
  }

  Future<void> _handleSave() async {
    final newName = _nameController.text.trim();
    if (newName == (widget.userDetails['name'] ?? '') &&
        _selectedImage == null) {
      if (mounted) Navigator.pop(context);
      return;
    }

    setState(() => _isSaving = true);
    try {
      String? finalAvatarUrl = _currentAvatar;
      Uint8List? finalAvatarBytes;

      if (_selectedImage != null) {
        finalAvatarBytes = _selectedImage!.bytes!;
      }

      await widget.onSave(newName, finalAvatarUrl, finalAvatarBytes);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      // Error handled
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _ProfileAvatar extends StatelessWidget {
  final Map<String, dynamic> userDetails;
  final bool isSaving;

  const _ProfileAvatar({required this.userDetails, required this.isSaving});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarData = userDetails['avatar_data'] as String?;
    final avatarUrl = userDetails['avatar'] as String?;

    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: theme.scaffoldBackgroundColor, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: CircleAvatar(
            backgroundColor: theme.colorScheme.surfaceContainerHigh,
            backgroundImage: avatarData != null
                ? MemoryImage(base64Decode(avatarData))
                : (avatarUrl != null ? NetworkImage(avatarUrl) : null)
                      as ImageProvider?,
            child: avatarData == null && avatarUrl == null
                ? Icon(
                    Icons.person_rounded,
                    size: 50,
                    color: theme.colorScheme.onSurfaceVariant,
                  )
                : null,
          ),
        ),
        if (isSaving)
          const Positioned.fill(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    );
  }
}

class _UpdateCheckTile extends StatefulWidget {
  const _UpdateCheckTile();

  @override
  State<_UpdateCheckTile> createState() => _UpdateCheckTileState();
}

class _UpdateCheckTileState extends State<_UpdateCheckTile> {
  bool _isChecking = false;
  String _version = "";

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = "v${info.version}";
      });
    }
  }

  Future<void> _checkForUpdates() async {
    if (_isChecking) return;
    
    setState(() => _isChecking = true);
    
    final updateInfo = await UpdateService.checkForUpdates();
    
    if (mounted) {
      setState(() => _isChecking = false);
      
      if (updateInfo != null) {
        if (updateInfo.type == UpdateType.major) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => MajorUpdateDialog(updateInfo: updateInfo),
          );
        } else if (updateInfo.type == UpdateType.minor) {
          showDialog(
            context: context,
            builder: (context) => MinorUpdateDialog(updateInfo: updateInfo),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You are on the latest version!")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AccountTile(
      icon: Icons.system_update_alt_rounded,
      title: "Check for Updates",
      subtitle: _isChecking ? "Checking..." : (_version.isEmpty ? "Loading..." : "Current Version: $_version"),
      trailing: _isChecking 
          ? const SizedBox(
              width: 20, 
              height: 20, 
              child: CircularProgressIndicator(strokeWidth: 2)
            )
          : null,
      onTap: _isChecking ? () {} : _checkForUpdates,
    );
  }
}
