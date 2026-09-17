import 'dart:async';

import 'package:flutter/foundation.dart';
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

    late final LocationSettings settings;
    if (defaultTargetPlatform == TargetPlatform.android) {
      settings = AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        intervalDuration: const Duration(seconds: 1),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      settings = AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        activityType: ActivityType.fitness,
        pauseLocationUpdatesAutomatically: false,
      );
    } else {
      settings = const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      );
    }

    _positionSub = Geolocator.getPositionStream(locationSettings: settings)
        .listen((position) {
      print(
        'GPS: speed=${position.speed}, '
        'accuracy=${position.accuracy}, '
        'timestamp=${position.timestamp}'
      );
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
