import 'package:shared_preferences/shared_preferences.dart';

enum TutorialMode { freeDrawing, traceDrawing, coloring }

class TutorialService {
  static const _prefix = 'tutorial_seen_';

  static String _key(TutorialMode mode) => '$_prefix${mode.name}';

  static Future<bool> isFirstTime(TutorialMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_key(mode)) ?? false);
  }

  static Future<void> markSeen(TutorialMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(mode), true);
  }
}
