import 'package:flutter/material.dart';

class SleepAnalysisScreen extends StatelessWidget {
  const SleepAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090B12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Sleep Analysis'),
      ),
      body: const Center(
        child: Text(
          'Sleep Analysis Screen (Coming Next)',
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}