/// Live tracking statistics updated in real-time during a session.
class SessionStats {
  final double currentSpeedKmh;
  final double maxSpeedKmh;
  final double avgSpeedKmh;
  final double distanceMeters;
  final int elapsedSeconds;

  const SessionStats({
    this.currentSpeedKmh = 0.0,
    this.maxSpeedKmh = 0.0,
    this.avgSpeedKmh = 0.0,
    this.distanceMeters = 0.0,
    this.elapsedSeconds = 0,
  });

  /// Returns a copy with updated fields.
  SessionStats copyWith({
    double? currentSpeedKmh,
    double? maxSpeedKmh,
    double? avgSpeedKmh,
    double? distanceMeters,
    int? elapsedSeconds,
  }) =>
      SessionStats(
        currentSpeedKmh: currentSpeedKmh ?? this.currentSpeedKmh,
        maxSpeedKmh: maxSpeedKmh ?? this.maxSpeedKmh,
        avgSpeedKmh: avgSpeedKmh ?? this.avgSpeedKmh,
        distanceMeters: distanceMeters ?? this.distanceMeters,
        elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      );

  static const SessionStats zero = SessionStats();
}
