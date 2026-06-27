import 'dart:ui';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SomniaApp());
}

class SomniaApp extends StatelessWidget {
  const SomniaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Somnia',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050608),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE7ECF3),
          secondary: Color(0xFF9BA8BC),
          surface: Color(0xFF0B0F14),
        ),
      ),
      home: const SomniaWelcomeScreen(),
    );
  }
}

class SomniaWelcomeScreen extends StatelessWidget {
  const SomniaWelcomeScreen({super.key});

  void _goNext(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Next step: onboarding questions'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A0F18),
              Color(0xFF06080D),
              Color(0xFF030405),
            ],
          ),
        ),
        child: Stack(
          children: [
            const _AmbientBackground(),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Somnia',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.96),
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Spacer(),
                    Center(
                      child: Column(
                        children: [
                          const _MoonHero(),
                          const SizedBox(height: 34),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.08),
                              ),
                            ),
                            child: const Text(
                              'PERSONAL SLEEP EXPERIENCE',
                              style: TextStyle(
                                color: Color(0xFFAAB6C5),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          const Text(
                            'Your personal\nsleep experience begins',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFFEFF3F8),
                              fontSize: 34,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -1.1,
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Welcome. We'll ask a few quick questions to prepare the most suitable sleep experience for you.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.64),
                              fontSize: 15,
                              height: 1.5,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    _GlassButton(
                      onTap: () => _goNext(context),
                      child: const Text(
                        'Start',
                        style: TextStyle(
                          color: Color(0xFF050608),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -90,
          right: -40,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.04),
            ),
          ),
        ),
        Positioned(
          top: 140,
          left: -70,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFC9D3E3).withOpacity(0.04),
            ),
          ),
        ),
        Positioned(
          bottom: 120,
          right: -30,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.025),
            ),
          ),
        ),
        ...List.generate(
          14,
          (index) => Positioned(
            top: 70.0 + (index * 42 % 520),
            left: 18.0 + (index * 31 % 330),
            child: Container(
              width: index.isEven ? 2.4 : 1.6,
              height: index.isEven ? 2.4 : 1.6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(index.isEven ? 0.8 : 0.45),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MoonHero extends StatelessWidget {
  const _MoonHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      height: 230,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white.withOpacity(0.12),
            Colors.white.withOpacity(0.06),
            Colors.white.withOpacity(0.02),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.05),
            blurRadius: 50,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [
                Color(0xFFF5F7FB),
                Color(0xFFD9E1EC),
                Color(0xFFB8C4D4),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white24,
                blurRadius: 22,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 26,
                left: 24,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.08),
                  ),
                ),
              ),
              Positioned(
                top: 54,
                right: 28,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.06),
                  ),
                ),
              ),
              Positioned(
                bottom: 26,
                left: 46,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.05),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _GlassButton({
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Ink(
              height: 58,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFE7ECF3),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.10),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}