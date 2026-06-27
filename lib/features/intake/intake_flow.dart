import 'package:flutter/material.dart';
import '../player/player_screen.dart';

class IntakeFlow extends StatefulWidget {
  const IntakeFlow({super.key});

  @override
  State<IntakeFlow> createState() => _IntakeFlowState();
}

class _IntakeFlowState extends State<IntakeFlow> {
  String? blocker;
  String? sleepLatency;
  String? energy;
  String? goal;

  int sessionLength = 30;

  bool get canStart =>
      blocker != null &&
      sleepLatency != null &&
      energy != null &&
      goal != null;

  bool get isPremiumSession => sessionLength > 30;

  Widget _optionChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black12),
          boxShadow: const [
            BoxShadow(
              blurRadius: 10,
              offset: Offset(0, 4),
              color: Color(0x11000000),
            )
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color: selected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _questionBlock({
    required String title,
    required List<String> options,
    required String? value,
    required void Function(String) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          for (final opt in options)
            _optionChip(
              label: opt,
              selected: value == opt,
              onTap: () => setState(() => onChanged(opt)),
            ),
        ],
      ),
    );
  }

  Widget _sessionLengthBlock() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "5) How long should tonight’s session be?",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _optionChip(
            label: "30 minutes (Free)",
            selected: sessionLength == 30,
            onTap: () => setState(() => sessionLength = 30),
          ),
          _optionChip(
            label: "45 minutes (Premium)",
            selected: sessionLength == 45,
            onTap: () => setState(() => sessionLength = 45),
          ),
          _optionChip(
            label: "60 minutes (Premium)",
            selected: sessionLength == 60,
            onTap: () => setState(() => sessionLength = 60),
          ),
        ],
      ),
    );
  }

  void _openPlayer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          blocker: blocker!,
          sleepLatency: sleepLatency!,
          energy: energy!,
          goal: goal!,
          sessionLength: Duration(minutes: sessionLength),
        ),
      ),
    );
  }

  void _showPaywall() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0B1224),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Unlock Full Experience',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'The ${sessionLength}-minute session is part of the premium experience. Upgrade to unlock longer sleep sessions.',
          style: const TextStyle(
            color: Colors.white70,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Later',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Connect real paywall screen here
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0B1224),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  void _handleStart() {
    if (!canStart) return;

    if (isPremiumSession) {
      _showPaywall();
    } else {
      _openPlayer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Somnia',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            const SizedBox(height: 6),
            const Text(
              "Tonight, let's personalize your session.",
              style: TextStyle(fontSize: 18, color: Colors.black87),
            ),
            const SizedBox(height: 18),

            _questionBlock(
              title: "1) What's the biggest blocker right now?",
              options: const [
                "My mind won't stop",
                "Body tension",
                "Inner restlessness",
              ],
              value: blocker,
              onChanged: (v) => blocker = v,
            ),

            _questionBlock(
              title: "2) Is falling asleep hard for you?",
              options: const ["Yes", "Sometimes", "No"],
              value: sleepLatency,
              onChanged: (v) => sleepLatency = v,
            ),

            _questionBlock(
              title: "3) How is your energy right now?",
              options: const ["High", "Medium", "Low"],
              value: energy,
              onChanged: (v) => energy = v,
            ),

            _questionBlock(
              title: "4) What do you want tonight?",
              options: const [
                "Slow my mind",
                "Release my body",
                "Let go of control",
              ],
              value: goal,
              onChanged: (v) => goal = v,
            ),

            _sessionLengthBlock(),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: canStart ? _handleStart : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                disabledBackgroundColor: Colors.black26,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(
                !canStart
                    ? "Answer all to continue"
                    : isPremiumSession
                        ? "Unlock Premium Session"
                        : "Start Free Session",
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),

            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}