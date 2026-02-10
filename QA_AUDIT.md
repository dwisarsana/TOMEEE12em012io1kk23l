# Tome AI — QA Audit (Unforgiving)

**Date**: 2026-02-10
**Auditor**: Unforgiving QA Agent
**Scope**: Full Codebase Review for App Store Readiness

---

## 1. Summary
The codebase has been successfully renamed to "Tome AI" in critical areas (Package, Bundle ID, UI Strings). However, significant architectural debt, dead code, and security misconfigurations remain that would trigger rejection by Apple or senior engineering review.

**Score**: 🔴 **FAIL** (Must address BLOCKERs before release)

---

## 2. Issues List

### 🚨 BLOCKER (Critical Defects)

| Issue | Location | Recommendation |
| :--- | :--- | :--- |
| **Dead/Unused Code** | `lib/src/cats.dart`, `lib/src/upsell.dart`, `lib/src/initial.dart`, `lib/src/paywall_footer_screen.dart` | **DELETE IMMEDIATELY**. These are raw RevenueCat sample files that clutter the project and confuse maintenance. |
| **Hardcoded App ID** | `lib/src/constant.dart` (`appId = 'app6dd1e43ac7'`) | **MOVE TO .ENV**. Even if public, configuration should be centralized. Hardcoding violates "Production-Grade" rules. |
| **No Error Handling** | `lib/src/constant.dart` (`checkPremiumStatus`) | **Implement Try-Catch**. The `checkPremiumStatus` function assumes `entitlements` are present. Network failure will crash the app or hang logic. |

### 🟠 MAJOR (Architectural/UX Failures)

| Issue | Location | Recommendation |
| :--- | :--- | :--- |
| **Dual Editor Anti-Pattern** | `lib/ui/editor.dart` vs `lib/ui/ai_generate.dart` | **Refactor to Unified Editor**. Maintaining two separate editor codebases (manual vs AI) guarantees feature divergence and bugs. |
| **Non-Persistent Navigation** | `lib/ui/homepage.dart` | **Implement ShellRoute**. Bottom navigation currently pushes new routes on the stack instead of switching tabs, breaking standard iOS navigation behavior. |
| **Memory-Only Images** | `lib/ui/editor.dart` | **Implement File Persistence**. Images are stored in `Map<String, Uint8List>` RAM. App restart = Data Loss. This is an unacceptable data integrity failure. |
| **Global State via SetState** | Throughout App | **Adopt Provider/Riverpod**. Passing state down the tree manually is fragile and unscalable for a production app. |

### 🟡 MINOR (Polish & hygiene)

| Issue | Location | Recommendation |
| :--- | :--- | :--- |
| **Boilerplate Comments** | `lib/main.dart` | **Remove**. Default Flutter comments ("The following defines the version...") are present in `pubspec.yaml` and code. Clean up. |
| **Material Widgets on iOS** | `lib/ui/setting.dart`, `lib/ui/homepage.dart` | **Use Adaptive/Cupertino**. `AlertDialog`, `CircularProgressIndicator`, and `Switch` should adapt to iOS styling. |
| **Hardcoded Strings** | `lib/src/constant.dart` | **Localization**. Error messages and paywall delays logic contain hardcoded strings/values. |

---

## 3. Security Regression Check

*   ✅ **Secrets**: API Keys moved to `.env`.
*   ✅ **Auth**: `flutter_secure_storage` implemented.
*   ✅ **Renaming**: No "AI Presentation" strings found in `lib/` source code.
*   ⚠️ **Config**: `.env` is bundled as an asset (Acceptable for MVP, but obfuscation recommended for Enterprise).

---

## 4. Final Verdict
**Tome AI** is structurally sound in terms of branding but technically fragile. The **Dead Code** and **Memory-Only Images** issues are immediate blockers for a reliable product launch.

**Next Action**:
1.  Purge `lib/src/` of unused files.
2.  Implement local file storage for images.
3.  Refactor `checkPremiumStatus` for safety.
