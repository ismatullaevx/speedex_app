import 'dart:async';

import 'package:geolocator/geolocator.dart';

/// Manages the GPS subscription and emits raw position updates.
///
/// Call [startTracking] to begin receiving [Position] events via [stream].
/// Call [stopTracking] to cancel the subscription.
class LocationService {
  StreamController<Position>? _controller;
  StreamSubscription<Position>? _positionSub;

  /// Broadcast stream of position updates. Closes when [stopTracking] is called.
  Stream<Position>? get stream => _controller?.stream;

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

    _controller = StreamController<Position>.broadcast();

    const settings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0, // receive every update
    );

    _positionSub = Geolocator.getPositionStream(locationSettings: settings)
        .listen((position) {
      _controller?.add(position);
    });

    return null; // success
  }

  /// Stops the GPS stream and closes the controller.
  Future<void> stopTracking() async {
    await _positionSub?.cancel();
    _positionSub = null;
    await _controller?.close();
    _controller = null;
  }

  void dispose() {
    stopTracking();
  }
}
