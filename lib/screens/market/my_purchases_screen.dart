import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/order_model.dart';
import '../../theme/app_colors.dart';
import '../../providers/app_provider.dart';

class MyPurchasesScreen extends StatelessWidget {
  const MyPurchasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppProvider.of(context);
    final orders = controller.orders
        .where((o) => o.buyerId == controller.user!.id)
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('مشترياتي')),
      body: orders.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🛍️', style: TextStyle(fontSize: 64)),
                  SizedBox(height: 16),
                  Text(
                    'لم تقم بأي مشتريات بعد',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              order.productTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: order.status == OrderStatus.completed
                                  ? AppColors.success.withValues(alpha: 0.2)
                                  : AppColors.warning.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              order.status == OrderStatus.completed
                                  ? 'مكتمل'
                                  : 'قيد المعالجة',
                              style: TextStyle(
                                color: order.status == OrderStatus.completed
                                    ? AppColors.success
                                    : AppColors.warning,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'المبلغ: \$${order.amount.toStringAsFixed(2)}',
                            style:
                                const TextStyle(color: AppColors.textSecondary),
                          ),
                          Text(
                            _formatDate(order.createdAt),
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      if (order.licenseKey != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.key,
                                  color: AppColors.accent, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'مفتاح الترخيص: ${order.licenseKey}',
                                  style: const TextStyle(
                                    color: AppColors.accent,
                                    fontSize: 13,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy,
                                    color: AppColors.accent, size: 18),
                                onPressed: () {
                                  Clipboard.setData(
                                      ClipboardData(text: order.licenseKey!));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('✅ تم نسخ المفتاح')),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (order.status == OrderStatus.completed) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  AppColors.success.withValues(alpha: 0.2),
                              foregroundColor: AppColors.success,
                            ),
                            onPressed: () {},
                            child: const Text('⬇️ تحميل المنتج'),
                          ),
                        ),
                      ],
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
