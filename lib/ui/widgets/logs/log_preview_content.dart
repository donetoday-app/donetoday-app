import 'package:done_today/theme/ui_constants.dart';
import 'package:done_today/utils/time_util.dart';
import 'package:flutter/material.dart';
import 'package:done_today/ui/widgets/done_today_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:done_today/providers/settings/theme_notifier.dart';

class LogPreviewContent extends ConsumerWidget {
  final String title;
  final String description;
  final String mood;
  final String category;
  final List<String> tags;
  final int wordCount;
  final String? date;
  final String? time;
  final ScrollController? controller;

  const LogPreviewContent({
    super.key,
    required this.title,
    required this.description,
    required this.mood,
    required this.category,
    required this.tags,
    required this.wordCount,
    this.date,
    this.time,
    this.controller,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final use24Hour = ref.watch(themeNotifierProvider).use24HourFormat;

    final parseDate = date ?? TimeUtil.todayIso();
    final parseTime = time ?? TimeUtil.getCurrentTimeFormatted(use24Hour: use24Hour);

    DateTime parseLogDateTime(String d, String t) {
      return TimeUtil.parseDateTime(d, t);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Align(
          alignment: Alignment.topCenter, // 🔥 force top anchoring
          child: SingleChildScrollView(
            controller: controller,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight, // 🔥 fill viewport height
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max, // 🔥 important
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.transparent,
                          child: Text(
                            mood.contains(' ') ? mood.split(' ').last : mood,
                            style: theme.textTheme.headlineMedium,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title.isEmpty ? "Untitled Log" : title,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                TimeUtil.formatFullDisplay(
                                  parseLogDateTime(parseDate, parseTime),
                                  use24Hour: use24Hour,
                                ),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
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
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Chip(
                      avatar: const Icon(Icons.category_rounded, size: 14),
                      label: Text(
                        category.isEmpty ? 'Uncategorized' : category,
                      ),
                      backgroundColor: theme.colorScheme.secondaryContainer
                          .withOpacity(0.3),
                      side: BorderSide.none,
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Tags Section
                    if (tags.isNotEmpty) ...[
                      Text(
                        "TAGS",
                        style: theme.textTheme.labelSmall?.copyWith(
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: tags.map((tag) {
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
                      color: theme.colorScheme.onSurface.withOpacity(0.08),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          "$wordCount words • ${((wordCount) / 200).ceil()} min read",
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DoneTodayMarkdown(
                      data: description.isEmpty
                          ? '*Nothing to preview yet.*'
                          : description,
                      textColor: theme.colorScheme.onSurface,
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
