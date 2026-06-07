import 'package:done_today/storage/models/log_model.dart';
import 'package:done_today/ui/widgets/calendar.dart';
import 'package:done_today/ui/widgets/word_activity.dart';
import 'package:done_today/ui/widgets/section_header.dart';
import 'package:flutter/material.dart';

Widget Activity(ThemeData theme, List<Log> logs) {
  if (logs.isEmpty) {
    return const SizedBox.shrink();
  }

  bool showWordGraph = false;

  return StatefulBuilder(
    builder: (BuildContext context, void Function(void Function()) setState) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: "Activity Overview",
            trailing: Row(
              children: [
                IconButton.filled(
                  tooltip: "Logging Calendar",
                  style: IconButton.styleFrom(
                    backgroundColor: !showWordGraph
                        ? theme.colorScheme.primary.withOpacity(0.15)
                        : Colors.transparent,
                  ),
                  icon: Icon(
                    Icons.calendar_month_rounded,
                    color: !showWordGraph
                        ? theme.colorScheme.primary
                        : theme.iconTheme.color,
                  ),
                  onPressed: () => setState(() => showWordGraph = false),
                ),
                IconButton.filled(
                  tooltip: "Word Activity",
                  style: IconButton.styleFrom(
                    backgroundColor: showWordGraph
                        ? theme.colorScheme.primary.withOpacity(0.15)
                        : Colors.transparent,
                  ),
                  icon: Icon(
                    Icons.insights_rounded,
                    color: showWordGraph
                        ? theme.colorScheme.primary
                        : theme.iconTheme.color,
                  ),
                  onPressed: () => setState(() => showWordGraph = true),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          showWordGraph
              ? WordActivity(logs: logs)
              : ActivityCalendar(logs: logs),
        ],
      );
    },
  );
}
