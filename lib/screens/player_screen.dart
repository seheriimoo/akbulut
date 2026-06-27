import 'package:flutter/material.dart';

class PlayerScreen extends StatelessWidget {
  final String sessionId;
  final String title;

  const PlayerScreen({
    super.key,
    required this.sessionId,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          "$title\n($sessionId)",
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
    );
  }
}