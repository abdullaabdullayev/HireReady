import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/interactions.dart';
import 'auth_screen.dart';

/// Welcome screen with value props → Sign up / Log in.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Container(
                height: 72,
                width: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: AppColors.brandGradient),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 38),
              ),
              const SizedBox(height: 28),
              const Text('Ace your next\ninterview.',
                  style: TextStyle(fontSize: 38, fontWeight: FontWeight.w800, height: 1.1, letterSpacing: -1)),
              const SizedBox(height: 16),
              const Text(
                'Practice real interview questions tailored to your role, answer by text or voice, and get instant AI feedback.',
                style: TextStyle(fontSize: 16, color: AppColors.inkSoft, height: 1.5),
              ),
              const SizedBox(height: 32),
              const _Feature(icon: Icons.upload_file_rounded, text: 'Upload your resume for tailored questions'),
              const _Feature(icon: Icons.mic_rounded, text: 'Answer by typing or speaking'),
              const _Feature(icon: Icons.auto_awesome_rounded, text: 'Instant AI scoring & explanations'),
              const Spacer(),
              ElevatedButton(
                onPressed: () => _go(context, startOnSignUp: true),
                child: const Text('Get started'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => _go(context, startOnSignUp: false),
                child: const Text('I already have an account'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _go(BuildContext context, {required bool startOnSignUp}) {
    HapticType.light.fire();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AuthScreen(startOnSignUp: startOnSignUp)),
    );
  }
}

class _Feature extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Feature({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.inkSoft))),
        ],
      ),
    );
  }
}
