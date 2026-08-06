import 'dart:async';

import 'package:flutter/material.dart';

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

  StreamSubscription<PositionUpdate>? _positionSub;
  Timer? _ticker;
  DateTime? _sessionStart;

  // Accumulators for average speed calculation
  double _totalDistance = 0.0;
  double _totalSpeedReadings = 0.0;
  int _speedSamples = 0;

  // ── Start tracking ────────────────────────────────────────────────────────
  Future<void> startTracking() async {
    if (_isTracking) return;

    _errorMessage = null;
    _stats = SessionStats.zero;
    _totalDistance = 0.0;
    _totalSpeedReadings = 0.0;
    _speedSamples = 0;
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
    _positionSub =
        _locationService.stream!.listen(_onPositionUpdate);

    // Tick every second for the timer display
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final elapsed = DateTime.now().difference(_sessionStart!).inSeconds;
      _stats = _stats.copyWith(elapsedSeconds: elapsed);
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
  void _onPositionUpdate(PositionUpdate update) {
    _totalDistance += update.distanceDelta;

    final speed = update.speedKmh;
    _speedSamples++;
    _totalSpeedReadings += speed;
    final avg = _speedSamples > 0 ? _totalSpeedReadings / _speedSamples : 0.0;

    _stats = _stats.copyWith(
      currentSpeedKmh: speed,
      maxSpeedKmh:
          speed > _stats.maxSpeedKmh ? speed : _stats.maxSpeedKmh,
      avgSpeedKmh: avg,
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
