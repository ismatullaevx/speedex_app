import 'dart:convert';

/// Represents a completed tracking session saved to local storage.
class Session {
  final String id;
  final DateTime startTime;
  final int durationSeconds;
  final double maxSpeedKmh;
  final double avgSpeedKmh;
  final double distanceMeters;

  const Session({
    required this.id,
    required this.startTime,
    required this.durationSeconds,
    required this.maxSpeedKmh,
    required this.avgSpeedKmh,
    required this.distanceMeters,
  });

  /// Serialize to a JSON-compatible map for SharedPreferences storage.
  Map<String, dynamic> toJson() => {
        'id': id,
        'startTime': startTime.toIso8601String(),
        'durationSeconds': durationSeconds,
        'maxSpeedKmh': maxSpeedKmh,
        'avgSpeedKmh': avgSpeedKmh,
        'distanceMeters': distanceMeters,
      };

  /// Deserialize from a JSON map read from SharedPreferences.
  factory Session.fromJson(Map<String, dynamic> json) => Session(
        id: json['id'] as String,
        startTime: DateTime.parse(json['startTime'] as String),
        durationSeconds: json['durationSeconds'] as int,
        maxSpeedKmh: (json['maxSpeedKmh'] as num).toDouble(),
        avgSpeedKmh: (json['avgSpeedKmh'] as num).toDouble(),
        distanceMeters: (json['distanceMeters'] as num).toDouble(),
      );

  /// Encode a list of sessions to a JSON string.
  static String encodeList(List<Session> sessions) =>
      jsonEncode(sessions.map((s) => s.toJson()).toList());

  /// Decode a JSON string back into a list of sessions.
  static List<Session> decodeList(String raw) {
    final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => Session.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
