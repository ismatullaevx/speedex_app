import 'package:intl/intl.dart';

/// Utility functions for formatting speed, distance, and time values.
class Formatter {
  Formatter._();

  /// Formats speed in km/h, showing one decimal place.
  static String speed(double kmh) => kmh.toStringAsFixed(1);

  /// Formats distance: shows meters below 1 km, otherwise km.
  static String distance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    }
    return '${(meters / 1000).toStringAsFixed(2)} km';
  }

  /// Formats elapsed seconds into HH:MM:SS.
  static String duration(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// Formats a [DateTime] to a readable date string: "Aug 6, 2026".
  static String date(DateTime dt) => DateFormat('MMM d, yyyy').format(dt);

  /// Formats a [DateTime] to time: "16:18".
  static String time(DateTime dt) => DateFormat('HH:mm').format(dt);

  /// Full date + time for session detail: "Aug 6, 2026 · 16:18".
  static String dateTime(DateTime dt) =>
      '${date(dt)} · ${time(dt)}';
}
