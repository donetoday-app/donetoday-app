import 'dart:math';
import 'package:done_today/state/auth/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

Widget greeting(
  BuildContext context,
  ThemeData theme,
  AuthState authState,
  bool hasToday,
) {
  final name = (authState is AuthLoggedIn)
      ? (authState).userDetails['name']?.toString().toUpperCase() ?? 'USER'
      : 'USER';

  final hour = DateTime.now().hour;
  String timeGreeting;
  IconData timeIcon;
  Color greetingColor;

  if (hour >= 5 && hour < 12) {
    timeGreeting = "GOOD MORNING";
    timeIcon = Icons.wb_sunny_rounded;
    greetingColor = const Color(0xFFFFB547); // Sunrise Amber
  } else if (hour >= 12 && hour < 17) {
    timeGreeting = "GOOD AFTERNOON";
    timeIcon = Icons.light_mode_rounded;
    greetingColor = const Color(0xFF38BDF8); // Sky Blue
  } else if (hour >= 17 && hour < 21) {
    timeGreeting = "GOOD EVENING";
    timeIcon = Icons.wb_twilight_rounded;
    greetingColor = const Color(0xFFFB7185); // Sunset Rose
  } else {
    timeGreeting = "GOOD NIGHT";
    timeIcon = Icons.nights_stay_rounded;
    greetingColor = const Color(0xFF818CF8); // Moon Indigo
  }

  // Consistent dynamic quote selection for the entire day
  final daySeed =
      DateTime.now().year * 10000 +
      DateTime.now().month * 100 +
      DateTime.now().day;
  final random = Random(daySeed);

  final completedSubMessages = [
    "Today's entry is sealed. Beautifully done.",
    "One more step on this quiet journey.",
    "Momentum secured. Keep the fire burning.",
    "Your future self is grateful for today.",
  ];
  final pendingSubMessages = [
    "Put pen to paper. Define your sanctuary.",
    "Write the first word. The rest will follow.",
    "A blank page is a beautiful start.",
    "Reflect, release, and capture today.",
  ];

  final subMessage = hasToday
      ? completedSubMessages[random.nextInt(completedSubMessages.length)]
      : pendingSubMessages[random.nextInt(pendingSubMessages.length)];

  final isDark = theme.brightness == Brightness.dark;
  final primaryTextColor = isDark ? Colors.white : theme.colorScheme.onSurface;

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Time greeting pill (Enhanced size of text & icon!)
              Row(
                children: [
                  Icon(timeIcon, size: 24, color: greetingColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "$timeGreeting, $name",
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: primaryTextColor.withOpacity(0.65),
                        letterSpacing: 2.8,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // 2. Large status title
              Text(
                hasToday ? "TODAY IS DEFINED." : "WHAT WILL YOU DEFINE TODAY?",
                style: TextStyle(fontFamily: 'Outfit', 
                  fontSize: 26,
                  color: primaryTextColor,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              // 3. Dynamic daily insight
              Text(
                subMessage,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: primaryTextColor.withOpacity(0.45),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // 4. Elegant clickable status indicator (Pencil is clickable to create a new log!)
        GestureDetector(
          onTap: () {
            if (!hasToday) {
              context.push('/logs/new');
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "You've already defined today. Keep up the awesome momentum!",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  backgroundColor: theme.colorScheme.primaryContainer,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasToday
                    ? theme.colorScheme.primary.withOpacity(0.08)
                    : theme.colorScheme.primary.withOpacity(0.12),
                border: Border.all(
                  color: hasToday
                      ? theme.colorScheme.primary.withOpacity(0.2)
                      : theme.colorScheme.primary.withOpacity(0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(
                      hasToday ? 0.04 : 0.08,
                    ),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                hasToday ? Icons.verified_rounded : Icons.create_rounded,
                size: 22,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
