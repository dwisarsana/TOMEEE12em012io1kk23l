# Monetization Contract: AI Presentation

## 1. Subscription or IAP Type
- **Provider:** RevenueCat (purchases_flutter, purchases_ui_flutter).
- **Type:** Subscriptions (inferred from `subscriptionOptions` handling in `UpsellScreen`).
- **Store Configuration:** Supports Apple App Store, Google Play Store, and Amazon Appstore based on platform/environment.

## 2. Entitlement Structure
- **Entitlement Identifier:** `slides` (defined in `lib/src/constant.dart`).
- **Logic:** Users with active `slides` entitlement are considered **Premium**.
- **Offerings:** Fetches default/current offerings from RevenueCat.

## 3. Premium Gating Logic
- **Location:** `lib/ui/ai_generate.dart`
  - `_aiGenerateOutline()`: Checks `_readPremiumStatus()`. If `false`, shows `_showUpgradeSnack()` (Upgrade snackbar with link to Settings/Paywall).
  - `_aiImageForSlide()`: Checks `_readPremiumStatus()`. If `false`, shows `_showUpgradeSnack()`.
- **Implementation:**
  - `_readPremiumStatus()`:
    1. Fetches `CustomerInfo` from RevenueCat (`Purchases.getCustomerInfo()`).
    2. Checks if `entitlements.all['slides']?.isActive` is `true`.
    3. Caches the result in `SharedPreferences` under key `is_premium`.
    4. **Fallback:** If network fails, returns the cached `is_premium` value from `SharedPreferences`.

## 4. Free User Limitations
- **AI Features:**
  - Cannot generate presentation outlines via AI.
  - Cannot generate images via AI.
- **Allowed Actions:**
  - Can manually create/edit slides.
  - Can export presentations to PPTX.
  - Can view existing presentations.
  - Can use "Template" (manual/hardcoded) generation source.

## 5. Usage Caps
- **Status:** No explicit usage caps (e.g., "3 free slides") were found in the analyzed code.
- **Model:** Binary (Free vs. Premium). Free users have zero access to AI generation features.

## 6. Restore Purchase Flow
- **Mechanism:** Handled via RevenueCat's built-in UI (`RevenueCatUI.presentPaywall()`).
- **Callback:** `onRestoreCompleted` in `PaywallScreen` logs the result.
- **UI:** The standard RevenueCat paywall includes a "Restore Purchases" button/action.

## 7. Premium Check Timing
- **On Demand:** Checked immediately before executing a gated action (generating outline or image).
- **Initialization:** `InitialScreen` (if used as entry point) checks on `initState`.
- **Background:** `Purchases.addReadyForPromotedProductPurchaseListener` handles promoted purchases.

## 8. SDK Used
- **Core:** `purchases_flutter` (RevenueCat).
- **UI:** `purchases_ui_flutter` (RevenueCat Paywalls).
- **Version:** Specified in `pubspec.yaml` (e.g., `^8.1.0`).

## 9. Failure Scenarios
- **Network Error (Check Status):** Catches exception and falls back to locally cached `is_premium` status.
- **Purchase Error:**
  - `onPurchaseError` callback in `PaywallScreen`.
  - `try-catch` block in `UpsellScreen` handles `purchaseCancelledError`, `purchaseNotAllowedError`, `paymentPendingError`.
- **Missing Entitlement:** Returns `false`, triggering the upgrade UI.
