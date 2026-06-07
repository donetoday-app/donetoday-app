import 'package:done_today/ui/widgets/bottom_nav_bar.dart';
import 'package:done_today/ui/widgets/top_nav_bar.dart';
import 'package:done_today/utils/responsive_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:done_today/providers/settings/theme_notifier.dart';

class ResponsiveScaffold extends ConsumerWidget {
  final Widget body;

  const ResponsiveScaffold({super.key, required this.body});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read the user's preference for floating navbar
    final themeState = ref.watch(themeNotifierProvider);
    final userPreference = themeState.useFloatingNavBar;

    // Screen size-dependent behavior:
    // - Mobile: Respects user preference (toggle visible in settings)
    // - Tablet/Desktop: Always ON (floating navbar always active, toggle hidden)
    return ResponsiveWidget(
      mobile: _AppScaffold(
        body: body,
        isFloating: userPreference,
      ), // Mobile: respects user toggle (defaults to ON)
      tablet: _AppScaffold(
        body: body,
        isFloating: true,
      ), // Tablet: always floating on (no toggle)
      desktop: _AppScaffold(
        body: body,
        isFloating: true,
      ), // Desktop: always floating on (no toggle)
    );
  }
}

class _AppScaffold extends ConsumerWidget {
  final Widget body;
  final bool isFloating;

  const _AppScaffold({required this.body, required this.isFloating});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final currentIndex = _getSelectedIndex(location);
    final theme = Theme.of(context);

    // Identify if we are on a secondary inner screen
    final bool isSecondaryScreen =
        !(location == '/' ||
            location == '/logs' ||
            location == '/challenges' ||
            location == '/analytics' ||
            location == '/profile');

    final scaffold = Scaffold(
      appBar: isSecondaryScreen
          ? null
          : AppNavBar(title: _getTitle(location), showAvatar: false),
      body: Stack(
        children: [
          body,
          if (!isSecondaryScreen && isFloating)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 400),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHigh
                              .withOpacity(0.95),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.outline.withOpacity(0.1),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.shadow.withOpacity(0.15),
                              blurRadius: 20,
                              spreadRadius: 2,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: BottomNavBar(
                            selectedIndex: currentIndex,
                            onItemSelected: (index) =>
                                _onItemSelected(context, index),
                            items: _navItems,
                            isFloating: true,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      resizeToAvoidBottomInset: true,
      extendBody: false,
      bottomNavigationBar: isSecondaryScreen
          ? null
          : (isFloating
                ? null
                : BottomNavBar(
                    selectedIndex: currentIndex,
                    onItemSelected: (index) => _onItemSelected(context, index),
                    items: _navItems,
                    isFloating: false,
                  )),
    );

    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: Center(
        child: ResponsiveConstraints(
          maxWidth: ResponsiveHelper.maxFullWidth,
          child: isMobile
              ? scaffold
              : Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.15),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 24,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: scaffold,
                ),
        ),
      ),
    );
  }
}

const List<NavItem> _navItems = [
  NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
  NavItem(icon: Icons.article_rounded, label: 'My Logs'),
  NavItem(icon: Icons.emoji_events_rounded, label: 'Challenges'),
  NavItem(icon: Icons.analytics_rounded, label: 'Analytics'),
  NavItem(icon: Icons.person_rounded, label: 'Profile'),
];

int _getSelectedIndex(String location) {
  if (location == '/') return 0;
  if (location.startsWith('/logs')) return 1;
  if (location.startsWith('/challenges')) return 2;
  if (location.startsWith('/analytics')) return 3;
  if (location.startsWith('/profile')) return 4;
  return 0;
}

String _getTitle(String location) {
  if (location == '/') return 'Dashboard';
  if (location.startsWith('/logs')) return 'My Logs';
  if (location.startsWith('/challenges')) return 'Challenges';
  if (location.startsWith('/analytics')) return 'Activity';
  if (location.startsWith('/profile')) return 'Profile';
  return 'Done Today';
}

void _onItemSelected(BuildContext context, int index) {
  switch (index) {
    case 0:
      context.goNamed('dashboard');
      break;
    case 1:
      context.goNamed('logs');
      break;
    case 2:
      context.goNamed('challenges');
      break;
    case 3:
      context.goNamed('analytics');
      break;
    case 4:
      context.goNamed('profile');
      break;
  }
}
