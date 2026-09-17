import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/session.dart';
import '../models/session_stats.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';

/// Tracks the state of the current GPS session.
///
/// Manages the GPS subscription via [LocationService], drives the
/// elapsed-time ticker, accumulates stats, and persists completed
/// sessions through [StorageService].
class SessionProvider extends ChangeNotifier {
  final LocationService _locationService;
  final StorageService _storageService;

  SessionProvider({
    required this._locationService,
    required this._storageService,
  });

  // ── Public state ─────────────────────────────────────────────────────────
  bool get isTracking => _isTracking;
  SessionStats get stats => _stats;
  String? get errorMessage => _errorMessage;
  String? get lastSavedSessionId => _lastSavedSessionId;

  // ── Private ──────────────────────────────────────────────────────────────
  bool _isTracking = false;
  SessionStats _stats = SessionStats.zero;
  String? _errorMessage;
  String? _lastSavedSessionId;

  StreamSubscription<Position>? _positionSub;
  Timer? _ticker;
  DateTime? _sessionStart;

  // Accumulators for GPS tracking
  Position? _lastValidPosition;
  double _totalDistance = 0.0;
  int _movingTimeSeconds = 0;

  // ── Start tracking ────────────────────────────────────────────────────────
  Future<void> startTracking() async {
    if (_isTracking) return;

    _errorMessage = null;
    _stats = SessionStats.zero;
    _totalDistance = 0.0;
    _movingTimeSeconds = 0;
    _lastValidPosition = null;
    _sessionStart = DateTime.now();

    final error = await _locationService.startTracking();
    if (error != null) {
      _errorMessage = error;
      notifyListeners();
      return;
    }

    _isTracking = true;
    notifyListeners();

    // Subscribe to GPS updates
    _positionSub = _locationService.stream!.listen(_onPositionUpdate);

    // Tick every second for the timer display and moving time accumulation
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final elapsed = DateTime.now().difference(_sessionStart!).inSeconds;

      // Accumulate moving time when the user is moving (current speed > 0.8 km/h).
      // This prevents stationary GPS drift from bloating moving time.
      if (_stats.currentSpeedKmh > 0.8) {
        _movingTimeSeconds++;
      }

      // Recalculate average speed as total distance divided by total moving time.
      final avgSpeed = _movingTimeSeconds > 0
          ? (_totalDistance * 3.6) / _movingTimeSeconds
          : 0.0;

      _stats = _stats.copyWith(
        elapsedSeconds: elapsed,
        avgSpeedKmh: avgSpeed,
      );
      notifyListeners();
    });
  }

  // ── Stop tracking ─────────────────────────────────────────────────────────
  Future<void> stopTracking() async {
    if (!_isTracking) return;

    _ticker?.cancel();
    _ticker = null;
    await _positionSub?.cancel();
    _positionSub = null;
    await _locationService.stopTracking();

    _isTracking = false;
    notifyListeners();

    // Save the session if there's meaningful data
    if (_stats.elapsedSeconds > 0) {
      final session = Session(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        startTime: _sessionStart ?? DateTime.now(),
        durationSeconds: _stats.elapsedSeconds,
        maxSpeedKmh: _stats.maxSpeedKmh,
        avgSpeedKmh: _stats.avgSpeedKmh,
        distanceMeters: _stats.distanceMeters,
      );
      await _storageService.saveSession(session);
      _lastSavedSessionId = session.id;
      notifyListeners();
    }
  }

  // ── GPS position handler ──────────────────────────────────────────────────
  void _onPositionUpdate(Position position) {
    // 1. Calculate raw speed in km/h directly from position.speed
    final rawSpeed = position.speed;
    double speedKmh = 0.0;
    if (rawSpeed > 0 && !rawSpeed.isNaN && rawSpeed.isFinite) {
      speedKmh = rawSpeed * 3.6;
    }

    // 2. Debug logging for every received GPS position
    print(
      'GPS: speed=${position.speed}, '
      'accuracy=${position.accuracy}, '
      'timestamp=${position.timestamp}, '
      'calculatedSpeed=${speedKmh.toStringAsFixed(2)} km/h'
    );

    // 3. Current speed updates immediately from latest valid GPS reading without buffer/moving average delay
    // Stationary threshold (< 0.5 km/h) suppresses stationary noise jitter
    final currentSpeed = speedKmh < 0.5 ? 0.0 : speedKmh;

    // 4. Distance calculation:
    // Accumulate distance using Geolocator.distanceBetween only when accuracy is reasonable (<= 50m)
    final bool isAccuracyAcceptableForDistance = position.accuracy <= 50.0;
    if (_lastValidPosition != null && isAccuracyAcceptableForDistance) {
      final distanceDelta = Geolocator.distanceBetween(
        _lastValidPosition!.latitude,
        _lastValidPosition!.longitude,
        position.latitude,
        position.longitude,
      );

      // Prevent GPS jitter from inflating distance when stationary
      if (currentSpeed > 0.5) {
        _totalDistance += distanceDelta;
      }
    }

    if (isAccuracyAcceptableForDistance) {
      _lastValidPosition = position;
    }

    // 5. Maximum speed tracking (independent from current speed display)
    final double maxSpeed = math.max(
      _stats.maxSpeedKmh,
      isAccuracyAcceptableForDistance ? currentSpeed : _stats.maxSpeedKmh,
    );

    // 6. Average speed calculation (total distance divided by total moving time)
    final avgSpeed = _movingTimeSeconds > 0
        ? (_totalDistance * 3.6) / _movingTimeSeconds
        : 0.0;

    // 7. Update stats and notify listeners immediately for real-time UI rebuild
    _stats = _stats.copyWith(
      currentSpeedKmh: currentSpeed,
      maxSpeedKmh: maxSpeed,
      avgSpeedKmh: avgSpeed,
      distanceMeters: _totalDistance,
    );
    notifyListeners();
  }

  // ── Clear error ────────────────────────────────────────────────────────────
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _positionSub?.cancel();
    _locationService.dispose();
    super.dispose();
  }
}
