import 'package:flutter/material.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget star({
    required double top,
    required double left,
    required double size,
    double opacity = 0.9,
  }) {
    return Positioned(
      top: top,
      left: left,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(opacity),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(opacity * 0.45),
              blurRadius: size * 3,
              spreadRadius: 0.2,
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    final screen = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,

        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF020611),
              Color(0xFF071B3A),
              Color(0xFF000000),
            ],
          ),
        ),

        child: Stack(
          children: [

            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.12),
                    radius: 0.95,
                    colors: [
                      Color(0x1A9DBDFF),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              top: -90,
              right: -70,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.03),
                ),
              ),
            ),

            star(top: 110, left: 34, size: 2.2),
            star(top: 160, left: 82, size: 1.7, opacity: 0.72),
            star(top: 210, left: screen.width - 54, size: 2.7),
            star(top: 290, left: 55, size: 1.8, opacity: 0.76),
            star(top: 360, left: screen.width - 76, size: 2.1, opacity: 0.84),
            star(top: 500, left: 28, size: 2.0),
            star(top: 610, left: screen.width - 50, size: 2.4),
            star(top: 760, left: 48, size: 1.8, opacity: 0.74),
            star(top: 880, left: screen.width - 66, size: 2.3),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [

                    const SizedBox(height: 14),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Somnia',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.92),
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),

                    const Spacer(),

                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {

                        final t =
                            Curves.easeInOut.transform(_controller.value);

                        final scale = 1.0 + (t * 0.03);

                        return Transform.scale(
                          scale: scale,
                          child: child,
                        );
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [

                          Container(
                            width: 300,
                            height: 300,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [

                                BoxShadow(
                                  color: Colors.white.withOpacity(0.08),
                                  blurRadius: 110,
                                  spreadRadius: 18,
                                ),

                                BoxShadow(
                                  color: const Color(0xFFBFD2FF)
                                      .withOpacity(0.12),
                                  blurRadius: 80,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                          ),

                          Container(
                            width: 230,
                            height: 230,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.07),
                                width: 1,
                              ),
                            ),
                          ),

                          Container(
                            width: 180,
                            height: 180,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                center: Alignment(-0.18, -0.20),
                                radius: 1,
                                colors: [
                                  Color(0xFFFFFFFF),
                                  Color(0xFFF2F6FB),
                                  Color(0xFFDCE5F0),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white24,
                                  blurRadius: 24,
                                  spreadRadius: 1,
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    const Text(
                      'Your sleep starts here',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.8,
                        height: 1.1,
                      ),
                    ),

                    const SizedBox(height: 14),

                    Text(
                      'Answer a few questions to create your perfect sleep experience.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.60),
                        fontSize: 16,
                        height: 1.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    const Spacer(),

                    Container(
                      width: double.infinity,
                      height: 64,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFF5F7FA),
                            Color(0xFFE1E6EF),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.14),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Material(
                        type: MaterialType.transparency,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(32),
                          onTap: () {},
                          child: const Center(
                            child: Text(
                              'Start',
                              style: TextStyle(
                                color: Color(0xFF0B0E14),
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 34),
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