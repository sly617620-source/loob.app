import 'package:flutter/material.dart';
import '../../models/submission_model.dart';
import '../../theme/app_colors.dart';
import '../../providers/app_provider.dart';

/// "تقديماتي" - tracks a content creator's submissions and their status
/// across all campaigns they've submitted to.
class MySubmissionsScreen extends StatelessWidget {
  const MySubmissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppProvider.of(context);
    final user = controller.user!;
    final submissions = controller.getSubmissionsForUser(user.id);

    final approvedEarnings = submissions
        .where((s) => s.isApproved || s.isPaid)
        .fold<double>(0, (sum, s) => sum + (s.reward ?? 0));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('تقديماتي')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(child: _statCard('📨', 'إجمالي التقديمات', '${submissions.length}', AppColors.accent)),
                const SizedBox(width: 12),
                Expanded(child: _statCard('💰', 'الأرباح', '\$${approvedEarnings.toStringAsFixed(0)}', AppColors.success)),
              ],
            ),
          ),
          Expanded(
            child: submissions.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('📭', style: TextStyle(fontSize: 48)),
                        SizedBox(height: 8),
                        Text('لم تقدّم على أي حملة بعد', style: TextStyle(color: AppColors.textMuted)),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: submissions.map((s) => _SubmissionCard(submission: s)).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String emoji, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.card.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  final Submission submission;
  const _SubmissionCard({required this.submission});

  static const _statusLabel = {
    SubmissionStatus.pending: 'قيد المراجعة',
    SubmissionStatus.approved: 'مقبول',
    SubmissionStatus.rejected: 'مرفوض',
    SubmissionStatus.paid: 'تم الدفع',
    SubmissionStatus.cancelled: 'ملغى',
  };
  static const _statusColor = {
    SubmissionStatus.pending: AppColors.warning,
    SubmissionStatus.approved: AppColors.success,
    SubmissionStatus.rejected: AppColors.error,
    SubmissionStatus.paid: AppColors.accent,
    SubmissionStatus.cancelled: AppColors.textMuted,
  };

  @override
  Widget build(BuildContext context) {
    final color = _statusColor[submission.status]!;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.card.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  submission.contentUrl ?? '',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: Text(_statusLabel[submission.status]!, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          if ((submission.caption ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(submission.caption!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
          if (submission.status == SubmissionStatus.rejected && (submission.feedback ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('السبب: ${submission.feedback}', style: const TextStyle(color: AppColors.error, fontSize: 11)),
          ],
          const SizedBox(height: 8),
          Text(
            '${submission.platform ?? ''} • \$${(submission.reward ?? 0).toStringAsFixed(1)} • ${_relativeTime(submission.submittedAt)}',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  String _relativeTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return 'منذ ${diff.inDays} يوم';
    if (diff.inHours > 0) return 'منذ ${diff.inHours} ساعة';
    return 'منذ قليل';
  }
}
