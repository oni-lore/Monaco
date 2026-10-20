import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/dm_wheel.dart';

/// Provides persisted DM Quick-Access wheel mode (Left / Right / Off).
class DMWheelModeProvider extends ChangeNotifier {
  static const String _prefsKey = 'dm_quick_access_mode';

  DMWheelMode _mode = DMWheelMode.right;

  DMWheelMode get mode => _mode;

  DMWheelModeProvider() {
    _loadMode();
  }

  Future<void> _loadMode() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    _mode = raw != null ? DMWheelMode.values.firstWhere(
      (e) => e.toString() == 'DMWheelMode.$raw',
      orElse: () => DMWheelMode.right,
    ) : DMWheelMode.right;
    notifyListeners();
  }

  Future<void> setMode(DMWheelMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, mode.toString().split('.').last);
    notifyListeners();
  }
}
