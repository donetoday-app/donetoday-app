import 'dart:math';
import 'package:done_today/providers/logs/logs_notifier.dart';
import 'package:done_today/state/logs/logs_state.dart';
import 'package:done_today/storage/hive/hive_service.dart';
import 'package:done_today/storage/models/log_model.dart';
import 'package:done_today/theme/ui_constants.dart';
import 'package:done_today/ui/widgets/unified_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

class DebugScreen extends ConsumerWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            UnifiedHeader(title: "DEBUG TOOLS", onBack: () => context.pop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  _buildSection(theme, "DATA GENERATION", [
                    _buildActionTile(
                      theme,
                      "Generate 30 Days of Logs",
                      "Creates dummy logs and metadata for the last month.",
                      Icons.auto_fix_high_rounded,
                      () => _generateDemoData(context, ref),
                    ),
                    _buildActionTile(
                      theme,
                      "Delete Debug Logs",
                      "Removes all logs tagged with #debug.",
                      Icons.cleaning_services_rounded,
                      () => _deleteDebugLogs(context, ref),
                    ),
                    _buildActionTile(
                      theme,
                      "Clear All App Data",
                      "Wipes all Hive boxes (Logs, Meta, Settings).",
                      Icons.delete_forever_rounded,
                      () => _clearAllData(context, ref),
                      isDestructive: true,
                    ),
                  ]),
                  const SizedBox(height: AppSpacing.lg),
                  _buildSection(theme, "SYSTEM INFO", [
                    Material(
                      color: Colors.transparent,
                      child: ListTile(
                        title: const Text("Platform"),
                        subtitle: Text(Theme.of(context).platform.toString()),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(ThemeData theme, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            title,
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.5,
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLg),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildActionTile(
    ThemeData theme,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    final color = isDestructive
        ? theme.colorScheme.error
        : theme.colorScheme.primary;
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
        onTap: onTap,
      ),
    );
  }

  Future<void> _generateDemoData(BuildContext context, WidgetRef ref) async {
    final moods = ["Happy 😊", "Excited 🤩", "Normal 😐", "Sad 😔", "Angry 😡"];
    final categories = [
      "Work",
      "Personal",
      "Health",
      "Fitness",
      "Coding",
      "Reading",
      "Mindfulness",
      "Social",
    ];
    String selectedCategory = "Random";

    // Category Selection Dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Generation Settings"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Select category for all logs:",
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButton<String>(
                value: selectedCategory,
                isExpanded: true,
                items: ["Random", ...categories]
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) => setState(() => selectedCategory = val!),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                "Note: All logs will be tagged with #debug for easy removal.",
                style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("CANCEL"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("GENERATE"),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    const uuid = Uuid();
    final random = Random();

    final tags = [
      "#win",
      "#progress",
      "#habit",
      "#learning",
      "#today",
      "#debug",
    ];
    final adjectives = [
      "productive",
      "challenging",
      "rewarding",
      "intense",
      "peaceful",
      "creative",
    ];
    final nouns = [
      "session",
      "breakthrough",
      "milestone",
      "activity",
      "routine",
      "experience",
    ];
    final verbs = [
      "completed",
      "achieved",
      "explored",
      "started",
      "finished",
      "improved",
    ];

    final now = DateTime.now();

    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      for (int i = 0; i < 30; i++) {
        final date = now.subtract(Duration(days: i));
        final dateStr =
            "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

        // 85% chance of having a log for the day
        if (random.nextDouble() < 0.85) {
          final logCount = random.nextInt(2) + 1; // 1-2 logs per day

          List<String> dailyLogIds = [];

          for (int j = 0; j < logCount; j++) {
            final logId = uuid.v4();
            dailyLogIds.add(logId);

            final adj = adjectives[random.nextInt(adjectives.length)];
            final noun = nouns[random.nextInt(nouns.length)];
            final verb = verbs[random.nextInt(verbs.length)];

            final description =
                "Today I $verb a $adj $noun. It was a ${random.nextBool() ? 'great' : 'useful'} way to stay consistent with my goals. Definitely feeling the ${random.nextInt(100)}% momentum!";

            final log = Log(
              id: logId,
              slug: "debug-log-$i-$j",
              title: "Debug: $verb $noun",
              description: description,
              mood: moods[random.nextInt(moods.length)],
              category: selectedCategory == "Random"
                  ? categories[random.nextInt(categories.length)]
                  : selectedCategory,
              date: dateStr,
              time: "${8 + random.nextInt(14)}:00",
              wordCount: 30 + random.nextInt(300),
              readTime: random.nextInt(8) + 1,
              tags: ["#debug", tags[random.nextInt(tags.length)]],
              createdAt: date.toIso8601String(),
              updatedAt: date.toIso8601String(),
            );

            await HiveService.saveLog(log.toJson());
          }
        }
      }

      // Refresh the logs state
      await ref.read(logsNotifierProvider.notifier).fetchInitialData();

      if (context.mounted) Navigator.pop(context); // Close loading dialog
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text("30 days of debug logs generated!")),
      );
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text("Error generating data: $e")),
      );
    }
  }

  Future<void> _deleteDebugLogs(BuildContext context, WidgetRef ref) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Debug Logs?"),
        content: const Text(
          "This will find and remove all logs tagged with #debug.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("DELETE", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final logsState = ref.read(logsNotifierProvider);
      if (logsState is! LogsLoaded) return;

      final debugLogs = logsState.logs
          .where((l) => l.tags?.contains("#debug") ?? false)
          .toList();

      if (debugLogs.isEmpty) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text("No debug logs found.")),
        );
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        for (final log in debugLogs) {
          await HiveService.deleteLog(log.id);
        }

        // Refresh the logs state
        await ref.read(logsNotifierProvider.notifier).fetchInitialData();

        if (context.mounted) Navigator.pop(context);
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text("Deleted ${debugLogs.length} debug logs.")),
        );
      } catch (e) {
        if (context.mounted) Navigator.pop(context);
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text("Error deleting logs: $e")),
        );
      }
    }
  }

  Future<void> _clearAllData(BuildContext context, WidgetRef ref) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear All Data?"),
        content: const Text(
          "This will permanently delete all logs and settings. This cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("CLEAR", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await HiveService.clearAllData();
      await ref.read(logsNotifierProvider.notifier).fetchInitialData();
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text("All data cleared.")),
      );
    }
  }
}
