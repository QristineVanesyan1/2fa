import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// App Store / rate-&-review integration.
///
/// Two entry points:
///  * [requestReview] — shows Apple's native in-app rating sheet
///    (`SKStoreReviewController`). Apple decides whether it actually appears
///    and silently throttles it (max ~3 prompts per 365 days per device), so it
///    must never be the only path and must never block the UI.
///  * [openStoreListing] — deep-links to the App Store review composer, which
///    always works. Used as a fallback and for the explicit "Rate Us" row.
class ReviewService {
  ReviewService._();

  /// Numeric App Store ID (App Store Connect ▸ App Information ▸ Apple ID).
  static const String appStoreId = '6790424054';

  /// Public marketing URL for the app (also used by "Share App").
  static const String appStoreUrl = 'https://apps.apple.com/app/id$appStoreId';

  /// Deep link that opens the App Store page with the review composer open.
  static const String writeReviewUrl =
      'https://apps.apple.com/app/id$appStoreId?action=write-review';

  static final InAppReview _inAppReview = InAppReview.instance;

  // ---------------------------------------------------------------------------
  // Explicit user action ("Rate Us" in Settings)
  // ---------------------------------------------------------------------------

  /// Called when the user taps "Rate Us".
  ///
  /// Tries the native sheet first (nicest UX, no app switch); if it is
  /// unavailable — e.g. the OS is throttling it or we're on a simulator — falls
  /// back to opening the App Store review composer.
  ///
  /// Returns `true` when something was shown/opened.
  static Future<bool> rateApp() async {
    try {
      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
        await _markPrompted();
        return true;
      }
    } catch (_) {
      // Fall through to the store listing.
    }
    return openStoreListing();
  }

  /// Opens the App Store page with the "Write a Review" sheet.
  static Future<bool> openStoreListing() async {
    try {
      // `openStoreListing` uses the native StoreKit product page when possible.
      await _inAppReview.openStoreListing(appStoreId: appStoreId);
      return true;
    } catch (_) {
      return launchUrl(
        Uri.parse(writeReviewUrl),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Automatic prompt (call from a "happy moment", e.g. after adding a code)
  // ---------------------------------------------------------------------------

  static const String _kLaunchCount = 'review_launch_count';
  static const String _kLastPromptMs = 'review_last_prompt_ms';

  /// Minimum number of significant actions before the first automatic prompt.
  static const int minActionsBeforePrompt = 3;

  /// Minimum time between automatic prompts.
  static const Duration minInterval = Duration(days: 90);

  /// Records a "significant action" (app launch, code added, password saved…).
  static Future<void> registerAction() async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(_kLaunchCount) ?? 0) + 1;
    await prefs.setInt(_kLaunchCount, count);
  }

  /// Requests the native rating sheet if our own heuristics allow it.
  ///
  /// Never opens the App Store as a fallback — an unsolicited app switch would
  /// be hostile. Safe to call often; it no-ops when the conditions aren't met.
  static Future<void> maybeRequestReview() async {
    final prefs = await SharedPreferences.getInstance();

    final count = prefs.getInt(_kLaunchCount) ?? 0;
    if (count < minActionsBeforePrompt) return;

    final lastMs = prefs.getInt(_kLastPromptMs);
    if (lastMs != null) {
      final since = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(lastMs),
      );
      if (since < minInterval) return;
    }

    try {
      if (!await _inAppReview.isAvailable()) return;
      await _inAppReview.requestReview();
      await _markPrompted();
    } catch (_) {
      // Ignore — rating is never critical.
    }
  }

  static Future<void> _markPrompted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLastPromptMs, DateTime.now().millisecondsSinceEpoch);
  }
}
