import 'package:intl/intl.dart';

/// Centralized date/time utilities for consistent formatting across the app.
class TimeUtil {
  TimeUtil._();

  // -------------------
  // Formats
  // -------------------

  /// ISO date format: `2026-04-15`
  static final DateFormat _isoDate = DateFormat('yyyy-MM-dd');

  /// ISO month prefix: `2026-04`
  static final DateFormat _isoMonth = DateFormat('yyyy-MM');

  /// Time (24h): `14:30`
  static final DateFormat _time24 = DateFormat('HH:mm');

  /// Short month + day: `Apr 15`
  static final DateFormat _shortMonthDay = DateFormat('MMM d', 'en_US');

  /// Readable date: `Apr 15, 2026`
  static final DateFormat _readableDate = DateFormat.yMMMd('en_US');

  /// Full date: `April 15, 2026`
  static final DateFormat _fullDate = DateFormat('MMMM d, yyyy', 'en_US');

  /// Full datetime display: `April 15, 2026 • 02:30 PM`
  static final DateFormat _fullDisplay = DateFormat('MMMM d, yyyy • hh:mm a', 'en_US');

  /// Full datetime display (24h): `April 15, 2026 • 14:30`
  static final DateFormat _fullDisplay24 = DateFormat('MMMM d, yyyy • HH:mm', 'en_US');

  /// ISO datetime (24h): `2026-04-15 14:30`
  static final DateFormat _isoDateTime24 = DateFormat('yyyy-MM-dd HH:mm', 'en_US');

  /// ISO datetime (12h): `2026-04-15 02:30PM`
  static final DateFormat _isoDateTime12 = DateFormat('yyyy-MM-dd hh:mma', 'en_US');

  /// Filename safe datetime: `2026-04-15_1430`
  static final DateFormat _filenameDateTime = DateFormat('yyyy-MM-dd_HHmm');

  // -------------------
  // Today & Now
  // -------------------

  /// Current [DateTime].
  static DateTime now() => DateTime.now();

  /// Today's date as ISO string: `2026-04-15`
  static String todayIso() => _isoDate.format(DateTime.now());

  /// Current month prefix: `2026-04`
  static String currentMonthPrefix() => _isoMonth.format(DateTime.now());

  /// Get current time formatted to 12h or 24h based on preference.
  static String getCurrentTimeFormatted({required bool use24Hour}) {
    final now = DateTime.now();
    if (use24Hour) {
      return _time24.format(now);
    } else {
      return DateFormat('hh:mm a', 'en_US').format(now);
    }
  }

  // -------------------
  // Formatting
  // -------------------

  /// Format a [DateTime] to ISO date: `2026-04-15`
  static String formatIsoDate(DateTime dt) => _isoDate.format(dt);

  /// Format a [DateTime] to short month + day: `Apr 15`
  static String formatShortMonthDay(DateTime dt) => _shortMonthDay.format(dt);

  /// Format a [DateTime] to readable date: `Apr 15, 2026`
  static String formatReadableDate(DateTime dt) => _readableDate.format(dt);

  /// Format a [DateTime] to full date: `April 15, 2026`
  static String formatFullDate(DateTime dt) => _fullDate.format(dt);

  /// Format a [DateTime] to full display: `April 15, 2026 • 02:30 PM`
  static String formatFullDisplay(DateTime dt, {bool use24Hour = false}) {
    if (use24Hour) {
      return _fullDisplay24.format(dt);
    } else {
      return _fullDisplay.format(dt);
    }
  }

  /// Format a [DateTime] for filenames: `2026-04-15_1430`
  static String formatFilename(DateTime dt) => _filenameDateTime.format(dt);

  /// Format a [DateTime] to standard display: `2026-04-15 14:30`
  static String formatDateTime(DateTime dt) => _isoDateTime24.format(dt);

  /// Format a time string to 12h or 24h format based on the preference.
  static String formatTimeString(String timeStr, {required bool use24Hour}) {
    if (timeStr.isEmpty) return '';
    try {
      final cleanTime = timeStr.trim();
      DateTime dt;
      if (cleanTime.toUpperCase().contains('AM') || cleanTime.toUpperCase().contains('PM')) {
        try {
          dt = DateFormat('hh:mm a', 'en_US').parse(cleanTime);
        } catch (_) {
          try {
            dt = DateFormat('hh:mma', 'en_US').parse(cleanTime.replaceAll(' ', ''));
          } catch (_) {
            try {
              dt = DateFormat('hh:mm:ss a', 'en_US').parse(cleanTime);
            } catch (_) {
              dt = DateFormat('h:mm a', 'en_US').parse(cleanTime);
            }
          }
        }
      } else {
        try {
          dt = DateFormat('HH:mm', 'en_US').parse(cleanTime);
        } catch (_) {
          try {
            dt = DateFormat('HH:mm:ss', 'en_US').parse(cleanTime);
          } catch (_) {
            dt = DateFormat('H:mm', 'en_US').parse(cleanTime);
          }
        }
      }
      
      if (use24Hour) {
        return DateFormat('HH:mm', 'en_US').format(dt);
      } else {
        return DateFormat('hh:mm a', 'en_US').format(dt);
      }
    } catch (_) {
      return timeStr;
    }
  }

  // -------------------
  // Parsing
  // -------------------

  /// Parse an ISO date string: `2026-04-15` → [DateTime]
  static DateTime parseIsoDate(String date) => DateTime.parse(date);

  /// Parse a date + time string, trying 24h first then 12h.
  static DateTime parseDateTime(String date, String time) {
    try {
      return _isoDateTime24.parse('$date $time');
    } catch (_) {
      final normalizedTime = time.replaceAll(' ', '');
      return _isoDateTime12.parse('$date $normalizedTime');
    }
  }

  // -------------------
  // Helpers
  // -------------------

  /// Check if a date string matches today's ISO date.
  static bool isToday(String dateIso) => dateIso == todayIso();

  /// First day of the current month.
  static DateTime firstOfCurrentMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  /// Last day of the current month.
  static DateTime lastOfCurrentMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 0);
  }

  /// Strip time from a [DateTime], returning midnight of that day.
  static DateTime stripTime(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}
