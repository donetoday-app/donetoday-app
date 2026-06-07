import 'dart:convert';
import 'dart:ui';

import 'package:done_today/providers/auth/auth_notifier.dart';
import 'package:done_today/state/auth/auth_state.dart';
import 'package:done_today/utils/responsive_helper.dart';
import 'package:done_today/theme/ui_constants.dart';
import 'package:done_today/ui/widgets/search/global_search_popup.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AppNavBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final bool showTitleAndAvatar;
  final bool showAvatar;

  const AppNavBar({
    super.key,
    required this.title,
    this.showTitleAndAvatar = true,
    this.showAvatar = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final topPadding = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: theme.brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
        statusBarBrightness: theme.brightness,
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            height: 56 + topPadding,
            padding: EdgeInsets.only(top: topPadding),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.85),
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.onSurface.withOpacity(0.08),
                  width: 1.0,
                ),
              ),
            ),
            child: ResponsiveConstraints(
              alignment: Alignment.center,
              maxWidth: ResponsiveHelper.maxFullWidth,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
              ),
              child: Row(
                children: [
                  // Minimalist Brand Logo/Title
                  GestureDetector(
                    onTap: () => context.go('/'),
                    child: Row(
                      children: [
                        Image.asset(
                          'lib/assets/icon/logo.png',
                          height: 36, // Beautifully proportioned logo size
                          width: 36,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "DONE TODAY",
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.5,
                            fontSize: 15,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),

                  // Action Tray
                  if (ref.watch(authNotifierProvider) is AuthLoggedIn) ...[
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withOpacity(0.04),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () => GlobalSearchPopup.show(context),
                        icon: Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                        ),
                        tooltip: 'Global Search',
                      ),
                    ),
                    if (showAvatar) ...[
                      const SizedBox(width: 8),
                      _buildAvatar(context, ref, theme),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, WidgetRef ref, ThemeData theme) {
    final authState = ref.watch(authNotifierProvider);
    final userDetails = (authState as AuthLoggedIn).userDetails;
    final avatarData = userDetails['avatar_data'] as String?;
    final profileUrl = userDetails['avatar'] as String?;

    return GestureDetector(
      onTap: () => context.goNamed('profile'),
      child: Container(
        padding: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: theme.colorScheme.onSurface.withOpacity(0.08),
            width: 1.0,
          ),
          boxShadow: null,
        ),
        child: CircleAvatar(
          radius: 20, // Increased for a beautifully readable profile icon
          backgroundColor: theme.colorScheme.surfaceContainerHigh,
          backgroundImage: avatarData != null
              ? MemoryImage(base64Decode(avatarData))
              : (profileUrl != null ? NetworkImage(profileUrl) : null)
                    as ImageProvider?,
          child: (profileUrl == null && avatarData == null)
              ? _buildFallbackIcon(theme)
              : null,
        ),
      ),
    );
  }

  Widget _buildFallbackIcon(ThemeData theme) {
    return Icon(
      Icons.person_rounded,
      size: 20, // Increased from 18
      color: theme.colorScheme.onSurface.withOpacity(0.5),
    );
  }
}