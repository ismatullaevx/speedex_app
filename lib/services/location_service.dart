import 'dart:async';

import 'package:geolocator/geolocator.dart';

/// Manages the GPS subscription and emits speed/position updates.
///
/// Call [startTracking] to begin receiving [PositionUpdate] events via [stream].
/// Call [stopTracking] to cancel the subscription.
class LocationService {
  StreamController<PositionUpdate>? _controller;
  StreamSubscription<Position>? _positionSub;
  Position? _lastPosition;

  /// Broadcast stream of position updates. Closes when [stopTracking] is called.
  Stream<PositionUpdate>? get stream => _controller?.stream;

  /// Requests permission and starts the GPS stream.
  /// Returns an error message string if permission is denied; null on success.
  Future<String?> startTracking() async {
    // ── Permission check ──────────────────────────────────────────────────
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return 'Location permission denied. Please enable it in Settings.';
    }

    // ── Verify GPS is enabled ────────────────────────────────────────────
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return 'Location services are disabled. Please enable GPS.';
    }

    _controller = StreamController<PositionUpdate>.broadcast();
    _lastPosition = null;

    const settings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0, // receive every update
    );

    _positionSub = Geolocator.getPositionStream(locationSettings: settings)
        .listen((position) {
      double distanceDelta = 0.0;
      if (_lastPosition != null) {
        distanceDelta = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );
      }
      _lastPosition = position;

      // speed is in m/s — convert to km/h
      final speedKmh =
          (position.speed < 0 ? 0.0 : position.speed) * 3.6;

      _controller?.add(PositionUpdate(
        speedKmh: speedKmh,
        distanceDelta: distanceDelta,
        position: position,
      ));
    });

    return null; // success
  }

  /// Stops the GPS stream and closes the controller.
  Future<void> stopTracking() async {
    await _positionSub?.cancel();
    _positionSub = null;
    await _controller?.close();
    _controller = null;
    _lastPosition = null;
  }

  void dispose() {
    stopTracking();
  }
}

/// Value object emitted on every GPS position update.
class PositionUpdate {
  final double speedKmh;
  final double distanceDelta; // meters since last update
  final Position position;

  const PositionUpdate({
    required this.speedKmh,
    required this.distanceDelta,
    required this.position,
  });
}
