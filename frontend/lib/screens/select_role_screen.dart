import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import '../models/app_models.dart';
import '../widgets/common.dart';
import 'select_level_screen.dart';

/// Step 1 — pick the job role to practice for.
class SelectRoleScreen extends StatefulWidget {
  /// When launched from a role chip, the role is preselected and we still let
  /// the user confirm before moving on.
  final bool skipToLevel;
  const SelectRoleScreen({super.key, this.skipToLevel = false});

  @override
  State<SelectRoleScreen> createState() => _SelectRoleScreenState();
}

class _SelectRoleScreenState extends State<SelectRoleScreen> {
  JobRole? _selected;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = AppState.instance.selectedRole;
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    final roles = state.roles
        .where((r) => r.title.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Choose a role')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Column(
                children: [
                  const StepDots(current: 1, total: 4),
                  const SizedBox(height: 18),
                  TextField(
                    onChanged: (v) => setState(() => _query = v),
                    stylusHandwritingEnabled: false,
                    decoration: const InputDecoration(
                      hintText: 'Search roles…',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.05,
                ),
                itemCount: roles.length,
                itemBuilder: (_, i) {
                  final role = roles[i];
                  final selected = _selected?.id == role.id;
                  return GestureDetector(
                    onTap: () => setState(() => _selected = role),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: kCardShadow,
                        border: Border.all(
                          color: selected ? role.color : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                height: 46,
                                width: 46,
                                decoration: BoxDecoration(
                                    color: role.color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(14)),
                                child: Icon(role.icon, color: role.color, size: 24),
                              ),
                              const Spacer(),
                              if (selected)
                                Icon(Icons.check_circle_rounded, color: role.color, size: 22),
                            ],
                          ),
                          const Spacer(),
                          Text(role.title,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, height: 1.2)),
                          const SizedBox(height: 4),
                          Text(role.category,
                              style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            FlowBottomBar(
              enabled: _selected != null,
              onNext: () {
                AppState.instance.selectedRole = _selected;
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SelectLevelScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
