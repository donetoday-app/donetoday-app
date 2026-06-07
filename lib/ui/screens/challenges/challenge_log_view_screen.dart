import 'package:done_today/storage/models/log_model.dart';
import 'package:done_today/theme/ui_constants.dart';
import 'package:done_today/utils/responsive_helper.dart';
import 'package:done_today/utils/time_util.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:done_today/ui/widgets/unified_header.dart';
import 'package:done_today/ui/widgets/done_today_markdown.dart';
import 'package:done_today/storage/models/challenge.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:done_today/providers/settings/theme_notifier.dart';
import 'package:done_today/providers/challenges/challenges_notifier.dart';

class ChallengeLogViewScreen extends ConsumerWidget {
  final Challenge challenge;
  final Log log;

  const ChallengeLogViewScreen({
    super.key,
    required this.challenge,
    required this.log,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final use24Hour = ref.watch(themeNotifierProvider).use24HourFormat;

    return Scaffold(
      body: SafeArea(
        child: ResponsiveConstraints(
          maxWidth: ResponsiveHelper.isDesktop(context)
              ? ResponsiveHelper.maxFullWidth
              : ResponsiveHelper.maxContentWidth,
          child: Column(
            children: [
              UnifiedHeader(
                title: "DAY ${log.dayNumber} LOG",
                onBack: () => context.pop(),
                actions: [
                  IconButton(
                    icon: Icon(
                      Icons.edit_rounded,
                      size: 22,
                      color: theme.colorScheme.primary,
                    ),
                    onPressed: () => context.push(
                      '/challenges/${challenge.id}/logs/edit/${log.id}',
                      extra: {'challenge': challenge, 'log': log},
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Padding(
                          padding: AppSpacing.screenPadding,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Row(
                                children: [
                                  if (log.mood != null)
                                    CircleAvatar(
                                      radius: 32,
                                      backgroundColor: theme
                                          .colorScheme
                                          .surfaceContainerHighest
                                          .withOpacity(0.3),
                                      child: Text(
                                        // Handle cases where mood might be "happy 😊"
                                        log.mood!.split(' ').last,
                                        style: theme.textTheme.headlineMedium,
                                      ),
                                    ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          log.title,
                                          style: theme.textTheme.headlineSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        const SizedBox(height: AppSpacing.xs),
                                        Text(
                                          TimeUtil.formatFullDisplay(
                                            TimeUtil.parseIsoDate(log.date),
                                            use24Hour: use24Hour,
                                          ),
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.6),
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              // Category Section
                              Text(
                                "CATEGORY",
                                style: theme.textTheme.labelSmall?.copyWith(
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.w900,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.4),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Chip(
                                avatar: const Icon(
                                  Icons.category_rounded,
                                  size: 14,
                                ),
                                label: Text(
                                  challenge.category.isEmpty
                                      ? 'Uncategorized'
                                      : challenge.category,
                                ),
                                backgroundColor: theme
                                    .colorScheme
                                    .secondaryContainer
                                    .withOpacity(0.3),
                                side: BorderSide.none,
                              ),

                              const SizedBox(height: AppSpacing.md),

                              // Tags Section
                              if (log.tags != null && log.tags!.isNotEmpty) ...[
                                Text(
                                  "TAGS",
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    letterSpacing: 1.5,
                                    fontWeight: FontWeight.w900,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.4),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Wrap(
                                  spacing: AppSpacing.sm,
                                  runSpacing: AppSpacing.sm,
                                  children: log.tags!.map((tag) {
                                    return Chip(
                                      label: Text(tag),
                                      backgroundColor: theme
                                          .colorScheme
                                          .surfaceContainerHighest
                                          .withOpacity(0.3),
                                      side: BorderSide.none,
                                    );
                                  }).toList(),
                                ),
                              ],
                              Container(
                                height: 1.0,
                                width: double.infinity,
                                margin: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.xs,
                                ),
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.08,
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    "${log.wordCount} words",
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              DoneTodayMarkdown(
                                data: log.description,
                                textColor: theme.colorScheme.onSurface,
                                fontSize: 16,
                                height: 1.6,
                                onDataChanged: (updatedData) {
                                  ref
                                      .read(challengesNotifierProvider.notifier)
                                      .updateLog(
                                        logId: log.id,
                                        title: log.title,
                                        description: updatedData,
                                        mood: log.mood,
                                        tags: log.tags,
                                        silent: true,
                                      );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
