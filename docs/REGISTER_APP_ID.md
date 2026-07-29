# Registering an App ID (iOS)

An **App ID** on the Apple Developer portal must exactly match your app's
**Bundle Identifier** in Xcode. This project currently uses the placeholder
`com.example.fauth` — change it to your own reverse-domain identifier before
registering (for example `com.yourcompany.authenticator`).

---

## Prerequisites
- A paid **Apple Developer Program** membership ($99/year).
- **Admin** or **App Manager** role in your team.
- Your final **Bundle Identifier** decided (e.g. `com.yourcompany.authenticator`).

---

## Step 1 — Register the App ID (Identifier)
1. Go to https://developer.apple.com/account and sign in.
2. Open **Certificates, Identifiers & Profiles**.
3. Select **Identifiers** in the sidebar, then click the **＋** button.
4. Choose **App IDs** → **Continue**.
5. Select type **App** → **Continue**.
6. Fill in:
   - **Description**: `Authenticator` (internal name, letters/numbers/spaces only).
   - **Bundle ID**: select **Explicit** and enter your exact ID,
     e.g. `com.yourcompany.authenticator`.
     (Avoid **Wildcard** — In-App Purchase and Push require an explicit ID.)
7. Under **Capabilities**, enable only what the app uses. For this app the
   defaults are fine; **In-App Purchase** is enabled automatically. Enable
   others (e.g. Push Notifications, Associated Domains) only if you add them.
8. Click **Continue** → **Register**.

---

## Step 2 — Match the Bundle ID in Xcode
1. Open `ios/Runner.xcworkspace` in Xcode.
2. Select the **Runner** target → **Signing & Capabilities** tab.
3. Set **Bundle Identifier** to the same value you registered.
4. Choose your **Team** and enable **Automatically manage signing** (Xcode will
   create the needed provisioning profile).

> Note: this repo has a mismatched `DEVELOPMENT_TEAM` between Debug/Release
> configs (`JTZFXVLUSK` vs `UT43R29Q2P`). Pick one team so all configs match.

Alternatively, set it from the CLI / project file:
- File: `ios/Runner.xcodeproj/project.pbxproj`
- Replace all three `PRODUCT_BUNDLE_IDENTIFIER = com.example.fauth;` with your ID
  (and `com.example.fauth.RunnerTests` → `<yourID>.RunnerTests`).

---

## Step 3 — Create the app in App Store Connect
1. Go to https://appstoreconnect.apple.com → **My Apps** → **＋** → **New App**.
2. Select **iOS**, set the app **Name**, **Primary Language**, and pick the
   **Bundle ID** you registered in Step 1.
3. Enter an **SKU** (any unique internal string, e.g. `authenticator-001`).
4. Click **Create**.

---

## Step 4 — (If using subscriptions) Configure In-App Purchases
This app offers Weekly / Monthly / Yearly subscriptions (via Adapty), so:
1. In App Store Connect, open your app → **Subscriptions**.
2. Create a **Subscription Group**, then add each product with its own
   **Product ID** (e.g. `com.yourcompany.authenticator.weekly`).
3. Set pricing and the free trial (introductory offer).
4. Map these Product IDs in your Adapty dashboard / paywall configuration.

---

## Verify
- `open ios/Runner.xcworkspace` → Signing shows a green checkmark (no errors).
- Build to a device: `flutter run --release` (or Product ▸ Archive for upload).

---

### Quick reference
| Item              | Value (example)                        |
|-------------------|----------------------------------------|
| Bundle ID / App ID| `com.yourcompany.authenticator`        |
| Description       | Authenticator                          |
| SKU               | `authenticator-001`                    |
| IAP product IDs   | `...authenticator.weekly` / `.monthly` / `.yearly` |
