import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import '../data/mock_data.dart';
import '../widgets/common.dart';
import '../services/auth_service.dart';
import 'welcome_screen.dart';

/// Profile / settings tab (UI only).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        const Text('Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        const SizedBox(height: 20),

        // Profile header
        AppCard(
          child: Row(
            children: [
              Container(
                height: 64,
                width: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: AppColors.brandGradient),
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(state.userName[0],
                    style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(state.userName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    const Text('abdullaabdullayev2402@gmail.com',
                        style: TextStyle(color: AppColors.muted, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.edit_rounded, color: AppColors.muted, size: 20),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Documents
        const SectionHeader('My documents'),
        const SizedBox(height: 12),
        ...MockData.sampleResources.map((r) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: kCardShadow,
              ),
              child: Row(
                children: [
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.danger, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        Text('${r.type} • ${r.size}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.more_horiz_rounded, color: AppColors.muted),
                ],
              ),
            )),
        const SizedBox(height: 20),

        const SectionHeader('Settings'),
        const SizedBox(height: 12),
        _settingsGroup([
          _row(Icons.notifications_rounded, 'Notifications', AppColors.primary),
          _row(Icons.workspace_premium_rounded, 'Upgrade to Pro', AppColors.warning),
          _row(Icons.help_outline_rounded, 'Help & support', AppColors.info),
          _row(Icons.privacy_tip_rounded, 'Privacy', AppColors.accent),
        ]),
        const SizedBox(height: 20),

        OutlinedButton.icon(
          onPressed: () async {
            await AuthService.logout();
            if (!context.mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const WelcomeScreen()),
              (route) => false,
            );
          },
          icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
          label: const Text('Log out', style: TextStyle(color: AppColors.danger)),
          style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.line, width: 1.5)),
        ),
        const SizedBox(height: 16),
        const Center(child: Text('HireReady v1.0.0', style: TextStyle(color: AppColors.muted, fontSize: 12))),
      ],
    );
  }

  Widget _settingsGroup(List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: kCardShadow,
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i != rows.length - 1) const Divider(indent: 60, endIndent: 16),
          ]
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, Color color) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: Container(
        height: 36,
        width: 36,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
      onTap: () {},
    );
  }
}
