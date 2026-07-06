import 'package:shared_preferences/shared_preferences.dart';

/// Abstraction over onboarding-completion persistence.
///
/// Kept as an interface so the startup flow can be unit-tested with an
/// in-memory fake instead of touching platform channels.
abstract class OnboardingService {
  /// Whether the user has already finished onboarding.
  Future<bool> isOnboardingComplete();

  /// Persists the fact that onboarding has been completed.
  Future<void> setOnboardingComplete();
}

/// Default [OnboardingService] backed by [SharedPreferences].
class SharedPrefsOnboardingService implements OnboardingService {
  SharedPrefsOnboardingService();

  static const String _key = 'onboarding_complete_v1';

  @override
  Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  @override
  Future<void> setOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}

/// Simple in-memory [OnboardingService] useful for tests.
class InMemoryOnboardingService implements OnboardingService {
  InMemoryOnboardingService({this.complete = false});

  bool complete;

  @override
  Future<bool> isOnboardingComplete() async => complete;

  @override
  Future<void> setOnboardingComplete() async => complete = true;
}
