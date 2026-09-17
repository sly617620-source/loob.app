import 'package:flutter/material.dart';
import 'package:loob/models/analytics_model.dart';
import 'package:loob/models/product_model.dart';
import 'package:loob/models/order_model.dart';
import 'package:loob/services/app_controller.dart';
import 'package:loob/theme/app_colors.dart';
import 'package:loob/providers/app_provider.dart';

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final controller = AppProvider.of(context);
    final user = controller.user!;
    final analytics = controller.getSellerAnalytics(user.id);
    final myProducts = controller.products
        .where((p) => p.sellerId == user.id)
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('لوحة البائع'),
        actions: [
          IconButton(
            icon: const Text('➕', style: TextStyle(fontSize: 20)),
            onPressed: () => _showProductForm(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    '💰', 'الإيرادات', 
                    '\$${analytics.totalRevenue.toStringAsFixed(0)}', 
                    AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '📦', 'المبيعات', 
                    '${analytics.totalSales}', 
                    AppColors.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    '👁️', 'المشاهدات', 
                    '${analytics.totalViews}', 
                    AppColors.warning,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '📊', 'التحويل', 
                    '${analytics.conversionRate.toStringAsFixed(1)}%', 
                    AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildTab('منتجاتي', 0),
                _buildTab('التحليلات', 1),
                _buildTab('الطلبات', 2),
              ],
            ),
            const SizedBox(height: 16),
            if (_selectedTab == 0) _buildProductsTab(myProducts, controller),
            if (_selectedTab == 1) _buildAnalyticsTab(analytics),
            if (_selectedTab == 2) _buildOrdersTab(controller),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String emoji, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildProductsTab(List<Product> products, AppController controller) {
    if (products.isEmpty) {
      return const Center(
        child: Column(
          children: [
            Text('📭', style: TextStyle(fontSize: 48)),
            SizedBox(height: 8),
            Text(
              'لا توجد منتجات بعد',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }
    return Column(
      children: products.map((p) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accent, AppColors.accentLight],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  p.sellerAvatar,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '\$${p.price} • ${p.salesCount} مبيع • ⭐ ${p.rating}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              color: AppColors.card,
              onSelected: (value) {
                if (value == 'edit') {
                  _showProductForm(context, existing: p);
                } else if (value == 'delete') {
                  _confirmDeleteProduct(context, controller, p);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('تعديل', style: TextStyle(color: Colors.white)),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('حذف', style: TextStyle(color: AppColors.error)),
                ),
              ],
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildAnalyticsTab(SellerAnalytics analytics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🏆 أفضل المنتجات',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...analytics.topProducts.map((p) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${p.views} مشاهدة • ${p.sales} مبيع',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '\$${p.revenue.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildOrdersTab(AppController controller) {
    final myOrders = controller.orders
        .where((o) => o.sellerId == controller.user!.id)
        .toList();

    if (myOrders.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد طلبات',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return Column(
      children: myOrders.map((o) => ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          o.productTitle,
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          '\$${o.amount} • ${_formatDate(o.createdAt)}',
          style: const TextStyle(color: AppColors.textMuted),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: o.status == OrderStatus.completed
                ? AppColors.success.withValues(alpha: 0.2)
                : AppColors.warning.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            o.status == OrderStatus.completed ? 'مكتمل' : 'معلق',
            style: TextStyle(
              color: o.status == OrderStatus.completed
                  ? AppColors.success
                  : AppColors.warning,
              fontSize: 12,
            ),
          ),
        ),
      )).toList(),
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return 'منذ ${diff.inDays} يوم';
    if (diff.inHours > 0) return 'منذ ${diff.inHours} ساعة';
    return 'منذ قليل';
  }

  void _showProductForm(BuildContext context, {Product? existing}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ProductFormSheet(existing: existing),
    );
  }

  void _confirmDeleteProduct(BuildContext context, AppController controller, Product p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('حذف المنتج', style: TextStyle(color: Colors.white)),
        content: Text('هل أنت متأكد من حذف "${p.title}"؟', style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              controller.deleteProduct(p.id);
              Navigator.pop(ctx);
            },
            child: const Text('حذف', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

/// Interactive create/edit form for a seller's product. Fully wired to
/// [AppController.addProduct]/[AppController.updateProduct] - not a stub.
class _ProductFormSheet extends StatefulWidget {
  final Product? existing;
  const _ProductFormSheet({this.existing});

  @override
  State<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<_ProductFormSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _priceController;
  late final TextEditingController _categoryController;
  late final TextEditingController _featureController;
  final List<String> _features = [];
  late ProductType _type;

  static const _typeLabels = {
    ProductType.digital: '📦 منتج رقمي',
    ProductType.course: '🎓 دورة تعليمية',
    ProductType.license: '🔐 ترخيص برمجي',
    ProductType.ugc: '🎬 محتوى UGC',
    ProductType.hybrid: '🎯 منتج هجين',
    ProductType.template: '🧩 قالب',
  };

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleController = TextEditingController(text: e?.title ?? '');
    _descController = TextEditingController(text: e?.description ?? '');
    _priceController = TextEditingController(text: e != null ? e.price.toStringAsFixed(0) : '');
    _categoryController = TextEditingController(text: e?.category ?? '');
    _featureController = TextEditingController();
    _type = e?.type ?? ProductType.digital;
    if (e != null) _features.addAll(e.features);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    _featureController.dispose();
    super.dispose();
  }

  void _save() {
    if (_titleController.text.trim().isEmpty || _priceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء العنوان والسعر على الأقل')),
      );
      return;
    }
    final controller = AppProvider.of(context, listen: false);
    final user = controller.user!;
    final price = double.tryParse(_priceController.text.trim()) ?? 0;

    if (widget.existing != null) {
      final e = widget.existing!;
      controller.updateProduct(Product(
        id: e.id,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        sellerId: e.sellerId,
        sellerName: e.sellerName,
        sellerAvatar: e.sellerAvatar,
        price: price,
        originalPrice: e.originalPrice,
        type: _type,
        images: e.images,
        tags: e.tags,
        category: _categoryController.text.trim().isEmpty ? e.category : _categoryController.text.trim(),
        previewUrl: e.previewUrl,
        features: _features,
        metadata: e.metadata,
        status: e.status,
        createdAt: e.createdAt,
        salesCount: e.salesCount,
        rating: e.rating,
        reviewsCount: e.reviewsCount,
        isFeatured: e.isFeatured,
        licenseKey: e.licenseKey,
        stock: e.stock,
        isPayAsYouSell: e.isPayAsYouSell,
      ));
    } else {
      final name = user.name.isNotEmpty ? user.name : 'أنا';
      controller.addProduct(Product(
        id: 'p_${DateTime.now().millisecondsSinceEpoch}',
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        sellerId: user.id,
        sellerName: name,
        sellerAvatar: name.substring(0, name.length >= 2 ? 2 : 1),
        price: price,
        type: _type,
        images: const [],
        tags: const [],
        category: _categoryController.text.trim().isEmpty ? 'عام' : _categoryController.text.trim(),
        features: _features,
        createdAt: DateTime.now(),
      ));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.existing != null ? '✏️ تعديل المنتج' : '➕ إضافة منتج جديد',
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _typeLabels.entries.map((entry) {
                final isSelected = entry.key == _type;
                return ChoiceChip(
                  label: Text(entry.value),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _type = entry.key),
                  backgroundColor: AppColors.background.withValues(alpha: 0.6),
                  selectedColor: AppColors.accent.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.accent : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            _field(_titleController, 'عنوان المنتج', '🏷️'),
            const SizedBox(height: 12),
            _field(_descController, 'وصف المنتج', '📝', maxLines: 3),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _field(_priceController, 'السعر (\$)', '💵', keyboardType: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(child: _field(_categoryController, 'التصنيف', '🗂️')),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._features.map((f) => Chip(
                      label: Text(f, style: const TextStyle(color: Colors.white, fontSize: 12)),
                      backgroundColor: AppColors.background.withValues(alpha: 0.8),
                      onDeleted: () => setState(() => _features.remove(f)),
                      side: BorderSide.none,
                    )),
                SizedBox(
                  width: 180,
                  child: TextField(
                    controller: _featureController,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: '+ أضف ميزة',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      filled: true,
                      fillColor: AppColors.background.withValues(alpha: 0.6),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onSubmitted: (v) {
                      if (v.trim().isEmpty) return;
                      setState(() => _features.add(v.trim()));
                      _featureController.clear();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _save,
                child: Text(
                  widget.existing != null ? 'حفظ التعديلات' : 'إضافة المنتج',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String hint, String emoji, {int maxLines = 1, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.background.withValues(alpha: 0.6),
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        prefixIcon: Padding(padding: const EdgeInsets.all(12), child: Text(emoji, style: const TextStyle(fontSize: 16))),
        prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}
