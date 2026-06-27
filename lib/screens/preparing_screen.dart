import 'package:flutter/material.dart';
import '../features/player/player_screen.dart';

class PreparingScreen extends StatefulWidget {
  final String blocker;

  const PreparingScreen({super.key, required this.blocker});

  @override
  State<PreparingScreen> createState() => _PreparingScreenState();
}

class _PreparingScreenState extends State<PreparingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _scale = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(const Duration(seconds: 20), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PlayerScreen(
            blocker: widget.blocker,
            sleepLatency: "15",
            energy: "40",
            goal: "sleep",
            sessionLength: const Duration(minutes: 30),
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String getTitle() {
    switch (widget.blocker) {
      case "overthinking":
        return "Your mind is slowing down...";
      case "stress":
        return "Your body is releasing tension...";
      case "physical":
        return "Your body is relaxing...";
      default:
        return "Your system is slowing down...";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF02030A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, 0.3),
            radius: 0.9,
            colors: [
              Color(0xFF0B1224),
              Color(0xFF02030A),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _scale,
                builder: (_, child) {
                  return Transform.scale(
                    scale: _scale.value,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.blue.withOpacity(0.25),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              Text(
                getTitle(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "Let it happen...",
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}