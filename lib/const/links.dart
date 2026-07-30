/// External links shown in the app (legal documents, support, etc.).
///
/// Kept in one place so the Settings screen and the paywall can never drift
/// apart — App Review checks that both surfaces point at the same documents.
class AppLinks {
  const AppLinks._();

  /// Terms of Use document.
  static const String termsOfUse =
      'https://docs.google.com/document/d/10L0gWWxdzUmiQaoBLqHNI5nWMoUr1F5A0t645ZhEAt0/edit?tab=t.0';

  /// Privacy Policy document.
  static const String privacyPolicy =
      'https://docs.google.com/document/d/10L0gWWxdzUmiQaoBLqHNI5nWMoUr1F5A0t645ZhEAt0/edit?tab=t.0';
}
