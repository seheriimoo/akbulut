import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'config/app_config.dart';
import 'compliance/consent_store.dart';
import 'features/player/player_screen.dart';
import 'infrastructure/crash_reporting.dart';
import 'screens/ai_chat_screen.dart';
import 'screens/choice_screen.dart';
import 'screens/compliance/consent_gate_screen.dart';
import 'screens/compliance/legal_document_screen.dart';
import 'screens/premium_paywall_screen.dart';

Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // SHIP-01: secrets only from dart-define / dart-define-from-file.
    await AppConfig.load();

    await CrashReporting.bootstrap(
      appRunner: () async {
        if (AppConfig.hasRevenueCatApiKey) {
          await Purchases.configure(
            PurchasesConfiguration(AppConfig.revenueCatApiKey),
          );
        }
        runApp(const SleepWaveApp());
      },
    );
  }, CrashReporting.zoneErrorHandler);
}

class AppRoutes {
  static const String welcome = '/';
  static const String choice = '/choice';
  static const String sleepAnalysis = '/sleep-analysis';
  static const String directSleep = '/direct-sleep';
  static const String premium = '/premium';
  static const String consent = '/consent';
  static const String privacy = '/privacy';
  static const String terms = '/terms';
}

class SleepWaveApp extends StatelessWidget {
  const SleepWaveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SleepWave',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      builder: (context, child) {
      return Stack(    
      children: [
            // Positioned.fill(
            //   child: Image.asset(
            //     'assets/images/moon_bg.jpg',
            //     fit: BoxFit.cover,
            //   ),
            // ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                   colors: [
                  const Color(0xFF02040D),
                  const Color(0xFF050B1E),
                     ],
                   ),
                ),
              ),
            ),
            if (child != null) child,
          ],
        );
      },
      initialRoute: AppRoutes.welcome,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.welcome:
        return _fade(const WelcomeScreen(), settings);
      case AppRoutes.choice:
        return _fade(const ChoiceScreen(), settings);
      case '/ai-chat':
        return _fade(const AISleepChatScreen(), settings);
      case AppRoutes.sleepAnalysis:
        return _fade(const SleepAnalysisScreen(), settings);
      case AppRoutes.directSleep:
        return _fade(const DirectSleepScreen(), settings);
      case AppRoutes.premium:
        return _fade(const PremiumPaywallScreen(), settings);
      case AppRoutes.consent:
        return _fade(const ConsentGateScreen(), settings);
      case AppRoutes.privacy:
        return _fade(
          const LegalDocumentScreen(kind: LegalDocumentKind.privacyPolicy),
          settings,
        );
      case AppRoutes.terms:
        return _fade(
          const LegalDocumentScreen(kind: LegalDocumentKind.termsOfService),
          settings,
        );
      default:
        return _fade(const WelcomeScreen(), settings);
    }
  }

  static PageRouteBuilder _fade(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      transitionDuration: Duration.zero,
      pageBuilder: (_, animation, __) =>
          FadeTransition(opacity: animation, child: page),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Future<void> _openNight(BuildContext context) async {
    final accepted = await ConsentStore.hasAcceptedBaseline();
    if (!context.mounted) return;
    if (accepted) {
      Navigator.pushNamed(context, '/ai-chat');
    } else {
      Navigator.pushNamed(context, AppRoutes.consent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
      children: [
      Positioned.fill(
      child: Image.asset(
        'assets/images/moon_bg.jpg',
        fit: BoxFit.cover,
      ),
    ),
      Positioned.fill(
      child: Container(
      color: Colors.black.withOpacity(0.62),
      ),
    ),
    SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Column(
                children: [
                  Text(
                    "Nocta",
                    style: TextStyle(
                      fontSize: 30,
                      letterSpacing: 1.2,
                      color: Colors.white.withOpacity(0.96),
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: 150,
                    height: 1.8,
                    color: Colors.white.withOpacity(0.4),
                  ),
                  const SizedBox(height: 6),
                  Text(
                   "AI-Powered Personalized Sleep Transition",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      letterSpacing: 0.6,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
              const Spacer(flex: 2),
              GestureDetector(
                onTap: () => _openNight(context),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                    child: Container(
                      height: 48,
                      width: double.infinity,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.18),
                        ),
                      ),
                      child: Text(
                        "Begin",
                        style: TextStyle(
                          fontSize: 14,
                          letterSpacing: 1.2,
                          color: Colors.white.withOpacity(0.95),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 18,
                children: [
                  TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.privacy),
                    child: Text(
                      'Privacy Policy',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white.withOpacity(0.35),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.terms),
                    child: Text(
                      'Terms of Service',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white.withOpacity(0.35),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ],
  ),
);
  }
}

////////////////////////////////////////////////////////////
/// 🔥 EKSİK CLASSLARI EKLEDİM (SORUN BURADAYDI)
////////////////////////////////////////////////////////////

class SleepAnalysisScreen extends StatelessWidget {
  const SleepAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(),

              Text(
                "Your mind seems active tonight",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.92),
                  fontSize: 26,
                  fontWeight: FontWeight.w300,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                "We'll help you slow down and settle into sleep.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 8,
                ),
              ),

              const Spacer(),

              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.directSleep,
                  );
                },
                child: Container(
                  height: 52,
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.18),
                    ),
                  ),
                  child: const Text(
                    "Continue",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class DirectSleepScreen extends StatelessWidget {
  const DirectSleepScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(),

              Text(
                "Ready to sleep?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.92),
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                "We'll begin your sleep session now.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 15,
                ),
              ),

              const Spacer(),

              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlayerScreen(
                        blocker: "mind",
                        sleepLatency: "30",
                        energy: "low",
                        goal: "sleep",
                        sessionLength: const Duration(minutes: 30),
                      ),
                    ),
                  );
                },
                child: Container(
                  height: 52,
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.18),
                    ),
                  ),
                  child: const Text(
                    "Start Session",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
