# Age Rating — App Store Connect

How to fill in the Age Rating questionnaire for **Authenticator: 2FA Codes**.

## Where to find it

1. Sign in to [App Store Connect](https://appstoreconnect.apple.com) → **My Apps** → Authenticator.
2. Left sidebar → **General** → **Age Rating** (in older layouts it's on the version
   page under *App Information*).
3. Click **Edit** (pencil) next to *Age Rating*, answer every question, then **Save**.

Age Rating lives on **App Information**, not on a specific version — it applies to
the whole app and can be edited without submitting a new build (though changes
made while a version is *In Review* may require re-review).

## The one question that decides everything: web access

This app contains a **real in-app browser** (`lib/screens/browser_screen.dart`):
a `WebView` with `JavaScriptMode.unrestricted` that loads any URL the user types
and falls back to a Google search. There is **no** content filtering, allow-list,
or parental control.

That means you must answer **Yes** to:

> **Unrestricted Web Access** — Does your app contain unrestricted web access,
> such as with an embedded browser?

Answering Yes forces the rating to Apple's highest tier — **18+** (previously
17+) — regardless of every other answer. Answering **No** here would be a
misrepresentation and is a common cause of rejection under App Review Guideline
2.3 (Accurate Metadata); Apple's reviewers open the Browser tab and try it.

If an 18+ rating is unacceptable for your marketing, the *only* legitimate fix is
to change the app, not the answer. Options:

- **Remove the browser tab** entirely (the app is still a strong 2FA + password
  manager) → then answer No and you land at 4+.
- **Restrict the WebView** to a fixed allow-list of domains via
  `NavigationDelegate.onNavigationRequest` (return
  `NavigationDecision.prevent` for anything not allow-listed), and drop the
  free-form URL bar / Google search. Restricted access = answer No.

Both are code changes — tell me if you want one and I'll implement it.

## Recommended answers for every question

Apple's current questionnaire (2025 layout, ratings 4+ / 9+ / 13+ / 16+ / 18+).
Answer these exactly:

| Question | Answer |
| --- | --- |
| Cartoon or Fantasy Violence | None |
| Realistic Violence | None |
| Prolonged Graphic or Sadistic Realistic Violence | None |
| Profanity or Crude Humor | None |
| Mature/Suggestive Themes | None |
| Horror/Fear Themes | None |
| Medical/Treatment Information | None |
| Alcohol, Tobacco, or Drug Use or References | None |
| Sexual Content or Nudity | None |
| Graphic Sexual Content and Nudity | None |
| Simulated Gambling | None |
| Contests | None |
| **Unrestricted Web Access** | **Yes** |
| Gambling (real money) | No |
| Lotteries or raffles | No |
| In-app controls to restrict access to user-generated / web content (parental controls) | No |
| Does your app contain user-generated content? | No |
| Does your app contain messaging or chat? | No |
| Does your app allow users to share content, location, or personal info? | No |
| Age Assurance / age verification built in? | No |
| Made for Kids (Kids Category) | **No** — never select this; an app with a browser cannot be in the Kids category |

Rationale for the "No"s: all data is stored locally and encrypted, there is no
account system, no server, no chat, no sharing of user content, and no ads or
third-party tracking SDKs. The only external network traffic is the WebView
itself and the Adapty purchase/paywall calls.

## After saving

- Confirm the badge shown on the App Information page reads **18+** and that the
  same rating appears in the *Ratings* section of the version you're submitting.
- Update `APP_DESCRIPTION.md` if you keep the browser: the "Age Rating: 4+" note
  there is only correct for a build **without** unrestricted web access.
- The rating is per-app and applies to all territories; some regions display a
  locally mapped equivalent (e.g. Korea, Brazil) automatically — nothing extra
  to fill in.
