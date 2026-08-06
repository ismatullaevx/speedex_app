import 'dart:async';

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

  // Accumulators and buffers for GPS tracking
  Position? _lastValidPosition;
  double _lastSpeedKmh = 0.0;
  final List<double> _speedBuffer = [];
  double _totalDistance = 0.0;
  int _movingTimeSeconds = 0;

  // ── Start tracking ────────────────────────────────────────────────────────
  Future<void> startTracking() async {
    if (_isTracking) return;

    _errorMessage = null;
    _stats = SessionStats.zero;
    _totalDistance = 0.0;
    _movingTimeSeconds = 0;
    _speedBuffer.clear();
    _lastValidPosition = null;
    _lastSpeedKmh = 0.0;
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

      // Accumulate moving time when the user is moving (smoothed speed > 0.8 km/h).
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
    // 1. Verify accuracy is good.
    // If accuracy is poor (error radius > 20 meters), we treat speed as 0.0,
    // skip distance calculation, and add 0.0 to the smoothing buffer.
    final bool isAccuracyPoor = position.accuracy > 20.0;

    double rawSpeedKmh = 0.0;

    if (isAccuracyPoor) {
      rawSpeedKmh = 0.0;
    } else {
      // 2. Handle invalid speed reports (negative, NaN, infinite)
      final rawSpeed = position.speed;
      if (rawSpeed < 0 || rawSpeed.isNaN || !rawSpeed.isFinite) {
        rawSpeedKmh = 0.0;
      } else {
        // Convert from m/s to km/h
        rawSpeedKmh = rawSpeed * 3.6;
      }
    }

    // 3. Ignore GPS spikes and unrealistic jumps.
    // If acceleration exceeds 50.0 km/h per second (approx 13.9 m/s²), it is treated as a GPS spike.
    if (_lastValidPosition != null && !isAccuracyPoor) {
      final dt = position.timestamp.difference(_lastValidPosition!.timestamp).inMilliseconds / 1000.0;
      if (dt >= 0.5) {
        final acceleration = (rawSpeedKmh - _lastSpeedKmh).abs() / dt;
        if (acceleration > 50.0) {
          // Ignore this update entirely as it represents an unrealistic jump
          return;
        }
      }
    }

    // 4. Calculate distance using distance between consecutive valid coordinates
    if (_lastValidPosition != null && !isAccuracyPoor) {
      final distanceDelta = Geolocator.distanceBetween(
        _lastValidPosition!.latitude,
        _lastValidPosition!.longitude,
        position.latitude,
        position.longitude,
      );

      // Prevent GPS jitter from inflating distance when stationary
      if (rawSpeedKmh > 0.5) {
        _totalDistance += distanceDelta;
      }
    }

    // Update references for next calculation
    if (!isAccuracyPoor) {
      _lastValidPosition = position;
      _lastSpeedKmh = rawSpeedKmh;
    }

    // 5. Smooth the speed using a moving average of the last 4 readings (approx. 4 seconds)
    _speedBuffer.add(rawSpeedKmh);
    if (_speedBuffer.length > 4) {
      _speedBuffer.removeAt(0);
    }
    final smoothedSpeed = _speedBuffer.reduce((a, b) => a + b) / _speedBuffer.length;

    // 6. Update max speed only when the new speed is greater than the previous maximum
    final maxSpeed = smoothedSpeed > _stats.maxSpeedKmh ? smoothedSpeed : _stats.maxSpeedKmh;

    // 7. Calculate average speed as total distance divided by total moving time
    final avgSpeed = _movingTimeSeconds > 0
        ? (_totalDistance * 3.6) / _movingTimeSeconds
        : 0.0;

    _stats = _stats.copyWith(
      currentSpeedKmh: smoothedSpeed,
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
