import 'package:done_today/services/backup_service.dart';
import 'package:done_today/ui/widgets/custom_popup.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DataImportPicker extends StatefulWidget {
  const DataImportPicker({super.key});

  @override
  State<DataImportPicker> createState() => _DataImportPickerState();
}

class _DataImportPickerState extends State<DataImportPicker> {
  final TextEditingController _passwordController = TextEditingController();
  final List<TextEditingController> _codeControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  Uint8List? _pickedContent;
  bool _isImporting = false;
  bool _showPassword = false;
  bool _useRecoveryCode = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    for (var controller in _codeControllers) controller.dispose();
    for (var node in _focusNodes) node.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final bytes = await BackupService.pickBackupFile();
    if (bytes != null) {
      setState(() => _pickedContent = bytes);
    }
  }

  String get _secret {
    if (_useRecoveryCode)
      return _codeControllers.map((c) => c.text.trim().toUpperCase()).join(' ');
    return _passwordController.text;
  }

  bool get _isSecretValid {
    if (_useRecoveryCode)
      return _codeControllers.every((c) => c.text.trim().length == 9);
    return _passwordController.text.length >= 8;
  }

  Future<void> _startImport() async {
    if (_pickedContent == null) return;
    final secret = _secret;
    if (secret.isEmpty) return;

    setState(() {
      _isImporting = true;
      _errorMessage = null;
    });
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      final success = await BackupService.processImport(
        zipBytes: _pickedContent!,
        secret: secret,
        isRecoveryCode: _useRecoveryCode,
      );
      if (mounted) {
        if (success) {
          Navigator.pop(context, true);
        } else {
          setState(() {
            _errorMessage = _useRecoveryCode
                ? "Invalid recovery code. Please check and try again."
                : "Incorrect password. Please try again.";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Import failed. The archive might be corrupted.";
        });
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomPopup(
      footer: _buildFooter(theme),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(theme),
              const SizedBox(height: 32),
              if (_pickedContent == null)
                _buildStep1(theme)
              else
                _buildStep2(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    bool step2 = _pickedContent != null;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.settings_backup_restore_rounded,
            size: 32,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          step2 ? "Verify Identity" : "Full Account Restore",
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: -0.5,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          step2
              ? "Decrypting full account archive"
              : "All your logs, challenges, and stats restored from a secure file",
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildStep1(ThemeData theme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _pickFile,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.25),
              width: 1.5,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary.withOpacity(0.08),
                theme.colorScheme.primary.withOpacity(0.02),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.02),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cloud_upload_rounded,
                  size: 36,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Choose Backup Archive",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Supports secure .zip format",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep2(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPickedFileCard(theme),
        const SizedBox(height: 32),
        _buildSecurityHeader(theme),
        const SizedBox(height: 24),
        if (!_useRecoveryCode)
          _buildPasswordField(theme)
        else
          _buildRecoveryGrid(theme),
        if (_errorMessage != null) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.error.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: theme.colorScheme.error,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPickedFileCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.archive_rounded, color: theme.colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              "Archive Selected",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _pickedContent = null),
            child: const Text("Change"),
          ),
        ],
      ),
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
          _useRecoveryCode ? "Recovery Codes" : "Master Password",
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
      onChanged: (_) => setState(() {
        _errorMessage = null;
      }),
      decoration: InputDecoration(
        hintText: "Password for this backup",
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _showPassword
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
          ),
          onPressed: () => setState(() => _showPassword = !_showPassword),
        ),
      ),
    );
  }

  Widget _buildRecoveryGrid(ThemeData theme) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => TextField(
        controller: _codeControllers[index],
        focusNode: _focusNodes[index],
        style: TextStyle(
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
          fontFamily: 'monospace',
          color: theme.colorScheme.onSurface,
        ),
        inputFormatters: [_RecoveryCodeFormatter()],
        textCapitalization: TextCapitalization.characters,
        decoration: InputDecoration(
          hintText: "XXXX-XXXX",
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: theme.colorScheme.outline.withOpacity(0.1),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 1.5,
            ),
          ),
        ),
        onChanged: (v) {
          if (v.length == 9 && index < 5) _focusNodes[index + 1].requestFocus();
          setState(() {
            _errorMessage = null;
          });
        },
      ),
    );
  }

  Widget _buildFooter(ThemeData theme) {
    if (_pickedContent == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ],
      );
    }
    bool canSubmit = _isSecretValid && !_isImporting;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: canSubmit ? _startImport : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isImporting
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    "Restore Account",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _isImporting
              ? null
              : () => setState(() {
                  _useRecoveryCode = !_useRecoveryCode;
                  _passwordController.clear();
                  _errorMessage = null;
                  for (var c in _codeControllers) c.clear();
                }),
          child: Text(_useRecoveryCode ? "Use Password" : "Use Recovery Codes"),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _isImporting ? null : () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
      ],
    );
  }
}

class _RecoveryCodeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.toUpperCase();
    if (text.length > 9) return oldValue;
    if (text.length == 4 && oldValue.text.length == 3)
      return TextEditingValue(
        text: '$text-',
        selection: const TextSelection.collapsed(offset: 5),
      );
    return newValue.copyWith(text: text);
  }
}
