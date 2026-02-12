import 'package:flutter/material.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Wrap RevenueCatUI in a Scaffold to avoid navigation issues if pushed as a route.
    // However, RevenueCatUI.presentPaywall() is usually a modal.
    // If this screen is navigated to via GoRouter, we should use PaywallView if available,
    // or call the modal and pop when done.
    // For simplicity and robustness given the contract, we'll embed the view.
    return Scaffold(
      body: PaywallView(
        onDismiss: () => Navigator.pop(context),
      ),
    );
  }
}
