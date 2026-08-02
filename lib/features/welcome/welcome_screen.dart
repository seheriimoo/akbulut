import 'dart:ui';
import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {

  const WelcomeScreen({super.key});

  void _openChoiceScreen(BuildContext context) {
    Navigator.pushNamed(context, '/ai-chat');
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
                onTap: () => _openChoiceScreen(context),
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
              const SizedBox(height: 45),
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