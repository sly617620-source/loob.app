import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loob/models/product_model.dart';
import 'package:loob/models/review_model.dart';
import 'package:loob/services/app_controller.dart';
import 'package:loob/theme/app_colors.dart';
import 'checkout_screen.dart';
import 'package:loob/providers/app_provider.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;
  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _selectedTab = 0;
  final _reviewController = TextEditingController();
  double _reviewRating = 5;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppProvider.of(context);
    final reviews = controller.getProductReviews(widget.product.id);
    final isInCart = controller.cart.any((p) => p.id == widget.product.id);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('تفاصيل المنتج'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () => _showShareOptions(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.surface, AppColors.card],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.product.type == ProductType.course
                          ? '🎓'
                          : widget.product.type == ProductType.license
                              ? '🔐'
                              : widget.product.type == ProductType.ugc
                                  ? '🎬'
                                  : '📦',
                      style: const TextStyle(fontSize: 64),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    widget.product.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${widget.product.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.product.isOnSale)
                      Text(
                        '\$${widget.product.originalPrice!.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    if (widget.product.isOnSale)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '-${widget.product.discountPercent.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.accent,
                  child: Text(
                    widget.product.sellerAvatar,
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  widget.product.sellerName,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified,
                          color: AppColors.success, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'بائع موثوق',
                        style: TextStyle(
                          color: AppColors.success.withValues(alpha: 0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.star, color: AppColors.warning, size: 20),
                Text(
                  ' ${widget.product.rating}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  ' (${widget.product.reviewsCount} تقييم)',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                const Spacer(),
                Text(
                  '${widget.product.salesCount} مبيع',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildTab('الوصف', 0),
                _buildTab('المميزات', 1),
                _buildTab('المراجعات', 2),
                _buildTab('الترخيص', 3),
              ],
            ),
            const SizedBox(height: 16),
            if (_selectedTab == 0) _buildDescriptionTab(),
            if (_selectedTab == 1) _buildFeaturesTab(),
            if (_selectedTab == 2) _buildReviewsTab(reviews, controller),
            if (_selectedTab == 3) _buildLicenseTab(),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CheckoutScreen(product: widget.product),
                      ),
                    ),
                    child: const Text(
                      'شراء الآن',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isInCart
                          ? AppColors.error.withValues(alpha: 0.2)
                          : AppColors.surface,
                      foregroundColor: isInCart ? AppColors.error : Colors.white,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      if (isInCart) {
                        controller.removeFromCart(widget.product.id);
                      } else {
                        controller.addToCart(widget.product);
                      }
                      setState(() {});
                    },
                    child: Text(
                      isInCart ? 'إزالة 🗑️' : 'السلة 🛒',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.accent : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? AppColors.accent : AppColors.textMuted,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionTab() {
    return Text(
      widget.product.description,
      style: const TextStyle(
        color: AppColors.textSecondary,
        height: 1.6,
        fontSize: 14,
      ),
    );
  }

  Widget _buildFeaturesTab() {
    return Column(
      children: widget.product.features.map((f) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('✅', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                f,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildReviewsTab(List<Review> reviews, AppController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'أضف تقييمك',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (i) => GestureDetector(
                  onTap: () => setState(() => _reviewRating = i + 1.0),
                  child: Icon(
                    Icons.star,
                    color: i < _reviewRating ? AppColors.warning : AppColors.textMuted,
                    size: 28,
                  ),
                )),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _reviewController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.background.withValues(alpha: 0.5),
                  hintText: 'اكتب مراجعتك...',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    if (_reviewController.text.isNotEmpty) {
                      final review = Review(
                        id: 'rev_${DateTime.now().millisecondsSinceEpoch}',
                        productId: widget.product.id,
                        userId: controller.user?.id ?? 'guest',
                        userName: controller.user?.name ?? 'زائر',
                        userAvatar: controller.user?.avatar ?? '👤',
                        rating: _reviewRating,
                        comment: _reviewController.text,
                        createdAt: DateTime.now(),
                      );
                      controller.addReview(review);
                      _reviewController.clear();
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ تم إضافة المراجعة'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  },
                  child: const Text('إرسال التقييم'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...reviews.map((r) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.accent,
                    child: Text(r.userAvatar, style: const TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            ...List.generate(5, (i) => Icon(
                              Icons.star,
                              color: i < r.rating ? AppColors.warning : AppColors.textMuted,
                              size: 14,
                            )),
                            const SizedBox(width: 8),
                            Text(
                              _formatDate(r.createdAt),
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(r.comment, style: const TextStyle(color: AppColors.textSecondary, height: 1.5)),
              if (r.sellerReply != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('💬', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'رد البائع: ${r.sellerReply}',
                          style: const TextStyle(color: AppColors.accent, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.thumb_up, size: 14, color: AppColors.textMuted),
                    label: Text(
                      'مفيد (${r.helpfulCount})',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildLicenseTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.shield, color: AppColors.warning),
                  SizedBox(width: 8),
                  Text(
                    'معلومات الترخيص',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.product.type == ProductType.license
                    ? 'هذا المنتج يتضمن ترخيص برمجي صالح لسنة واحدة.'
                    : widget.product.type == ProductType.course
                        ? 'الدورة متاحة مدى الحياة بعد الشراء.'
                        : 'هذا المنتج رقمي متاح للتحميل الفوري.',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showShareOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'مشاركة المنتج',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Text('🔗', style: TextStyle(fontSize: 24)),
              title: const Text(
                'نسخ الرابط',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(ctx);
                Clipboard.setData(
                  ClipboardData(text: 'https://loob.app/product/${widget.product.id}'),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ تم نسخ الرابط')),
                );
              },
            ),
            ListTile(
              leading: const Text('📱', style: TextStyle(fontSize: 24)),
              title: const Text(
                'مشاركة عبر واتساب',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return 'منذ ${diff.inDays} يوم';
    if (diff.inHours > 0) return 'منذ ${diff.inHours} ساعة';
    return 'منذ قليل';
  }
}
