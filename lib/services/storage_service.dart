import 'package:shared_preferences/shared_preferences.dart';
import '../models/session.dart';

/// Persists and retrieves sessions using SharedPreferences.
class StorageService {
  static const _sessionsKey = 'speedex_sessions';

  /// Loads all saved sessions, newest first.
  Future<List<Session>> loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final sessions = Session.decodeList(raw);
      // Sort newest first
      sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
      return sessions;
    } catch (_) {
      return [];
    }
  }

  /// Appends [session] to the stored list.
  Future<void> saveSession(Session session) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await loadSessions();
    existing.insert(0, session); // newest first
    await prefs.setString(_sessionsKey, Session.encodeList(existing));
  }

  /// Removes the session with the given [id].
  Future<void> deleteSession(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await loadSessions();
    existing.removeWhere((s) => s.id == id);
    await prefs.setString(_sessionsKey, Session.encodeList(existing));
  }

  /// Clears all saved sessions.
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionsKey);
  }
}
