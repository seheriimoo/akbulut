import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

void main() {
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
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF020202),
        useMaterial3: true,
      ),
      home: const WelcomeScreen(),
    );
  }
}

class AppColors {
  static const bg = Color(0xFF020202);
  static const text = Color(0xFFF5F5F5);
  static const sub = Color(0xB5FFFFFF);
  static const line = Color(0x7AFFFFFF);
  static const soft = Color(0x1AFFFFFF);
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SomniaShell(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, c) {
              final moon = math.min(c.maxWidth * 0.56, 250.0);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    const BrandWordmark(),
                    const Spacer(flex: 2),
                    MoonHero(size: moon),
                    const Spacer(),
                    const Text(
                      'Welcome to Somnia',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 29,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        'I will ask you a few short questions to create your personalized sleep experience.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.sub,
                          fontSize: 16,
                          height: 1.55,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                    const Spacer(flex: 2),
                    OutlineCTA(
                      label: 'Start',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const QuestionScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class QuestionScreen extends StatelessWidget {
  const QuestionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const options = [
      'Less than 10 minutes',
      '10–20 minutes',
      '20–40 minutes',
      'More than 40 minutes',
    ];

    return Scaffold(
      body: SomniaShell(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 26),
            child: Column(
              children: [
                const BrandWordmark(),
                const SizedBox(height: 28),
                const MiniMoonHeader(),
                const SizedBox(height: 36),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'How long does it usually take you to fall asleep?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 24,
                      height: 1.38,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.35,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                for (int i = 0; i < options.length; i++) ...[
                  OptionPill(label: options[i], highlighted: i == 1),
                  const SizedBox(height: 14),
                ],
                const SizedBox(height: 8),
                const DotsIndicator(current: 0, total: 3),
                const SizedBox(height: 22),
                OutlineCTA(
                  label: 'Continue',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PlayerScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SomniaShell(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 26),
            child: Column(
              children: [
                const BrandWordmark(),
                const SizedBox(height: 24),
                const MiniMoonHeader(showWave: true),
                const SizedBox(height: 26),
                const Text(
                  'Deep Sleep',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 34,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '30 min',
                  style: TextStyle(
                    color: AppColors.sub,
                    fontSize: 18,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 24),
                const WaveStrip(),
                const SizedBox(height: 24),
                Row(
                  children: const [
                    Text('2:16', style: TextStyle(color: AppColors.sub, fontSize: 14)),
                    SizedBox(width: 12),
                    Expanded(child: LineSlider(value: 0.42)),
                    SizedBox(width: 12),
                    Text('-27:44', style: TextStyle(color: AppColors.sub, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.fast_rewind_rounded, color: AppColors.sub, size: 36),
                    SizedBox(width: 28),
                    PlayButton(),
                    SizedBox(width: 28),
                    Icon(Icons.fast_forward_rounded, color: AppColors.sub, size: 36),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  children: const [
                    Icon(Icons.volume_up_rounded, color: AppColors.sub, size: 22),
                    SizedBox(width: 12),
                    Expanded(child: LineSlider(value: 0.38)),
                    SizedBox(width: 12),
                    Icon(Icons.nights_stay_rounded, color: AppColors.sub, size: 22),
                  ],
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: const [
                    BottomItem(icon: Icons.dark_mode_rounded, label: 'Sleep'),
                    BottomItem(icon: Icons.access_time_rounded, label: 'Timer'),
                    BottomItem(icon: Icons.favorite_border_rounded, label: 'Save'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SomniaShell extends StatelessWidget {
  final Widget child;
  const SomniaShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF010101), Color(0xFF040404), Color(0xFF020202)],
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: StarField()),
          const Positioned.fill(child: CosmicGlow()),
          child,
        ],
      ),
    );
  }
}

class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      'S L O W A V E',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Color(0xD9FFFFFF),
        fontSize: 20,
        letterSpacing: 8,
        fontWeight: FontWeight.w300,
      ),
    );
  }
}

class CosmicGlow extends StatelessWidget {
  const CosmicGlow({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Align(
            alignment: const Alignment(0, 0.78),
            child: Container(
              width: 320,
              height: 220,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [Colors.white.withOpacity(0.10), Colors.transparent],
                ),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0, -0.08),
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [Colors.white.withOpacity(0.08), Colors.transparent],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StarField extends StatelessWidget {
  const StarField({super.key});

  @override
  Widget build(BuildContext context) {
    const stars = [
      Offset(0.10, 0.09), Offset(0.34, 0.13), Offset(0.60, 0.16), Offset(0.83, 0.18),
      Offset(0.18, 0.27), Offset(0.76, 0.28), Offset(0.11, 0.46), Offset(0.87, 0.51),
      Offset(0.22, 0.66), Offset(0.54, 0.74), Offset(0.80, 0.80), Offset(0.16, 0.90),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        return Stack(
          children: [
            for (int i = 0; i < stars.length; i++)
              Positioned(
                left: c.maxWidth * stars[i].dx,
                top: c.maxHeight * stars[i].dy,
                child: Container(
                  width: i % 4 == 0 ? 3 : 2,
                  height: i % 4 == 0 ? 3 : 2,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(i % 4 == 0 ? 0.52 : 0.28),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.08),
                        blurRadius: 5,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class MoonHero extends StatelessWidget {
  final double size;
  const MoonHero({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: size + 60,
          height: size + 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.10),
                blurRadius: 60,
                spreadRadius: 10,
              ),
            ],
          ),
        ),
        MoonDisc(size: size),
      ],
    );
  }
}

class MiniMoonHeader extends StatelessWidget {
  final bool showWave;
  const MiniMoonHeader({super.key, this.showWave = true});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 220,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          const Positioned(
            top: 0,
            child: MoonHero(size: 170),
          ),
          if (showWave)
            Positioned(
              left: 0,
              right: 0,
              top: 110,
              child: const SizedBox(
                height: 70,
                child: WaveGlow(),
              ),
            ),
        ],
      ),
    );
  }
}

class MoonDisc extends StatelessWidget {
  final double size;
  const MoonDisc({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: Alignment(-0.18, -0.18),
            colors: [Color(0xFFF7F7F7), Color(0xFFE9E9E9), Color(0xFFD7D7D7)],
            stops: [0.0, 0.68, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: MoonPainter())),
            Positioned(
              left: size * 0.10,
              top: size * 0.14,
              child: Container(
                width: size * 0.42,
                height: size * 0.42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Colors.white.withOpacity(0.10), Colors.transparent],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MoonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final crater = Paint()..color = const Color(0x11000000);
    final craterSoft = Paint()..color = const Color(0x10FFFFFF);

    final data = [
      [0.28, 0.34, 0.12],
      [0.63, 0.29, 0.09],
      [0.41, 0.66, 0.14],
      [0.66, 0.54, 0.10],
      [0.48, 0.47, 0.07],
    ];

    for (final d in data) {
      final center = Offset(size.width * d[0], size.height * d[1]);
      final r = size.width * d[2];
      canvas.drawCircle(center.translate(3, 3), r, crater);
      canvas.drawCircle(center.translate(-1, -1), r, craterSoft);
    }

    final edgeShadow = Paint()
      ..shader = RadialGradient(
        colors: [Colors.transparent, Colors.black.withOpacity(0.10)],
        stops: const [0.76, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, edgeShadow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class WaveGlow extends StatelessWidget {
  const WaveGlow({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: WaveGlowPainter());
  }
}

class WaveGlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Path()..moveTo(0, size.height * 0.58);
    p1.cubicTo(
      size.width * 0.18, size.height * 0.15,
      size.width * 0.35, size.height * 0.88,
      size.width * 0.52, size.height * 0.54,
    );
    p1.cubicTo(
      size.width * 0.68, size.height * 0.18,
      size.width * 0.84, size.height * 0.80,
      size.width, size.height * 0.45,
    );

    final p2 = Path()..moveTo(0, size.height * 0.46);
    p2.cubicTo(
      size.width * 0.16, size.height * 0.80,
      size.width * 0.34, size.height * 0.10,
      size.width * 0.56, size.height * 0.50,
    );
    p2.cubicTo(
      size.width * 0.74, size.height * 0.82,
      size.width * 0.90, size.height * 0.22,
      size.width, size.height * 0.50,
    );

    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.white.withOpacity(0.20)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = const LinearGradient(
        colors: [Colors.transparent, Color(0x85FFFFFF), Color(0x30FFFFFF), Color(0xAAFFFFFF), Colors.transparent],
      ).createShader(Offset.zero & size)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawPath(p1, glow);
    canvas.drawPath(p2, line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class OutlineCTA extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const OutlineCTA({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.line, width: 1.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
              foregroundColor: AppColors.text,
              backgroundColor: Colors.white.withOpacity(0.015),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
            ),
            onPressed: onTap,
            child: Text(label),
          ),
        ),
      ),
    );
  }
}

class OptionPill extends StatelessWidget {
  final String label;
  final bool highlighted;
  const OptionPill({super.key, required this.label, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: highlighted ? Colors.white.withOpacity(0.95) : AppColors.line,
              width: highlighted ? 1.45 : 1.1,
            ),
            color: highlighted ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.015),
            boxShadow: highlighted
                ? [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.05),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.text,
              fontSize: 17,
              fontWeight: highlighted ? FontWeight.w400 : FontWeight.w300,
            ),
          ),
        ),
      ),
    );
  }
}

class DotsIndicator extends StatelessWidget {
  final int current;
  final int total;
  const DotsIndicator({super.key, required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final active = i == current;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: active ? 10 : 8,
          height: active ? 10 : 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? Colors.white : Colors.white.withOpacity(0.25),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.16),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}

class WaveStrip extends StatelessWidget {
  const WaveStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: CustomPaint(painter: WaveStripPainter()),
    );
  }
}

class WaveStripPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final soft = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withOpacity(0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final bars = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2
      ..color = Colors.white.withOpacity(0.46)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final line = Path()..moveTo(0, size.height * 0.58);
    for (double x = 0; x <= size.width; x += 12) {
      final y = size.height * 0.58 + 7 * math.sin(x / 32) + 4 * math.cos(x / 18);
      line.lineTo(x, y);
    }
    canvas.drawPath(line, soft);

    for (double x = 8; x < size.width; x += 8) {
      final intensity = 0.5 + 0.5 * math.sin(x / 24) + 0.3 * math.cos(x / 15);
      final h = 8 + intensity.abs() * 12;
      final cy = size.height * 0.55;
      canvas.drawLine(Offset(x, cy - h / 2), Offset(x, cy + h / 2), bars);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LineSlider extends StatelessWidget {
  final double value;
  const LineSlider({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 16,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          FractionallySizedBox(
            widthFactor: value,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          Align(
            alignment: Alignment(value * 2 - 1, 0),
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.15),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PlayButton extends StatelessWidget {
  const PlayButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.line, width: 1.5),
        color: Colors.white.withOpacity(0.02),
      ),
      child: const Icon(Icons.pause_rounded, color: AppColors.text, size: 54),
    );
  }
}

class BottomItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const BottomItem({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.sub, size: 28),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: AppColors.sub, fontSize: 13, fontWeight: FontWeight.w300),
        ),
      ],
    );
  }
}
