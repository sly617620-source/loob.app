import 'package:flutter/material.dart';
import 'package:loob/models/notification_model.dart';
import 'package:loob/services/local_storage_service.dart';
import 'package:loob/theme/app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late LocalStorageService _storage;
  List<AppNotification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initStorage();
  }

  Future<void> _initStorage() async {
    _storage = await LocalStorageService.create();
    _loadNotifications();
  }

  void _loadNotifications() {
    _notifications = [
      AppNotification(
        id: '1',
        title: 'حملة جديدة متاحة',
        body: 'انضم إلى حملة سماعات بلوتوث الفاخرة واربح عمولة 15%',
        type: NotificationType.campaign,
        createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
        targetId: 'campaign_1',
        isRead: false,
        colorValue: 0xFFD4AF37,
      ),
      AppNotification(
        id: '2',
        title: 'تمت الموافقة على طلبك',
        body: 'تمت الموافقة على انضمامك لحملة الساعة الذكية',
        type: NotificationType.approval,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        targetId: 'campaign_2',
        isRead: false,
        colorValue: 0xFF2ED573,
      ),
      AppNotification(
        id: '3',
        title: 'مبيعات جديدة',
        body: 'قام أحمد بشراء منتجك، ربحك: 45 ر.س',
        type: NotificationType.sale,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        targetId: 'order_123',
        isRead: true,
        colorValue: 0xFF1E90FF,
      ),
      AppNotification(
        id: '4',
        title: 'رسالة جديدة',
        body: 'متجر التقنية: نعم متوفر حالياً',
        type: NotificationType.message,
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        targetId: 'chat_1',
        isRead: true,
        colorValue: 0xFFFFA502,
      ),
      AppNotification(
        id: '5',
        title: 'تم السحب بنجاح',
        body: 'تم تحويل مبلغ 500 ر.س إلى حسابك البنكي',
        type: NotificationType.payment,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        isRead: true,
        colorValue: 0xFF8E44AD,
      ),
      AppNotification(
        id: '6',
        title: 'تقييم جديد',
        body: 'قام محمد بتقييم منتجك بـ 5 نجوم',
        type: NotificationType.review,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        targetId: 'product_1',
        isRead: true,
        colorValue: 0xFFFF4757,
      ),
      AppNotification(
        id: '7',
        title: 'تحديث النظام',
        body: 'تم إطلاق ميزات جديدة في التطبيق، اكتشفها الآن',
        type: NotificationType.system,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        isRead: true,
        colorValue: 0xFF6C7A89,
      ),
    ];

    setState(() => _isLoading = false);
  }

  Future<void> _markAllAsRead() async {
    setState(() {
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    });
    await _storage.setLastReadNotificationTime(DateTime.now());
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('مسح الإشعارات', style: TextStyle(color: Colors.white)),
        content: const Text('هل أنت متأكد من حذف جميع الإشعارات؟', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('مسح'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() => _notifications = []);
    }
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card.withValues(alpha: 0.95),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'الإشعارات',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_notifications.isNotEmpty) ...[
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('تعيين الكل مقروء', style: TextStyle(color: AppColors.accent)),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.white54),
              onPressed: _clearAll,
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : _notifications.isEmpty
              ? _buildEmptyState()
              : _buildNotificationsList(),
    );
  }

  Widget _buildNotificationsList() {
    final today = <AppNotification>[];
    final yesterday = <AppNotification>[];
    final older = <AppNotification>[];

    final now = DateTime.now();
    for (final n in _notifications) {
      final diff = now.difference(n.createdAt);
      if (diff.inDays < 1) {
        today.add(n);
      } else if (diff.inDays < 2) {
        yesterday.add(n);
      } else {
        older.add(n);
      }
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (_unreadCount > 0)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.notifications_active_rounded, color: AppColors.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'لديك $_unreadCount إشعارات غير مقروءة',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (today.isNotEmpty) ...[
          _buildSectionHeader('اليوم'),
          ...today.map((n) => _buildNotificationTile(n)),
        ],
        if (yesterday.isNotEmpty) ...[
          _buildSectionHeader('أمس'),
          ...yesterday.map((n) => _buildNotificationTile(n)),
        ],
        if (older.isNotEmpty) ...[
          _buildSectionHeader('سابقاً'),
          ...older.map((n) => _buildNotificationTile(n)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildNotificationTile(AppNotification notification) {
    final color = Color(notification.colorValue);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppColors.error.withValues(alpha: 0.2),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.delete_rounded, color: AppColors.error),
            const SizedBox(width: 8),
            Text('حذف', style: TextStyle(color: AppColors.error)),
            const SizedBox(width: 20),
          ],
        ),
      ),
      onDismissed: (_) {
        setState(() => _notifications.removeWhere((n) => n.id == notification.id));
      },
      child: InkWell(
        onTap: () {
          setState(() {
            final index = _notifications.indexWhere((n) => n.id == notification.id);
            if (index != -1) {
              _notifications[index] = notification.copyWith(isRead: true);
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: notification.isRead ? Colors.transparent : color.withValues(alpha: 0.05),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getIconData(notification.type),
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: notification.isRead
                                  ? FontWeight.w600
                                  : FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(notification.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade400,
                        height: 1.4,
                      ),
                    ),
                    if (!notification.isRead)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 80, color: Colors.grey.shade600),
          const SizedBox(height: 16),
          Text(
            'لا توجد إشعارات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ستظهر إشعاراتك هنا عندما تصلك',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(NotificationType type) {
    switch (type) {
      case NotificationType.campaign:
        return Icons.campaign_rounded;
      case NotificationType.approval:
        return Icons.check_circle_rounded;
      case NotificationType.sale:
        return Icons.shopping_cart_rounded;
      case NotificationType.message:
        return Icons.chat_bubble_rounded;
      case NotificationType.system:
        return Icons.info_rounded;
      case NotificationType.payment:
        return Icons.account_balance_wallet_rounded;
      case NotificationType.review:
        return Icons.star_rounded;
      case NotificationType.order:
        return Icons.receipt_long_rounded;
      case NotificationType.submission:
        return Icons.upload_file_rounded;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inHours < 1) return '${diff.inMinutes}د';
    if (diff.inDays < 1) return '${diff.inHours}س';
    if (diff.inDays < 7) return '${diff.inDays}ي';
    return '${time.day}/${time.month}';
  }
}
