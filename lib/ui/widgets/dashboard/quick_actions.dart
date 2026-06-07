import 'package:done_today/theme/ui_constants.dart';
import 'package:done_today/ui/widgets/custom_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:done_today/providers/logs/logs_notifier.dart';
import 'package:done_today/state/logs/logs_state.dart';
import 'package:done_today/utils/time_util.dart';

class QuickActions extends ConsumerWidget {
  const QuickActions({super.key});

  void _showCreateOptions(BuildContext context, bool hasToday) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(
          color: theme.colorScheme.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            Text(
              "QUICK CREATE",
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.5,
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Material(
              color: Colors.transparent,
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: hasToday
                        ? theme.colorScheme.surfaceContainerHighest.withOpacity(
                            0.5,
                          )
                        : theme.colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: AppRadius.radiusMd,
                  ),
                  child: Icon(
                    hasToday
                        ? Icons.check_circle_rounded
                        : Icons.edit_note_rounded,
                    color: hasToday
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                title: Text(
                  hasToday ? "Already Logged" : "New log",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: hasToday
                        ? theme.colorScheme.onSurface.withOpacity(0.5)
                        : null,
                  ),
                ),
                subtitle: Text(
                  hasToday
                      ? "You've already captured today's win!"
                      : "Capture what you've done today",
                  style: theme.textTheme.bodySmall,
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: hasToday
                    ? null
                    : () {
                        Navigator.pop(context);
                        context.push('/logs/new');
                      },
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final logsState = ref.watch(logsNotifierProvider);

    bool hasToday = false;
    if (logsState is LogsLoaded) {
      final today = TimeUtil.todayIso();
      hasToday = logsState.logs.any((l) => l.date == today);
    }

    return Row(
      children: [
        _action(
          context,
          theme,
          "Create",
          Icons.add_rounded,
          () => _showCreateOptions(context, hasToday),
        ),
        const SizedBox(width: AppSpacing.sm),
        _action(
          context,
          theme,
          "History",
          Icons.history_rounded,
          () => context.goNamed('logs'),
        ),
        const SizedBox(width: AppSpacing.sm),
        _action(
          context,
          theme,
          "Activity",
          Icons.analytics_rounded,
          () => context.goNamed('activity_analytics'),
        ),
      ],
    );
  }

  Widget _action(
    BuildContext context,
    ThemeData theme,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.radiusLg,
        child: CustomCard(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          borderRadius: AppRadius.lg,
          child: Column(
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 20),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
