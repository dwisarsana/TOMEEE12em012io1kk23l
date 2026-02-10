import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:url_launcher/url_launcher.dart';

import '../src/constant.dart';

class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  bool isLoggedIn = false;
  String? userEmail;
  bool isPremium = false;

  // Brand palette — AI Presentation
  static const _primary = Color(0xFF5865F2); // indigo
  static const _chip    = Color(0xFFEEF2FF);
  static const _ink     = Color(0xFF1F2937);

  @override
  void initState() {
    super.initState();
    _loadLoginStatus();
    _refreshPremiumStatus();
  }

  Future<void> _loadLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      userEmail  = prefs.getString('user_email');
    });
  }

  Future<void> _refreshPremiumStatus() async {
    try {
      final info   = await Purchases.getCustomerInfo();
      final active = info.entitlements.all[entitlementKey]?.isActive ?? false;
      final prefs  = await SharedPreferences.getInstance();
      await prefs.setBool('is_premium', active);
      setState(() => isPremium = active);
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      setState(() => isPremium = prefs.getBool('is_premium') ?? false);
    }
  }

  Future<void> _loginApple() async {
    try {
      if (await SignInWithApple.isAvailable()) {
        final credential = await SignInWithApple.getAppleIDCredential(
          scopes: [AppleIDAuthorizationScopes.email],
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);
        if (credential.email != null) {
          await prefs.setString('user_email', credential.email!);
        }
        setState(() {
          isLoggedIn = true;
          userEmail  = credential.email;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Signed in as ${credential.email ?? 'Apple ID'}")),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Apple Sign In is not available on this device.")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Apple Login failed")),
        );
      }
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('is_logged_in');
    await prefs.remove('user_email');
    setState(() {
      isLoggedIn = false;
      userEmail  = null;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Logged out")));
    }
  }

  Future<void> _removeAccount() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Remove Account"),
        content: const Text("Are you sure? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Remove", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      setState(() {
        isLoggedIn = false;
        userEmail  = null;
        isPremium  = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Account removed")));
      }
    }
  }

  Future<void> _upgrade() async {
    try {
      final offerings = await Purchases.getOfferings();
      final offer = offerings.current;
      if (offer != null && offer.availablePackages.isNotEmpty) {
        await Purchases.purchasePackage(offer.availablePackages.first);
        await _refreshPremiumStatus();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Thanks for upgrading to AI Presentation Premium!")),
          );
        }
      } else {
        presentPaywall();
      }
    } catch (_) {
      presentPaywall();
    }
  }

  Future<void> _restore() async {
    try {
      await Purchases.restorePurchases();
      await _refreshPremiumStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Restored successfully")));
      }
    } catch (_) {
      presentPaywall();
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open $url')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: Text(
          "Settings",
          style: GoogleFonts.poppins(
            color: _primary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
        children: [
          // ===== Account =====
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE4E9EF)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 27,
                      backgroundColor: _chip,
                      child: const Icon(Icons.auto_awesome_rounded, size: 30, color: _primary),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Your Account",
                            style: GoogleFonts.poppins(
                              color: _primary,
                              fontSize: 17.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isLoggedIn
                                ? (userEmail ?? "Signed in with Apple")
                                : "Sign in to sync, back up, and share presentations.",
                            style: GoogleFonts.poppins(
                              color: Colors.black54,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    if (!isLoggedIn)
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: SignInWithAppleButton(
                            onPressed: _loginApple,
                            style: SignInWithAppleButtonStyle.black,
                          ),
                        ),
                      ),
                    if (isLoggedIn) ...[
                      _accountActionButton(
                        icon: Icons.logout_rounded,
                        label: "Logout",
                        color: Colors.grey[700]!,
                        onTap: _logout,
                      ),
                      const SizedBox(width: 8),
                      _accountActionButton(
                        icon: Icons.delete_forever_rounded,
                        label: "Remove",
                        color: Colors.redAccent,
                        onTap: _removeAccount,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ===== Premium =====
          _sectionTitle("Premium"),
          _menuTile(
            icon: Icons.workspace_premium_rounded,
            text: isPremium ? "You’re Premium" : "Upgrade to Premium",
            subtitle: isPremium
                ? "Thanks for supporting AI Presentation!"
                : "Unlock PPTX export themes, HD image generation with AI.",
            color: _primary,
            trailing: isPremium
                ? const Icon(Icons.verified_rounded, color: _primary)
                : null,
            onTap: isPremium ? null : _upgrade,
          ),
          _menuTile(
            icon: Icons.restore_rounded,
            text: "Restore Purchases",
            color: _primary,
            onTap: _restore,
          ),

          const SizedBox(height: 28),

          // ===== Legal =====
          _sectionTitle("Legal"),
          _menuTile(
            icon: Icons.privacy_tip_rounded,
            text: "Privacy Policy",
            color: _primary,
            onTap: () => _launchURL("https://appsdeveloper.org/privacy.html"),
          ),
          _menuTile(
            icon: Icons.book_rounded,
            text: "Terms & EULA",
            color: _primary,
            onTap: () => _launchURL("https://appsdeveloper.org/terms.html"),
          ),
        ],
      ),
    );
  }

  // ===== UI helpers =====
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          color: _primary,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String text,
    String? subtitle,
    required Color color,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        tileColor: Colors.white,
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          text,
          style: GoogleFonts.poppins(
            color: _ink,
            fontWeight: FontWeight.w700,
            fontSize: 16.2,
          ),
        ),
        subtitle: subtitle == null
            ? null
            : Text(
          subtitle,
          style: GoogleFonts.poppins(
            color: Colors.black54,
            fontSize: 12.8,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: trailing ?? Icon(Icons.chevron_right_rounded, color: color.withOpacity(0.4)),
      ),
    );
  }

  Widget _accountActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: color.withOpacity(0.35), width: 1),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
