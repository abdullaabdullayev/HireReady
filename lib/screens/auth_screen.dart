import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/interactions.dart';
import 'dashboard_screen.dart';

/// Combined Sign up / Log in screen (UI only — no real auth).
class AuthScreen extends StatefulWidget {
  final bool startOnSignUp;
  const AuthScreen({super.key, required this.startOnSignUp});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late bool _signUp = widget.startOnSignUp;
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_signUp ? 'Create your account' : 'Welcome back',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              const SizedBox(height: 8),
              Text(
                _signUp ? 'Start practicing in under a minute.' : 'Log in to continue your prep.',
                style: const TextStyle(fontSize: 15, color: AppColors.inkSoft),
              ),
              const SizedBox(height: 28),

              // Segmented toggle
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    _segment('Sign up', _signUp, () {
                      HapticType.selection.fire();
                      setState(() => _signUp = true);
                    }),
                    _segment('Log in', !_signUp, () {
                      HapticType.selection.fire();
                      setState(() => _signUp = false);
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (_signUp) ...[
                _label('Full name'),
                const TextField(
                  stylusHandwritingEnabled: false,
                  decoration: InputDecoration(hintText: 'Abdulla Abdullayev'),
                ),
                const SizedBox(height: 16),
              ],
              _label('Email'),
              const TextField(
                keyboardType: TextInputType.emailAddress,
                stylusHandwritingEnabled: false,
                decoration: InputDecoration(hintText: 'you@example.com', prefixIcon: Icon(Icons.mail_outline_rounded)),
              ),
              const SizedBox(height: 16),
              _label('Password'),
              TextField(
                obscureText: _obscure,
                stylusHandwritingEnabled: false,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              if (!_signUp) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(onPressed: () {}, child: const Text('Forgot password?')),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  HapticType.light.fire();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const DashboardScreen()),
                    (route) => false,
                  );
                },
                child: Text(_signUp ? 'Create account' : 'Log in'),
              ),
              const SizedBox(height: 20),
              Row(children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('or continue with', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                ),
                const Expanded(child: Divider()),
              ]),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _social(Icons.g_mobiledata_rounded, 'Google')),
                  const SizedBox(width: 12),
                  Expanded(child: _social(Icons.apple_rounded, 'Apple')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _segment(String text, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: active ? kCardShadow : null,
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: active ? AppColors.primary : AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
      );

  Widget _social(IconData icon, String label) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 24),
      label: Text(label),
      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
    );
  }
}
