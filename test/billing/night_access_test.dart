import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slowave/billing/billing_purchases_port.dart';
import 'package:slowave/billing/billing_service.dart';
import 'package:slowave/billing/night_access.dart';
import 'package:slowave/billing/premium_product_access.dart';
import 'package:slowave/billing/sleep_bed_catalog.dart';
import 'package:slowave/core/brain/living_mind_store.dart';
import 'package:slowave/screens/ai_chat_screen.dart';
import 'package:slowave/screens/night_complete_screen.dart';
import 'package:slowave/screens/night_gate.dart';
import 'package:slowave/screens/paywall_screen.dart';

CustomerInfo _customerInfo({required bool premium}) {
  final entitlement = EntitlementInfo(
    'nocta_premium',
    true,
    true,
    '2026-01-01T00:00:00Z',
    '2026-01-01T00:00:00Z',
    'nocta_premium_yearly',
    true,
    periodType: PeriodType.intro,
  );
  final active = premium
      ? <String, EntitlementInfo>{'nocta_premium': entitlement}
      : <String, EntitlementInfo>{};
  return CustomerInfo(
    EntitlementInfos(Map<String, EntitlementInfo>.from(active), active),
    const {},
    premium ? const ['nocta_premium_yearly'] : const [],
    premium ? const ['nocta_premium_yearly'] : const [],
    const [],
    '2026-01-01T00:00:00Z',
    'test-user',
    const {},
    '2026-01-01T00:00:00Z',
  );
}

class _FakePurchases implements BillingPurchasesPort {
  _FakePurchases({required this.customerInfo});

  CustomerInfo customerInfo;

  @override
  Future<Offerings> getOfferings() async {
    return Offerings(const {}, current: null);
  }

  @override
  Future<CustomerInfo> getCustomerInfo() async => customerInfo;

  @override
  Future<CustomerInfo> purchasePackage(Package package) async => customerInfo;

  @override
  Future<CustomerInfo> restorePurchases() async => customerInfo;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BillingService previousBilling;

  setUp(() {
    previousBilling = BillingService.instance;
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    BillingService.instance = previousBilling;
  });

  PremiumProductAccess accessFor({required bool premium}) {
    return PremiumProductAccess(isPremium: premium);
  }

  group('V1 free nights + paywall gate', () {
    testWidgets('1–3. nights 1-3 start conversation without a paywall',
        (tester) async {
      for (final completed in [0, 1, 2]) {
        SharedPreferences.setMockInitialValues({
          'nocta_living_mind_total_sessions': completed,
        });
        BillingService.instance = BillingService.forTesting(
          purchases: _FakePurchases(customerInfo: _customerInfo(premium: false)),
          configured: false,
        );

        late bool allowed;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () async {
                    allowed = await ensureNightConversationAllowed(context);
                  },
                  child: const Text('start-night'),
                );
              },
            ),
          ),
        );
        await tester.tap(find.text('start-night'));
        await tester.pumpAndSettle();
        expect(allowed, isTrue, reason: 'completed=$completed');
        expect(find.byType(PaywallScreen), findsNothing);
      }
    });

    test('1–3. new user nights 1-3 keep HCOS access and 30m audio', () {
      const free = PremiumProductAccess(isPremium: false);
      for (final completed in [0, 1, 2]) {
        expect(
          NightAccess.canStartConversation(
            isPremium: false,
            completedNights: completed,
          ),
          isTrue,
          reason: 'completed=$completed must still enter HCOS',
        );
        expect(free.sessionLength, const Duration(minutes: 30));
        expect(free.sleepBedAsset, PremiumProductAccess.freeSleepBedAsset);
      }
    });

    test('4. night 4 blocks conversation before HCOS starts', () {
      expect(
        NightAccess.canStartConversation(
          isPremium: false,
          completedNights: 3,
        ),
        isFalse,
      );
    });

    testWidgets('5. dismissing paywall does not open HCOS', (tester) async {
      SharedPreferences.setMockInitialValues({
        'nocta_living_mind_total_sessions': 3,
      });
      BillingService.instance = BillingService.forTesting(
        purchases: _FakePurchases(customerInfo: _customerInfo(premium: false)),
        configured: false,
      );

      var allowed = true;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () async {
                  allowed = await ensureNightConversationAllowed(context);
                },
                child: const Text('start-night'),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('start-night'));
      await tester.pumpAndSettle();

      expect(find.byType(PaywallScreen), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(allowed, isFalse);
      expect(find.byType(AISleepChatScreen), findsNothing);
    });

    test('6–8. monthly, yearly, and trial entitlement are unlimited + 45m', () {
      for (final premium in [true]) {
        expect(
          NightAccess.canStartConversation(
            isPremium: premium,
            completedNights: 3,
          ),
          isTrue,
        );
        final access = accessFor(premium: premium);
        expect(access.sessionLength, const Duration(minutes: 45));
        expect(access.sleepBedAsset, PremiumProductAccess.premiumSleepBedAsset);
      }
    });

    testWidgets('9. restore removes the night gate', (tester) async {
      SharedPreferences.setMockInitialValues({
        'nocta_living_mind_total_sessions': 3,
      });
      BillingService.instance = BillingService.forTesting(
        purchases: _FakePurchases(customerInfo: _customerInfo(premium: true)),
        configured: true,
      );

      late bool allowed;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () async {
                  allowed = await ensureNightConversationAllowed(context);
                },
                child: const Text('start-night'),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('start-night'));
      await tester.pumpAndSettle();
      expect(allowed, isTrue);
      expect(find.byType(PaywallScreen), findsNothing);
    });

    test('10. premium is not affected by night count', () {
      expect(
        NightAccess.canStartConversation(
          isPremium: true,
          completedNights: 0,
        ),
        isTrue,
      );
      expect(
        NightAccess.canStartConversation(
          isPremium: true,
          completedNights: 99,
        ),
        isTrue,
      );
    });

    test('11. failed or cancelled purchase does not grant premium', () {
      expect(
        NightAccess.canStartConversation(
          isPremium: false,
          completedNights: 3,
        ),
        isFalse,
      );
      expect(accessFor(premium: false).sessionLength, const Duration(minutes: 30));
    });

    test('12. app restart keeps completed free-night count', () async {
      const store = LivingMindStore();
      await store.saveAfterNight(totalSessions: 2, blocker: 'mind');
      expect(await const LivingMindStore().loadTotalSessions(), 2);
      expect(
        NightAccess.canStartConversation(
          isPremium: false,
          completedNights: 2,
        ),
        isTrue,
      );
    });

    testWidgets('13. opening chat without completing does not consume a night',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'nocta_living_mind_total_sessions': 1,
      });
      await tester.pumpWidget(const MaterialApp(home: AISleepChatScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(await const LivingMindStore().loadTotalSessions(), 1);
    });

    test('14. existing users with 3+ completed nights are gated safely', () {
      expect(
        NightAccess.canStartConversation(
          isPremium: false,
          completedNights: 3,
        ),
        isFalse,
      );
      expect(
        NightAccess.canStartConversation(
          isPremium: false,
          completedNights: 12,
        ),
        isFalse,
      );
      expect(
        NightAccess.shouldShowPostThirdNightNote(
          isPremium: false,
          completedNights: 3,
        ),
        isTrue,
      );
      expect(
        NightAccess.shouldShowPostThirdNightNote(
          isPremium: true,
          completedNights: 3,
        ),
        isFalse,
      );
    });
  });

  group('Paywall placement and night counting contracts', () {
    test('paywall is before conversation, not at audio handoff', () {
      final main = File('lib/main.dart').readAsStringSync();
      final consent = File('lib/screens/compliance/consent_gate_screen.dart')
          .readAsStringSync();
      final chat = File('lib/screens/ai_chat_screen.dart').readAsStringSync();
      expect(main.contains('ensureNightConversationAllowed'), isTrue);
      expect(consent.contains('ensureNightConversationAllowed'), isTrue);
      expect(chat.contains('PaywallScreen'), isFalse);
      expect(chat.contains('_startAudioFlow'), isTrue);
    });

    test('free night increments only through completeNightSession save', () {
      final chat = File('lib/screens/ai_chat_screen.dart').readAsStringSync();
      expect(chat.contains('completeNightSession'), isTrue);
      expect(chat.contains('saveAfterNight'), isTrue);
      final closeIdx = chat.indexOf('Future<void> _closeNightSession');
      final saveIdx = chat.indexOf('saveAfterNight');
      expect(saveIdx, greaterThan(closeIdx));
      expect(
        chat.indexOf('saveAfterNight', saveIdx + 1),
        -1,
      );
    });

    testWidgets('third-night closing copy is light, not a paywall', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NightCompleteScreen(showPremiumTransition: true),
        ),
      );
      expect(find.text('Tonight is complete'), findsOneWidget);
      expect(
        find.text(
          'If tomorrow night your mind is still awake, Nocta can meet you there.',
        ),
        findsOneWidget,
      );
      expect(find.byType(PaywallScreen), findsNothing);
    });
  });

  group('Audio duration contract', () {
    test('every live blocker uses entitlement 30m/45m beds, not 5m GlobalSleep',
        () {
      const beds = SleepBedCatalog();
      const free = PremiumProductAccess(isPremium: false);
      const premium = PremiumProductAccess(isPremium: true);
      for (final blocker in [
        'mind',
        'loneliness',
        'relationship',
        'stress',
        'unknown',
      ]) {
        expect(beds.assetFor(blocker: blocker, access: free), free.sleepBedAsset);
        expect(
          beds.assetFor(blocker: blocker, access: premium),
          premium.sleepBedAsset,
        );
        expect(
          beds.assetFor(blocker: blocker, access: free),
          isNot(SleepBedCatalog.globalSleepBed),
        );
      }
      expect(File(PremiumProductAccess.freeSleepBedAsset).existsSync(), isTrue);
      expect(
        File(PremiumProductAccess.premiumSleepBedAsset).existsSync(),
        isTrue,
      );
    });

    test('shipped m4a runtimes match free 30m and premium 45m timers', () {
      final free = _m4aMovieDuration(PremiumProductAccess.freeSleepBedAsset);
      final premium = _m4aMovieDuration(
        PremiumProductAccess.premiumSleepBedAsset,
      );
      expect(
        (free.inSeconds - 30 * 60).abs(),
        lessThan(2),
        reason: 'free bed must be ~30 minutes, was ${free.inSeconds}s',
      );
      expect(
        (premium.inSeconds - 45 * 60).abs(),
        lessThan(2),
        reason: 'premium bed must be ~45 minutes, was ${premium.inSeconds}s',
      );
    });
  });
}

/// Movie duration from the ISO-BMFF `mvhd` box. No macOS `afinfo` / ffmpeg.
Duration _m4aMovieDuration(String path) {
  final raf = File(path).openSync();
  try {
    final length = raf.lengthSync();
    while (raf.positionSync() + 8 <= length) {
      final start = raf.positionSync();
      final header = raf.readSync(8);
      if (header.length < 8) {
        break;
      }
      final headerData = ByteData.sublistView(header);
      var boxSize = headerData.getUint32(0);
      final type = String.fromCharCodes(header.sublist(4));
      var headerSize = 8;
      if (boxSize == 1) {
        final ext = raf.readSync(8);
        boxSize = ByteData.sublistView(ext).getUint64(0);
        headerSize = 16;
      } else if (boxSize == 0) {
        boxSize = length - start;
      }
      expect(boxSize, greaterThanOrEqualTo(headerSize), reason: path);
      if (type == 'mvhd') {
        final payload = raf.readSync(boxSize - headerSize);
        return _parseMvhdPayload(payload, path);
      }
      const containers = {'moov', 'trak', 'mdia', 'minf'};
      if (containers.contains(type)) {
        continue;
      }
      raf.setPositionSync(start + boxSize);
    }
    fail('no mvhd box in $path');
  } finally {
    raf.closeSync();
  }
}

Duration _parseMvhdPayload(Uint8List payload, String path) {
  expect(payload.length, greaterThanOrEqualTo(20), reason: path);
  final data = ByteData.sublistView(payload);
  final version = payload[0];
  late final int timescale;
  late final int durationTicks;
  if (version == 0) {
    timescale = data.getUint32(12);
    durationTicks = data.getUint32(16);
  } else if (version == 1) {
    expect(payload.length, greaterThanOrEqualTo(32), reason: path);
    timescale = data.getUint32(20);
    durationTicks = data.getUint64(24);
  } else {
    fail('unsupported mvhd version $version in $path');
  }
  expect(timescale, greaterThan(0), reason: path);
  return Duration(
    milliseconds: ((durationTicks * 1000) / timescale).round(),
  );
}

