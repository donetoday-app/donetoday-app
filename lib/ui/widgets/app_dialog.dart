import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:done_today/theme/app_theme.dart';

class AppDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;

  const AppDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmLabel = "Confirm",
    this.cancelLabel = "Cancel",
    required this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    String confirmLabel = "Confirm",
    String cancelLabel = "Cancel",
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    bool isDestructive = false,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: title,
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) {
        return AppDialog(
          title: title,
          content: content,
          confirmLabel: confirmLabel,
          cancelLabel: cancelLabel,
          onConfirm: onConfirm,
          onCancel: onCancel,
          isDestructive: isDestructive,
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
                ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppDialogFrame(
      title: title,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      onConfirm: onConfirm,
      onCancel: onCancel,
      isDestructive: isDestructive,
      child: content,
    );
  }
}

/// A reusable shell for dialogs that provides the background, header, and footer.
class AppDialogFrame extends StatelessWidget {
  final String title;
  final Widget child;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;

  const AppDialogFrame({
    super.key,
    required this.title,
    required this.child,
    this.confirmLabel = "Confirm",
    this.cancelLabel = "Cancel",
    required this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = AppTheme.of(context);

    // Determine the header icon based on context/title
    IconData headerIcon = Icons.info_rounded;
    Color iconColor = theme.colorScheme.primary;

    if (isDestructive) {
      headerIcon = Icons.warning_amber_rounded;
      iconColor = customColors.error;
    } else {
      final lowercaseTitle = title.toLowerCase();
      if (lowercaseTitle.contains('backup') ||
          lowercaseTitle.contains('export')) {
        headerIcon = Icons.backup_rounded;
        iconColor = theme.colorScheme.primary;
      } else if (lowercaseTitle.contains('profile') ||
          lowercaseTitle.contains('user')) {
        headerIcon = Icons.person_rounded;
        iconColor = theme.colorScheme.primary;
      } else {
        headerIcon = Icons.info_outline_rounded;
        iconColor = theme.colorScheme.primary;
      }
    }

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(
              0.92,
            ), // Beautiful acrylic glass translucent background
            borderRadius: BorderRadius.circular(
              24,
            ), // Uniform 24px rounded corners
            border: Border.all(
              color: theme.colorScheme.onSurface.withOpacity(0.08),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sleek Visual Badge (Top Center)
              const SizedBox(height: 28),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: iconColor.withOpacity(0.15),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(headerIcon, size: 28, color: iconColor),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Content (Centered, clean Typography wrapper)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: DefaultTextStyle(
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: theme.colorScheme.onSurface.withOpacity(0.65),
                    fontSize: 14,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                  child: child,
                ),
              ),

              const SizedBox(height: 18),

              // Footer Actions
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: theme.colorScheme.onSurface.withOpacity(0.05),
                      width: 1,
                    ),
                  ),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(28),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onCancel ?? () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(
                            color: theme.colorScheme.onSurface.withOpacity(
                              0.08,
                            ),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          cancelLabel,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: onConfirm,
                        style: FilledButton.styleFrom(
                          backgroundColor: isDestructive
                              ? customColors.error
                              : theme.colorScheme.primary,
                          foregroundColor: isDestructive
                              ? Colors.white
                              : theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          confirmLabel,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
