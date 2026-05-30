import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import '../models/app_models.dart';
import '../widgets/common.dart';

/// Review the questions the user got wrong or flagged.
class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = AppState.instance.reviewList;
    return Scaffold(
      appBar: AppBar(title: const Text('Review questions')),
      body: SafeArea(
        child: items.isEmpty
            ? const _Empty()
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (_, i) => _ReviewCard(record: items[i], index: i + 1),
              ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final AnswerRecord record;
  final int index;
  const _ReviewCard({required this.record, required this.index});

  @override
  Widget build(BuildContext context) {
    final q = record.question;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TagPill(text: q.category, icon: Icons.category_rounded),
              const Spacer(),
              if (record.markedForReview)
                const TagPill(text: 'Flagged', color: AppColors.warning, icon: Icons.bookmark_rounded)
              else
                const TagPill(text: 'Incorrect', color: AppColors.danger, icon: Icons.close_rounded),
            ],
          ),
          const SizedBox(height: 14),
          Text(q.prompt, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.35)),
          const SizedBox(height: 14),
          if (record.textAnswer != null && record.textAnswer!.trim().isNotEmpty) ...[
            _block('Your answer', record.textAnswer!.trim(), AppColors.muted),
            const SizedBox(height: 10),
          ],
          _block('Model answer', q.modelAnswer, AppColors.info),
        ],
      ),
    );
  }

  Widget _block(String title, String body, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: color)),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(fontSize: 13.5, height: 1.4, color: AppColors.inkSoft)),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 72,
            width: 72,
            decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(22)),
            child: const Icon(Icons.celebration_rounded, color: AppColors.accent, size: 36),
          ),
          const SizedBox(height: 18),
          const Text('Nothing to review', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('You aced every question.', style: TextStyle(color: AppColors.muted)),
        ],
      ),
    );
  }
}
