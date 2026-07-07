import 'package:shared_preferences/shared_preferences.dart';

/// Persists the app-lock security settings (passcode + Face ID) and exposes
/// helpers so the startup flow can decide whether the app needs to be unlocked.
///
/// Kept as an interface so the startup flow can be unit-tested with an
/// in-memory fake instead of touching platform channels.
abstract class AppLockService {
  /// Whether a passcode has been set and passcode lock is enabled.
  Future<bool> isPasscodeEnabled();

  /// Whether Face ID / biometric unlock is enabled.
  Future<bool> isFaceIdEnabled();

  /// The stored passcode (or null if none is set).
  Future<String?> getPasscode();

  /// Enables passcode lock and stores the given [passcode].
  Future<void> setPasscode(String passcode);

  /// Disables passcode lock (and clears the stored passcode). Also disables
  /// Face ID since it depends on a passcode being set.
  Future<void> clearPasscode();

  /// Enables/disables Face ID unlock.
  Future<void> setFaceIdEnabled(bool enabled);

  /// Whether the app should present a lock screen on launch.
  Future<bool> isLockEnabled() async {
    return await isPasscodeEnabled() || await isFaceIdEnabled();
  }
}

/// Default [AppLockService] backed by [SharedPreferences].
class SharedPrefsAppLockService extends AppLockService {
  SharedPrefsAppLockService();

  static const String _passcodeEnabledKey = 'app_lock_passcode_enabled_v1';
  static const String _passcodeKey = 'app_lock_passcode_v1';
  static const String _faceIdKey = 'app_lock_face_id_v1';

  @override
  Future<bool> isPasscodeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_passcodeEnabledKey) ?? false;
  }

  @override
  Future<bool> isFaceIdEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_faceIdKey) ?? false;
  }

  @override
  Future<String?> getPasscode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_passcodeKey);
  }

  @override
  Future<void> setPasscode(String passcode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_passcodeKey, passcode);
    await prefs.setBool(_passcodeEnabledKey, true);
  }

  @override
  Future<void> clearPasscode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_passcodeKey);
    await prefs.setBool(_passcodeEnabledKey, false);
    // Face ID depends on the passcode, so disable it too.
    await prefs.setBool(_faceIdKey, false);
  }

  @override
  Future<void> setFaceIdEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_faceIdKey, enabled);
  }
}

/// Simple in-memory [AppLockService] useful for tests.
class InMemoryAppLockService extends AppLockService {
  InMemoryAppLockService({
    this.passcode,
    this.passcodeEnabled = false,
    this.faceIdEnabled = false,
  });

  String? passcode;
  bool passcodeEnabled;
  bool faceIdEnabled;

  @override
  Future<bool> isPasscodeEnabled() async => passcodeEnabled;

  @override
  Future<bool> isFaceIdEnabled() async => faceIdEnabled;

  @override
  Future<String?> getPasscode() async => passcode;

  @override
  Future<void> setPasscode(String value) async {
    passcode = value;
    passcodeEnabled = true;
  }

  @override
  Future<void> clearPasscode() async {
    passcode = null;
    passcodeEnabled = false;
    faceIdEnabled = false;
  }

  @override
  Future<void> setFaceIdEnabled(bool enabled) async => faceIdEnabled = enabled;
}
