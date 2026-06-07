import 'package:done_today/providers/challenges/challenges_notifier.dart';
import 'package:done_today/theme/ui_constants.dart';
import 'package:done_today/providers/logs/logs_notifier.dart';
import 'package:done_today/providers/settings/theme_notifier.dart';
import 'package:done_today/ui/widgets/color_slider_tile.dart';
import 'package:done_today/ui/widgets/settings/data_export_picker.dart';
import 'package:done_today/ui/widgets/settings/data_import_picker.dart';
import 'package:done_today/ui/widgets/section_header.dart';
import 'package:done_today/utils/responsive_helper.dart';
import 'package:done_today/ui/widgets/custom_card.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:done_today/ui/widgets/unified_header.dart';
import 'package:done_today/services/update_service.dart';
import 'package:done_today/ui/widgets/update_dialogs.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeProvider = ref.watch(themeNotifierProvider.notifier);
    final themeState = ref.watch(themeNotifierProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: ResponsiveConstraints(
          maxWidth: ResponsiveHelper.isDesktop(context)
              ? ResponsiveHelper.maxFullWidth
              : ResponsiveHelper.maxContentWidth,
          child: Column(
            children: [
              UnifiedHeader(title: "SETTINGS", onBack: () => context.pop()),
              Expanded(
                child: ListView(
                  padding: AppSpacing.screenPadding,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    const SectionHeader(title: "APPEARANCE"),
                    const SizedBox(height: AppSpacing.sm),

                    // Visual Theme Selection
                    Row(
                      children: [
                        _ThemePreviewCard(
                          label: "System",
                          icon: Icons.brightness_auto_rounded,
                          isSelected: themeState.themeMode == ThemeMode.system,
                          onTap: () =>
                              themeProvider.setThemeMode(ThemeMode.system),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _ThemePreviewCard(
                          label: "Light",
                          icon: Icons.light_mode_rounded,
                          isSelected: themeState.themeMode == ThemeMode.light,
                          onTap: () =>
                              themeProvider.setThemeMode(ThemeMode.light),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _ThemePreviewCard(
                          label: "Dark",
                          icon: Icons.dark_mode_rounded,
                          isSelected: themeState.themeMode == ThemeMode.dark,
                          onTap: () =>
                              themeProvider.setThemeMode(ThemeMode.dark),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    CustomCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      borderRadius: AppRadius.md,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.palette_rounded,
                                size: 18,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Appearance Accent",
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          ColorSliderTile(
                            title: "",
                            color: themeState.seedColor,
                            onChanged: (color) =>
                                themeProvider.changeSeedColor(color),
                          ),
                          if (themeState.themeMode != ThemeMode.light) ...[
                            const SizedBox(height: AppSpacing.sm),
                            const Divider(),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            "AMOLED BLACK",
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        "Battery Saving",
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme.colorScheme.onSurface
                                                  .withOpacity(0.7),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Transform.scale(
                                  scale: 0.8,
                                  child: Switch.adaptive(
                                    value: themeState.useBlackMode,
                                    onChanged: (val) {
                                      themeProvider.setUseBlackMode(val);
                                    },
                                    activeColor: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // Floating Navbar toggle (only visible on mobile)
                    if (ResponsiveHelper.isMobile(context))
                      CustomCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        borderRadius: AppRadius.md,
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.dock_rounded,
                                        size: 18,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Floating Navbar",
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color:
                                                  theme.colorScheme.onSurface,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Use detached pill dock instead of full bar",
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.65),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Transform.scale(
                              scale: 0.8,
                              child: Switch.adaptive(
                                value: themeState.useFloatingNavBar,
                                onChanged: (val) {
                                  themeProvider.setUseFloatingNavBar(val);
                                },
                                activeColor: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: AppSpacing.sm),
                    const SectionHeader(title: "TIME PREFERENCES"),
                    const SizedBox(height: AppSpacing.sm),

                    CustomCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      borderRadius: AppRadius.md,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "24-Hour Time Format",
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Use 24-hour time standard instead of 12-hour",
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.65),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Transform.scale(
                            scale: 0.8,
                            child: Switch.adaptive(
                              value: themeState.use24HourFormat,
                              onChanged: (val) {
                                themeProvider.setUse24HourFormat(val);
                              },
                              activeColor: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sm),
                    const SectionHeader(title: "DATA MANAGEMENT"),
                    const SizedBox(height: AppSpacing.sm),

                    CustomCard(
                      padding: EdgeInsets.zero,
                      borderRadius: AppRadius.md,
                      child: Column(
                        children: [
                          _SettingsTile(
                            icon: Icons.cloud_upload_rounded,
                            title: "Export Archive",
                            subtitle: "Create a secure backup",
                            onTap: () => _handleExport(context),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            child: Divider(height: 1),
                          ),
                          _SettingsTile(
                            icon: Icons.cloud_download_rounded,
                            title: "Import Archive",
                            subtitle: "Restore from a previous backup",
                            onTap: () => _handleImport(ref),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Center(
                      child: Column(
                        children: [
                          const _VersionCheckWidget(),
                          const SizedBox(height: 8),
                          Text(
                            "DONE TODAY",
                            style: theme.textTheme.labelSmall?.copyWith(
                              letterSpacing: 4,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleExport(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const DataExportPicker(),
    );
  }

  Future<void> _handleImport(WidgetRef ref) async {
    final success = await showDialog<bool>(
      context: ref.context,
      builder: (context) => const DataImportPicker(),
    );

    if (success == true) {
      await ref.read(logsNotifierProvider.notifier).fetchInitialData();
      await ref.read(challengesNotifierProvider.notifier).fetchInitialData();
    }
  }
}

class _ThemePreviewCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemePreviewCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withOpacity(0.12)
                : Color.alphaBlend(
                    theme.colorScheme.primary.withOpacity(0.015),
                    theme.colorScheme.surfaceContainer,
                  ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary.withOpacity(0.8)
                  : theme.colorScheme.onSurface.withOpacity(0.08),
              width: isSelected ? 1.8 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.55),
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  letterSpacing: 0.5,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.75),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: theme.colorScheme.primary),
          ),
          title: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.65),
            ),
          ),
          trailing: Icon(
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

class _VersionCheckWidget extends StatefulWidget {
  const _VersionCheckWidget();

  @override
  State<_VersionCheckWidget> createState() => _VersionCheckWidgetState();
}

class _VersionCheckWidgetState extends State<_VersionCheckWidget> {
  String _version = "";
  bool _isChecking = false;

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
    if (kIsWeb || _isChecking) return;

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
    final theme = Theme.of(context);

    return InkWell(
      onTap: kIsWeb ? null : _checkForUpdates,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isChecking) ...[
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              _version.isEmpty ? "v..." : _version,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            if (!kIsWeb) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.system_update_alt_rounded,
                size: 14,
                color: theme.colorScheme.primary.withOpacity(0.8),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
