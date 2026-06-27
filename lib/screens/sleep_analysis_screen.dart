import 'package:flutter/material.dart';

import '../engines/sleep_analysis_engine.dart';
import '../models/sleep_analysis_result.dart';
import 'sleep_plan_screen.dart';

class SleepAnalysisScreen extends StatefulWidget {
  const SleepAnalysisScreen({super.key});

  @override
  State<SleepAnalysisScreen> createState() => _SleepAnalysisScreenState();
}

class _SleepAnalysisScreenState extends State<SleepAnalysisScreen> {
  final Map<int, int> answers = {};
  final TextEditingController noteController = TextEditingController();

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  Widget buildQuestion({
    required int index,
    required String question,
    required List<String> options,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 18),
          ...List.generate(options.length, (i) {
            final selected = answers[index] == i;

            return GestureDetector(
              onTap: () {
                setState(() {
                  answers[index] = i;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: selected
                          ? const Color(0xFF8FB6FF)
                          : Colors.white.withOpacity(0.55),
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        options[i],
                        style: TextStyle(
                          fontSize: 18,
                          color: selected
                              ? Colors.white
                              : Colors.white.withOpacity(0.88),
                          fontWeight:
                              selected ? FontWeight.w500 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          Divider(
            height: 34,
            thickness: 1,
            color: Colors.white.withOpacity(0.08),
          ),
        ],
      ),
    );
  }

  List<int> _buildAnswersForEngine() {
    return [
      answers[1] ?? 0,
      answers[2] ?? 0,
      answers[3] ?? 0,
      answers[4] ?? 0,
      answers[5] ?? 0,
      answers[6] ?? 0,
    ];
  }

  void _analyzeAndContinue() {
    final SleepAnalysisResult result = SleepAnalysisEngine.analyze(
      answers: _buildAnswersForEngine(),
      extraNote: noteController.text.trim(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SleepPlanScreen(result: result),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050B1A),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).maybePop(),
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.10),
                              ),
                              color: Colors.white.withOpacity(0.03),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 18),
                        const Expanded(
                          child: Text(
                            'Sleep Analysis',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Let’s understand your sleep patterns and create the most suitable experience for tonight.',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: Colors.white.withOpacity(0.58),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.white.withOpacity(0.08),
                    ),
                    const SizedBox(height: 28),
                    buildQuestion(
                      index: 1,
                      question: 'How quiet is your mind when trying to sleep?',
                      options: const [
                        'Calm',
                        'Slightly active',
                        'Very active',
                      ],
                    ),
                    buildQuestion(
                      index: 2,
                      question: 'How much stress or tension do you feel right now?',
                      options: const [
                        'None',
                        'Moderate',
                        'High',
                      ],
                    ),
                    buildQuestion(
                      index: 3,
                      question: 'Do you use your phone before sleep?',
                      options: const [
                        'No',
                        '10–30 min',
                        'More than 1 hour',
                      ],
                    ),
                    buildQuestion(
                      index: 4,
                      question: 'Is your sleep schedule consistent?',
                      options: const [
                        'Yes',
                        'Sometimes',
                        'No',
                      ],
                    ),
                    buildQuestion(
                      index: 5,
                      question:
                          'Does your body feel tired but you still can’t sleep?',
                      options: const [
                        'No',
                        'Sometimes',
                        'Yes',
                      ],
                    ),
                    buildQuestion(
                      index: 6,
                      question: 'Do you feel emotionally overwhelmed right now?',
                      options: const [
                        'No',
                        'A little',
                        'Yes',
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Did anything affect you today? (optional)',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.10),
                        ),
                        color: Colors.white.withOpacity(0.03),
                      ),
                      child: TextField(
                        controller: noteController,
                        maxLines: 5,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Write here if you want…',
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.35),
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 74,
                child: ElevatedButton(
                  onPressed: _analyzeAndContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A243A),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                      side: BorderSide(
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ),
                  child: const Text(
                    'Get my sleep plan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
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