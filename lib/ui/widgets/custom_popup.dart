import 'dart:ui';

import 'package:done_today/utils/responsive_helper.dart';
import 'package:flutter/material.dart';

class CustomPopup extends StatelessWidget {
  final Widget child;
  final Widget? footer;
  final bool showCloseButton;
  final double? maxWidth;
  final EdgeInsets? padding;
  final EdgeInsets? footerPadding;
  final CrossAxisAlignment crossAxisAlignment;
  final bool disableScroll;

  const CustomPopup({
    super.key,
    required this.child,
    this.footer,
    this.showCloseButton = true,
    this.maxWidth,
    this.padding,
    this.footerPadding,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.disableScroll = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = ResponsiveHelper.isMobile(context);

    if (isMobile) {
      return _buildMobileLayout(context, theme);
    }
    return _buildDesktopLayout(context, theme);
  }

  Widget _buildMobileLayout(BuildContext context, ThemeData theme) {
    return Material(
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          if (showCloseButton)
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [_buildCloseButton(context, theme)],
                ),
              ),
            ),
          Expanded(
            child: disableScroll
                ? Padding(
                    padding:
                        padding ??
                        EdgeInsets.fromLTRB(
                          24,
                          showCloseButton ? 0 : 32,
                          24,
                          footer == null ? 32 : 12,
                        ),
                    child: child,
                  )
                : ScrollConfiguration(
                    behavior: ScrollConfiguration.of(
                      context,
                    ).copyWith(scrollbars: false),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding:
                          padding ??
                          EdgeInsets.fromLTRB(
                            24,
                            showCloseButton ? 0 : 32,
                            24,
                            footer == null ? 32 : 12,
                          ),
                      child: Column(
                        crossAxisAlignment: crossAxisAlignment,
                        children: [child],
                      ),
                    ),
                  ),
          ),
          if (footer != null) _buildFooter(theme, true),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, ThemeData theme) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth ?? 700),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(
                0.92,
              ), // Beautiful translucent matching search popup
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.onSurface.withOpacity(0.08),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showCloseButton)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: _buildCloseButton(context, theme),
                    ),
                  ),
                Flexible(
                  child: Padding(
                    padding:
                        padding ??
                        EdgeInsets.fromLTRB(
                          32,
                          showCloseButton ? 16 : 32,
                          32,
                          footer == null ? 40 : 12,
                        ),
                    child: disableScroll
                        ? child
                        : SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: crossAxisAlignment,
                              children: [child],
                            ),
                          ),
                  ),
                ),
                if (footer != null) _buildFooter(theme, false),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(ThemeData theme, bool isMobile) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding:
            footerPadding ??
            EdgeInsets.fromLTRB(24, 16, 24, isMobile ? 24 : 16),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.onSurface.withOpacity(0.08),
              width: 1.0,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: footer!,
          ),
        ),
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context, ThemeData theme) {
    return IconButton(
      icon: const Icon(Icons.close_rounded, size: 24),
      onPressed: () => Navigator.of(context).pop(),
      style: IconButton.styleFrom(
        backgroundColor: theme.colorScheme.surfaceContainerHighest.withOpacity(
          0.4,
        ),
        foregroundColor: theme.colorScheme.onSurfaceVariant,
        padding: const EdgeInsets.all(12),
      ),
    );
  }
}
