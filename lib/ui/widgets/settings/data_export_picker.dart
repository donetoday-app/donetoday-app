import 'package:done_today/services/backup_service.dart';
import 'package:done_today/theme/app_theme.dart';
import 'package:done_today/theme/ui_constants.dart';
import 'package:done_today/ui/widgets/custom_card.dart';
import 'package:done_today/ui/widgets/custom_popup.dart';
import 'package:done_today/utils/encryption_helper.dart';
import 'package:done_today/utils/file_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class DataExportPicker extends StatefulWidget {
  const DataExportPicker({super.key});

  @override
  State<DataExportPicker> createState() => _DataExportPickerState();
}

class _DataExportPickerState extends State<DataExportPicker> {
  final TextEditingController _passwordController = TextEditingController();
  late String _recoveryPhrase;
  bool _showPassword = false;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _recoveryPhrase = EncryptionHelper.generateRecoveryCode();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomPopup(
      footer: _buildActions(context, theme),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(theme),
            const SizedBox(height: 32),

            _buildInfoCard(theme),
            const SizedBox(height: 24),

            _buildSecurityHeader(theme),
            const SizedBox(height: 16),
            _buildPasswordField(theme),
            const SizedBox(height: 24),

            _buildRecoverySection(theme),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.backup_rounded,
            size: 32,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "Full Account Backup",
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "All your logs, challenges, and stats in one secure file",
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(ThemeData theme) {
    return CustomCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: AppRadius.md,
      child: Column(
        children: [
          _buildInfoItem(theme, Icons.history_rounded, "Daily Logs"),
          const SizedBox(height: 12),
          _buildInfoItem(
            theme,
            Icons.emoji_events_rounded,
            "Challenges & Progress",
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            theme,
            Icons.analytics_rounded,
            "Daily Metadata & Streaks",
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(ThemeData theme, IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityHeader(ThemeData theme) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          "Master Password",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(ThemeData theme) {
    return TextField(
      controller: _passwordController,
      obscureText: !_showPassword,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: "Create a secure backup password",
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _showPassword = !_showPassword),
        ),
      ),
    );
  }

  Widget _buildRecoverySection(ThemeData theme) {
    final customColors = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: customColors.error,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                "RECOVERY CODES",
                style: theme.textTheme.labelLarge?.copyWith(
                  color: customColors.error,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "Write these down. If you lose your password, these codes are the ONLY way to recover your data.",
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          _buildRecoveryGrid(theme),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildCopyButton(theme)),
              const SizedBox(width: 12),
              Expanded(child: _buildDownloadTxtButton(theme)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadTxtButton(ThemeData theme) {
    return OutlinedButton.icon(
      onPressed: () {
        final content =
            "DoneToday Recovery Phrase\n\nRECOVERY PHRASE:\n$_recoveryPhrase";
        final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
        FileHelper.saveAndShareText(
          content,
          "DoneToday_Recovery_$timestamp.txt",
        );
      },
      icon: const Icon(Icons.file_download_outlined, size: 18),
      label: const Text("TXT"),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildRecoveryGrid(ThemeData theme) {
    final codes = _recoveryPhrase.split(' ');
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            codes[index],
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCopyButton(ThemeData theme) {
    return OutlinedButton.icon(
      onPressed: () {
        Clipboard.setData(ClipboardData(text: _recoveryPhrase));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Recovery codes copied")));
      },
      icon: const Icon(Icons.copy_rounded, size: 18),
      label: const Text("Copy"),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildActions(BuildContext context, ThemeData theme) {
    bool canExport = _passwordController.text.length >= 8 && !_isExporting;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: canExport
                ? () async {
                    setState(() => _isExporting = true);
                    try {
                      await Future.delayed(const Duration(milliseconds: 100));
                      await BackupService.exportData(
                        password: _passwordController.text,
                        recoveryPhrase: _recoveryPhrase,
                      );
                      if (mounted) Navigator.pop(context);
                    } finally {
                      if (mounted) setState(() => _isExporting = false);
                    }
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isExporting
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    "Generate Backup File",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _isExporting ? null : () => Navigator.pop(context),
          child: Text("Cancel"),
        ),
      ],
    );
  }
}
