import 'package:flutter/material.dart';
import '../../models/chat_model.dart';
import '../../theme/app_colors.dart';

/// شاشة قائمة المحادثات
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<ChatConversation> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  void _loadConversations() {
    // بيانات وهمية مع createdAt المضافة
    _conversations = [
      ChatConversation(
        id: '1',
        otherUserId: 'seller1',
        otherUserName: 'متجر التقنية',
        otherUserAvatar: 'https://picsum.photos/seed/seller1/100/100',
        lastMessage: 'مرحباً، هل يمكنك إرسال عينة من المنتج؟',
        lastMessageTime: DateTime.now().subtract(const Duration(minutes: 5)),
        createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
        unreadCount: 2,
        isOnline: true,
        productId: '1',
        productName: 'سماعات لاسلكية',
        productImage: 'https://picsum.photos/seed/headphones/100/100',
      ),
      ChatConversation(
        id: '2',
        otherUserId: 'seller2',
        otherUserName: 'متجر الرياضة',
        otherUserAvatar: 'https://picsum.photos/seed/seller2/100/100',
        lastMessage: 'شكراً لطلبك، سيتم الشحن غداً',
        lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        unreadCount: 0,
        isOnline: false,
        productId: '2',
        productName: 'ساعة ذكية',
        productImage: 'https://picsum.photos/seed/watch/100/100',
      ),
      ChatConversation(
        id: '3',
        otherUserId: 'buyer1',
        otherUserName: 'أحمد محمد',
        otherUserAvatar: 'https://picsum.photos/seed/buyer1/100/100',
        lastMessage: 'هل يوجد خصم للكميات؟',
        lastMessageTime: DateTime.now().subtract(const Duration(hours: 5)),
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        unreadCount: 1,
        isOnline: true,
      ),
      ChatConversation(
        id: '4',
        otherUserId: 'seller3',
        otherUserName: 'بوتيك الأناقة',
        otherUserAvatar: 'https://picsum.photos/seed/seller3/100/100',
        lastMessage: 'تم تأكيد الدفع، شكراً لك',
        lastMessageTime: DateTime.now().subtract(const Duration(days: 1)),
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        unreadCount: 0,
        isOnline: false,
      ),
    ];

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'المحادثات',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : _conversations.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _conversations.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    indent: 88,
                    color: AppColors.textMuted.withValues(alpha: 0.15),
                  ),
                  itemBuilder: (context, index) {
                    return _buildConversationTile(_conversations[index], theme);
                  },
                ),
    );
  }

  Widget _buildConversationTile(ChatConversation conv, ThemeData theme) {
    return InkWell(
      onTap: () {
        // Navigator.push(context, MaterialPageRoute(builder: (_) => ChatRoomScreen(conversation: conv)));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // الصورة
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: conv.otherUserAvatar.isNotEmpty
                      ? NetworkImage(conv.otherUserAvatar)
                      : null,
                  backgroundColor: AppColors.card,
                  child: conv.otherUserAvatar.isEmpty
                      ? const Icon(Icons.person_rounded, color: AppColors.textSecondary)
                      : null,
                ),
                if (conv.isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.green.shade500,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.background, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // المحتوى
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conv.otherUserName,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Text(
                        _formatTime(conv.lastMessageTime),
                        style: TextStyle(
                          fontSize: 12,
                          color: conv.unreadCount > 0 ? theme.colorScheme.primary : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conv.lastMessage ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: conv.unreadCount > 0 ? AppColors.textPrimary : AppColors.textMuted,
                            fontWeight: conv.unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (conv.unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${conv.unreadCount}',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (conv.productName != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.shopping_bag_outlined, size: 12, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            conv.productName!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.chat_bubble_outline_rounded, size: 80, color: AppColors.textMuted),
          const SizedBox(height: 16),
          const Text(
            'لا توجد محادثات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'ستظهر محادثاتك مع البائعين والمشترين هنا',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
    );
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
