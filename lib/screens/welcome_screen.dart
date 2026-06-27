import 'dart:ui'; // ✅ EKLENDİ
import 'package:flutter/material.dart';

void main() {
  runApp(const SleepWaveApp());
}

class AppRoutes {
  static const String welcome = '/';
  static const String choice = '/choice';
  static const String aiChat = '/ai-chat';
  static const String sleepAnalysis = '/sleep-analysis';
  static const String directSleep = '/direct-sleep';
  static const String premium = '/premium';
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
            // 🌙 BACKGROUND
            Positioned.fill(
              child: Image.asset(
                'assets/images/moon_bg.jpg',
                fit: BoxFit.cover,
              ),
            ),

            // 🌑 OVERLAY
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.18),
                      Colors.black.withOpacity(0.42),
                      Colors.black.withOpacity(0.68),
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
      case AppRoutes.aiChat:
        return _fade(const AISleepChatScreen(), settings);
      case AppRoutes.sleepAnalysis:
        return _fade(const SleepAnalysisScreen(), settings);
      case AppRoutes.directSleep:
        return _fade(const DirectSleepScreen(), settings);
      case AppRoutes.premium:
        return _fade(const PremiumPaywallScreen(), settings);
      default:
        return _fade(const WelcomeScreen(), settings);
    }
  }

  static PageRouteBuilder _fade(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, animation, __) =>
          FadeTransition(opacity: animation, child: page),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _openChoiceScreen(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.choice);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 70),

              // 🔥 SADECE BURASI DEĞİŞTİ (PREMIUM BAŞLIK)
              Text(
                "SleepWave",
                style: TextStyle(
                  fontSize: 200,
                  letterSpacing: 3.6,
                  color: Colors.white.withOpacity(0.96),
                  fontWeight: FontWeight.w300,
                  shadows: [
                    Shadow(
                      color: Colors.white.withOpacity(0.20),
                      blurRadius: 14,
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              Text(
                "AI-Powered Personalized Sleep Transition",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 200,
                  letterSpacing: 0.6,
                  color: Colors.white.withOpacity(0.45),
                ),
              ),

              const SizedBox(height: 10),

              // 🔥 PREMIUM BLUR BUTTON (DEĞİŞMEDİ)
              GestureDetector(
                onTap: () => _openChoiceScreen(context),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      height: 48,
                      width: double.infinity,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.25),
                        ),
                      ),
                      child: const Text(
                        "Begin",
                        style: TextStyle(
                          fontSize: 14,
                          letterSpacing: 1.6,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 45),
            ],
          ),
        ),
      ),
    );
  }
}

class ChoiceScreen extends StatelessWidget {
  const ChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Text("Choice Screen"),
      ),
    );
  }
}

class AISleepChatScreen extends StatelessWidget {
  const AISleepChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Text("AI Chat"),
      ),
    );
  }
}

class SleepAnalysisScreen extends StatelessWidget {
  const SleepAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Text("Sleep Analysis"),
      ),
    );
  }
}

class PremiumPaywallScreen extends StatelessWidget {
  const PremiumPaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Text("Premium"),
      ),
    );
  }
}

class DirectSleepScreen extends StatelessWidget {
  const DirectSleepScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Text("Direct Sleep"),
      ),
    );
  }
}