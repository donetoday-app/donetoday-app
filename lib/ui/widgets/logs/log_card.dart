import 'package:done_today/theme/app_theme.dart';
import 'package:done_today/theme/ui_constants.dart';
import 'package:done_today/ui/widgets/custom_card.dart';
import 'package:flutter/material.dart';
import 'package:done_today/utils/time_util.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:done_today/providers/settings/theme_notifier.dart';

class LogCard extends StatefulWidget {
  final String title;
  final String date;
  final String time;
  final String description;
  final String? mood;
  final List<String>? tags;
  final int wordCount;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool? isDeletable;

  const LogCard({
    super.key,
    required this.title,
    required this.date,
    required this.time,
    required this.description,
    this.mood,
    this.tags,
    required this.wordCount,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.isDeletable,
  });

  @override
  State<LogCard> createState() => _LogCardState();
}

class _LogCardState extends State<LogCard> {
  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final theme = Theme.of(context);
        final customColors = AppTheme.of(context);
        final use24Hour = ref.watch(themeNotifierProvider).use24HourFormat;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: GestureDetector(
            onTap: widget.onTap,
            child: CustomCard(
              padding: EdgeInsets.zero,
              borderRadius: 20,
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: 4,
                      child: Container(color: theme.colorScheme.primary),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16).copyWith(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.article_rounded,
                                          size: 14,
                                          color: theme.colorScheme.primary,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          TimeUtil.formatReadableDate(
                                            TimeUtil.parseIsoDate(widget.date),
                                          ).toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.primary,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          TimeUtil.formatTimeString(
                                            widget.time,
                                            use24Hour: use24Hour,
                                          ),
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.4),
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      widget.title,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ],
                                ),
                              ),
                              if (widget.mood != null) ...[
                                const SizedBox(width: 12),
                                Text(
                                  widget.mood!.split(' ').last,
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.4,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Wrap(
                                  spacing: AppSpacing.sm,
                                  runSpacing: AppSpacing.sm,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    if (widget.tags != null)
                                      ...widget.tags!
                                          .take(2)
                                          .map(
                                            (tag) => _buildTagChip(theme, tag),
                                          ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Text(
                                "${widget.wordCount} words",
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.5),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: theme.colorScheme.onSurface.withOpacity(
                              0.06,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          Icon(
                                            Icons.stars_rounded,
                                            color: theme.colorScheme.primary,
                                            size: 20,
                                          ),
                                          const SizedBox(width: AppSpacing.sm),
                                          Expanded(
                                            child: Text(
                                              "Share is coming soon!",
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    color: theme
                                                        .colorScheme
                                                        .onSurface,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: theme.colorScheme.surfaceContainerHigh,
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 2),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                          color: theme.colorScheme.onSurface
                                              .withOpacity(0.08),
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                icon: Icon(
                                  Icons.share_rounded,
                                  size: 22,
                                  color: theme.colorScheme.onSurface.withOpacity(0.65),
                                ),
                                label: Text(
                                  "SHARE",
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontSize: 13,
                                    color: theme.colorScheme.onSurface.withOpacity(0.65),
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                                  minimumSize: const Size(0, 44),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (widget.onEdit != null || widget.isDeletable == true) ...[
                                    const SizedBox(width: AppSpacing.sm),
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit_rounded,
                                        size: 22,
                                        color: theme.colorScheme.primary.withOpacity(0.8),
                                      ),
                                      style: IconButton.styleFrom(
                                        padding: const EdgeInsets.all(AppSpacing.sm),
                                      ),
                                      onPressed: widget.onEdit,
                                      tooltip: 'Edit Log',
                                    ),
                                  ],
                                  if (widget.onDelete != null) ...[
                                    const SizedBox(width: AppSpacing.xs),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete_rounded,
                                        color: customColors.error.withOpacity(0.8),
                                        size: 22,
                                      ),
                                      style: IconButton.styleFrom(
                                        padding: const EdgeInsets.all(AppSpacing.sm),
                                      ),
                                      onPressed: widget.onDelete,
                                      tooltip: 'Delete Log',
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
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

  Widget _buildTagChip(ThemeData theme, String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: AppRadius.radiusMd,
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Text(
        "#$tag",
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}
