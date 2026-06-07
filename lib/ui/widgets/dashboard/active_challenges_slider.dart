import 'dart:async';
import 'package:done_today/theme/ui_constants.dart';
import 'package:done_today/storage/models/challenge.dart';
import 'package:done_today/storage/models/log_model.dart';
import 'package:done_today/ui/widgets/custom_card.dart';
import 'package:done_today/utils/time_util.dart';
import 'package:flutter/material.dart';

class ActiveChallengesSlider extends StatefulWidget {
  final List<Challenge> challenges;
  final Map<String, List<Log>> challengeLogs;
  final Function(Challenge) onChallengeTap;
  final Function(Challenge) onLog;

  const ActiveChallengesSlider({
    super.key,
    required this.challenges,
    required this.challengeLogs,
    required this.onChallengeTap,
    required this.onLog,
  });

  @override
  State<ActiveChallengesSlider> createState() => _ActiveChallengesSliderState();
}

class _ActiveChallengesSliderState extends State<ActiveChallengesSlider> {
  late PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer?.cancel();
    if (widget.challenges.length < 2) return;

    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        _currentPage++;
        if (_currentPage >= widget.challenges.length) {
          _currentPage = 0;
        }
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = TimeUtil.todayIso();

    if (widget.challenges.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: AppSpacing.xs,
        ),
        child: CustomCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          borderRadius: AppRadius.lg,
          child: SizedBox(
            height: 110,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "START A NEW JOURNEY",
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.primary,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "No Active Challenges",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Form a new habit. Start tracking today.",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.add_task_rounded,
                  size: 32,
                  color: theme.colorScheme.primary.withOpacity(0.6),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 165,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.challenges.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final challenge = widget.challenges[index];
              final logs = widget.challengeLogs[challenge.id] ?? [];
              final hasToday = logs.any((l) => l.date == today);
              final progress = logs.length / challenge.totalDays;

              return GestureDetector(
                onTap: () => widget.onChallengeTap(challenge),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: AppSpacing.xs,
                  ),
                  child: CustomCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    borderRadius: AppRadius.lg,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    challenge.category.toUpperCase(),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: theme.colorScheme.primary,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    challenge.title,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 20,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: hasToday
                                    ? Colors.green.withOpacity(0.1)
                                    : theme.colorScheme.primary.withOpacity(
                                        0.1,
                                      ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                hasToday
                                    ? Icons.check_circle_rounded
                                    : Icons.pending_actions_rounded,
                                color: hasToday
                                    ? Colors.green
                                    : theme.colorScheme.primary,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Day ${logs.length} of ${challenge.totalDays}",
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (!hasToday)
                              SizedBox(
                                height: 32,
                                child: FilledButton.tonal(
                                  onPressed: () => widget.onLog(challenge),
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    "Log Day",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.green.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      size: 14,
                                      color: Colors.green.withOpacity(0.8),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "LOGGED",
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: Colors.green.withOpacity(
                                              0.8,
                                            ),
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.5,
                                            fontSize: 10,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 6,
                                  backgroundColor:
                                      theme.colorScheme.surfaceContainerHighest,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    hasToday
                                        ? Colors.green
                                        : theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              "${(progress * 100).toInt()}%",
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: theme.colorScheme.onSurface,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // if (widget.challenges.length > 1) ...[
        //   const SizedBox(height: AppSpacing.md),
        //   Row(
        //     mainAxisAlignment: MainAxisAlignment.center,
        //     children: List.generate(
        //       widget.challenges.length,
        //       (index) => AnimatedContainer(
        //         duration: const Duration(milliseconds: 300),
        //         margin: const EdgeInsets.symmetric(horizontal: 4),
        //         height: 6,
        //         width: _currentPage == index ? 24 : 6,
        //         decoration: BoxDecoration(
        //           color: _currentPage == index
        //             ? theme.colorScheme.primary
        //             : theme.colorScheme.outline.withOpacity(0.2),
        //           borderRadius: BorderRadius.circular(12),
        //         ),
        //       ),
        //     ),
        //   ),
        // ],
      ],
    );
  }
}
