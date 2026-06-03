import 'package:shared_preferences/shared_preferences.dart';

/// Orden aleatorio elegido por el alumno solo para una tarea de clase (no comparte
/// con preferencias de práctica libre / código compartido).
class AssignmentRandomizePreferenceStore {
  static String _key(String assignmentId) =>
      'assignment_randomize_$assignmentId';

  Future<bool?> load(String assignmentId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _key(assignmentId);
    if (!prefs.containsKey(key)) {
      return null;
    }
    return prefs.getBool(key);
  }

  Future<void> save(String assignmentId, bool randomizeQuestions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(assignmentId), randomizeQuestions);
  }
}
