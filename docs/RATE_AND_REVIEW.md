# Rate & Review (iOS App Store)

## What was set up
- Package: `in_app_review: ^2.0.9` (uses `SKStoreReviewController` on iOS).
- Service: `lib/services/review_service.dart`
  - `ReviewService.appStoreId = '6790424054'`
  - `appStoreUrl` → `https://apps.apple.com/app/id6790424054`
  - `writeReviewUrl` → `...?action=write-review`
  - `rateApp()` — native rating sheet, falls back to the App Store review page.
  - `registerAction()` / `maybeRequestReview()` — throttled automatic prompt.
- Settings ▸ **Rate Us** now calls `rateApp()`.
- Settings ▸ **Share App** now uses `ReviewService.appStoreUrl`.
- After successfully adding a 2FA code (`AddManuallyScreen._save`) the app
  registers a "happy moment" and may show the native prompt.

## Throttling rules
Ours: at least **3** significant actions, and at most one prompt per **90 days**
(stored in `SharedPreferences`: `review_launch_count`, `review_last_prompt_ms`).
Apple's: max ~3 prompts per app per 365 days per device — it can silently do
nothing, which is expected and must never be treated as an error.

## Testing
- The native sheet does **not** appear reliably in Debug on a simulator; it also
  never submits a real review in TestFlight (the sheet shows but is inert).
- To verify the fallback path, call `ReviewService.openStoreListing()` — it opens
  the real App Store page (only works once the app is published or in review).
- Reset local throttling during development:
  delete the app, or clear the two `SharedPreferences` keys above.

## Notes / requirements
- No `Info.plist` entries or capabilities are required for review prompts.
- Apple guideline 1.1.7 / HIG: never beg for ratings, never gate features behind
  a review, never show a custom "rate us?" dialog before the native sheet, and
  don't call the prompt from a button-less automatic flow more than the limits
  above. The current setup complies.
- If the App ID ever changes, update `ReviewService.appStoreId` only.
