import 'package:flutter/material.dart';

class ContinueScreen extends StatefulWidget {
  const ContinueScreen({super.key});

  @override
  State<ContinueScreen> createState() => _ContinueScreenState();
}

class _ContinueScreenState extends State<ContinueScreen> {
  String selected = '';

  Widget buildOption({
    required String title,
    required String subtitle,
    required String value,
  }) {
    final bool isSelected = selected == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          selected = value;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white24,
            width: 1.2,
          ),
          color: isSelected
              ? Colors.white.withOpacity(0.08)
              : Colors.white.withOpacity(0.03),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void goNext() {
    if (selected == 'chat') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ChatScreen()),
      );
    } else if (selected == 'analysis') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AnalysisScreen()),
      );
    } else if (selected == 'sleep') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SleepScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = selected.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_sleepwave.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.45),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.08),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.15),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'How would you like to continue?',
                    style: TextStyle(
                      fontSize: 26,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Choose the experience that fits you best tonight',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.70),
                    ),
                  ),

                  const SizedBox(height: 36),

                  buildOption(
                    title: 'Talk with a sleep specialist',
                    subtitle: 'Calm your mind and share what’s on it',
                    value: 'chat',
                  ),

                  buildOption(
                    title: 'Get a personalized sleep analysis',
                    subtitle: 'Find the best experience for you',
                    value: 'analysis',
                  ),

                  buildOption(
                    title: 'Start sleep now',
                    subtitle: 'Go straight into your sleep experience',
                    value: 'sleep',
                  ),

                  const Spacer(),

                  GestureDetector(
                    onTap: isEnabled ? goNext : null,
                    child: Container(
                      width: double.infinity,
                      height: 58,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: LinearGradient(
                          colors: isEnabled
                              ? [
                                  Colors.white.withOpacity(0.18),
                                  Colors.white.withOpacity(0.05),
                                ]
                              : [
                                  Colors.white.withOpacity(0.08),
                                  Colors.white.withOpacity(0.03),
                                ],
                        ),
                        border: Border.all(
                          color: isEnabled
                              ? Colors.white.withOpacity(0.35)
                              : Colors.white.withOpacity(0.18),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Continue',
                          style: TextStyle(
                            color: isEnabled
                                ? Colors.white
                                : Colors.white.withOpacity(0.45),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Sleep Specialist'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Text(
          'AI Chat Screen',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 22,
          ),
        ),
      ),
    );
  }
}

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Sleep Analysis'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Text(
          'Sleep Analysis Screen',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 22,
          ),
        ),
      ),
    );
  }
}

class SleepScreen extends StatelessWidget {
  const SleepScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Sleep Experience'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Text(
          'Sleep Audio Screen',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 22,
          ),
        ),
      ),
    );
  }
}