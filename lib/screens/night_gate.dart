import 'package:flutter/material.dart';

import '../billing/billing_service.dart';
import '../billing/night_access.dart';
import '../core/brain/living_mind_store.dart';
import 'paywall_screen.dart';

/// Opens paywall before HCOS when free nights are exhausted.
///
/// Does not start Conversation. Does not belong to HCOS.
Future<bool> ensureNightConversationAllowed(BuildContext context) async {
  final billing = BillingService.instance;
  if (await billing.hasPremiumEntitlement()) return true;

  final completed = await const LivingMindStore().loadTotalSessions();
  if (NightAccess.canStartConversation(
    isPremium: false,
    completedNights: completed,
  )) {
    return true;
  }

  if (!context.mounted) return false;
  final purchased = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => const PaywallScreen()),
  );
  if (purchased == true) return true;
  return billing.hasPremiumEntitlement();
}
