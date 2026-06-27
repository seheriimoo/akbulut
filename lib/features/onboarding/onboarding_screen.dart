import 'package:flutter/material.dart';

import '../../models/user_sleep_profile.dart';
import '../../services/sleep_session_selector.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _sleepLatency = 20;
  bool _racingThoughts = false;
  int _stressLevel = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050608),
      appBar: AppBar(
        title: const Text('Uyku Ayarı'),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Uykuya dalmanız ne kadar sürüyor?',
              style: TextStyle(fontSize: 18),
            ),
            Slider(
              value: _sleepLatency.toDouble(),
              min: 5,
              max: 60,
              divisions: 11,
              label: '$_sleepLatency dk',
              onChanged: (v) {
                setState(() {
                  _sleepLatency = v.round();
                });
              },
            ),
            const SizedBox(height: 30),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Zihninizde hızlı düşünceler oluyor mu?'),
              value: _racingThoughts,
              onChanged: (v) {
                setState(() {
                  _racingThoughts = v;
                });
              },
            ),
            const SizedBox(height: 30),
            const Text(
              'Bugünkü stres seviyeniz',
              style: TextStyle(fontSize: 18),
            ),
            Slider(
              value: _stressLevel.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: '$_stressLevel',
              onChanged: (v) {
                setState(() {
                  _stressLevel = v.round();
                });
              },
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final profile = UserSleepProfile(
                    sleepLatency: _sleepLatency,
                    racingThoughts: _racingThoughts,
                    stressLevel: _stressLevel,
                  );

                  final session =
                      SleepSessionSelector.chooseSession(profile);

                  Navigator.pop(context, session);
                },
                child: const Text('Devam Et'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}