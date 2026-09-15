import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../providers/app_provider.dart';

class CouponsScreen extends StatelessWidget {
  const CouponsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppProvider.of(context);
    final coupons = controller.coupons;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('الكوبونات والخصومات')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: coupons.length,
        itemBuilder: (context, index) {
          final coupon = coupons[index];
          final isValid = coupon.isValid;
          final discount = coupon.discountPercent;
          final used = coupon.usedCount;
          final maxUses = coupon.maxUses;
          final validUntil = coupon.validUntil;

          final progress = (maxUses != null && maxUses > 0) ? (used / maxUses).clamp(0.0, 1.0) : 0.0;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: isValid
                  ? const LinearGradient(
                      colors: [Color(0xFF1F263F), Color(0xFF2A3454)],
                    )
                  : null,
              color: isValid ? null : AppColors.card.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isValid ? AppColors.accent.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isValid ? AppColors.accent.withValues(alpha: 0.2) : AppColors.textMuted.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isValid ? AppColors.accent.withValues(alpha: 0.5) : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        coupon.code,
                        style: TextStyle(
                          color: isValid ? AppColors.accent : AppColors.textMuted,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (!isValid)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'منتهي',
                          style: TextStyle(color: AppColors.error, fontSize: 12),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'خصم $discount%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'صالح حتى: ${_formatDate(validUntil)}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(isValid ? AppColors.accent : AppColors.textMuted),
                ),
                const SizedBox(height: 8),
                Text(
                  "تم الاستخدام: $used / ${maxUses ?? '∞'}",
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
