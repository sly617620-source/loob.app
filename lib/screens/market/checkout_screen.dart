import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../models/coupon_model.dart';
import '../../services/app_controller.dart';
import '../../theme/app_colors.dart';
import '../../providers/app_provider.dart';

class CheckoutScreen extends StatefulWidget {
  final Product product;
  const CheckoutScreen({super.key, required this.product});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _couponController = TextEditingController();
  Coupon? _appliedCoupon;
  double _discountAmount = 0;
  String _selectedPayment = 'wallet';

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppProvider.of(context);
    final finalPrice = widget.product.price - _discountAmount;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('إتمام الشراء')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.accent, AppColors.accentLight],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        widget.product.sellerAvatar,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${widget.product.price.toStringAsFixed(2)}',
                          style: const TextStyle(color: AppColors.accent),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'كوبون الخصم',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _couponController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.card.withValues(alpha: 0.8),
                      hintText: 'أدخل كود الكوبون',
                      hintStyle: const TextStyle(color: AppColors.textMuted),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _applyCoupon(controller),
                  child: const Text('تطبيق'),
                ),
              ],
            ),
            if (_appliedCoupon != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.success, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'تم تطبيق كوبون ${_appliedCoupon!.code} (خصم ${_appliedCoupon!.discountPercent}%)',
                      style: const TextStyle(color: AppColors.success),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.card.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildPriceRow('سعر المنتج', widget.product.price),
                  if (_discountAmount > 0)
                    _buildPriceRow('الخصم', -_discountAmount, color: AppColors.success),
                  const Divider(color: AppColors.textMuted),
                  _buildPriceRow('الإجمالي', finalPrice, isBold: true),
                  if (widget.product.isPayAsYouSell)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '💡 نموذج الدفع عند البيع: البائع يدفع 10% فقط عند كل عملية بيع',
                        style: TextStyle(
                          color: AppColors.accent.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'طريقة الدفع',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildPaymentMethod('💰', 'رصيد المحفظة', 'wallet', controller.user?.balance ?? 0),
            _buildPaymentMethod('💳', 'بطاقة ائتمانية', 'card', null),
            _buildPaymentMethod('🅿️', 'PayPal', 'paypal', null),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _completePurchase(controller, finalPrice),
                child: const Text(
                  'تأكيد الشراء',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isBold ? Colors.white : AppColors.textSecondary,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '\$${amount.abs().toStringAsFixed(2)}',
            style: TextStyle(
              color: color ?? (isBold ? AppColors.accent : Colors.white),
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod(String icon, String label, String value, double? balance) {
    final isSelected = _selectedPayment == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedPayment = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent.withValues(alpha: 0.1) : AppColors.card.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.accent : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                  if (balance != null)
                    Text(
                      'المتاح: \$${balance.toStringAsFixed(2)}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: AppColors.accent),
          ],
        ),
      ),
    );
  }

  void _applyCoupon(AppController controller) {
    final code = _couponController.text.trim().toUpperCase();
    try {
      final coupon = controller.coupons.firstWhere(
        (c) => c.code == code && c.isValid,
      );
      setState(() {
        _appliedCoupon = coupon;
        final discount = widget.product.price * (coupon.discountPercent / 100);
        _discountAmount = coupon.maxDiscount != null && discount > coupon.maxDiscount! ? coupon.maxDiscount! : discount;
      });
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ كوبون غير صالح'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _completePurchase(AppController controller, double finalPrice) async {
    // حماية ضد الوجود null للمستخدم
    if (controller.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب تسجيل الدخول لإجراء عملية الشراء'), backgroundColor: AppColors.error),
      );
      return;
    }

    await controller.purchaseProduct(
      widget.product.id,
      controller.user!.id,
      couponCode: _appliedCoupon?.code,
    );

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.card,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              const Text(
                'تم الشراء بنجاح!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'يمكنك الآن تحميل المنتج من قسم مشترياتي',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('الذهاب للمشتريات'),
              ),
            ],
          ),
        ),
      );
    }
  }
}
