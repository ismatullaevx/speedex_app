import 'package:flutter/material.dart';

import '../models/session.dart';
import '../services/storage_service.dart';

/// Manages the list of saved sessions for the History screen.
class HistoryProvider extends ChangeNotifier {
  final StorageService _storage;

  HistoryProvider({required this._storage});

  List<Session> get sessions => List.unmodifiable(_sessions);
  bool get isLoading => _isLoading;

  List<Session> _sessions = [];
  bool _isLoading = false;

  /// Load sessions from storage. Call this when the History tab is shown.
  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    _sessions = await _storage.loadSessions();
    _isLoading = false;
    notifyListeners();
  }

  /// Reload sessions — convenient alias used after a session is saved.
  Future<void> refresh() => load();

  /// Delete a session by its ID and refresh the list.
  Future<void> deleteSession(String id) async {
    await _storage.deleteSession(id);
    await load();
  }

  /// Delete all sessions.
  Future<void> clearAll() async {
    await _storage.clearAll();
    _sessions = [];
    notifyListeners();
  }
}
