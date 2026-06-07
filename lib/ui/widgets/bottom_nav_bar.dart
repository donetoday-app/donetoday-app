import 'dart:convert';
import 'package:done_today/providers/auth/auth_notifier.dart';
import 'package:done_today/state/auth/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BottomNavBar extends ConsumerWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final List<NavItem> items;
  final bool isFloating;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items,
    this.isFloating = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authNotifierProvider);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: isFloating
          ? const BoxDecoration()
          : BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.onSurface.withOpacity(0.08),
                  width: 1.0,
                ),
              ),
            ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isSelected = index == selectedIndex;
            final isProfileTab = item.label == 'Profile';

            Widget iconWidget;
            if (isProfileTab && authState is AuthLoggedIn) {
              final userDetails = authState.userDetails;
              final avatarData = userDetails['avatar_data'] as String?;
              final profileUrl = userDetails['avatar'] as String?;

              iconWidget = Container(
                padding: const EdgeInsets.all(1.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withOpacity(0.08),
                    width: 1.5,
                  ),
                ),
                child: CircleAvatar(
                  radius: 11, // Fits perfectly inside 24px icon bounds
                  backgroundColor: theme.colorScheme.surfaceContainerHigh,
                  backgroundImage: avatarData != null
                      ? MemoryImage(base64Decode(avatarData))
                      : (profileUrl != null ? NetworkImage(profileUrl) : null)
                            as ImageProvider?,
                  child: (profileUrl == null && avatarData == null)
                      ? Icon(
                          Icons.person_rounded,
                          size: 14,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        )
                      : null,
                ),
              );
            } else {
              iconWidget = Icon(
                item.icon,
                size: 24,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              );
            }

            return Expanded(
              child: GestureDetector(
                onTap: item.enabled ? () => onItemSelected(index) : null,
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 32,
                      width: 56,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary.withOpacity(0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(child: iconWidget),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          item.label,
                          maxLines: 1,
                          style: theme.textTheme.labelSmall!.copyWith(
                            fontSize: 10.5,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w500,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class NavItem {
  final IconData icon;
  final String label;
  final bool enabled;

  const NavItem({required this.icon, required this.label, this.enabled = true});
}
