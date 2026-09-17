import 'package:flutter/material.dart';
import '../../models/campaign_model.dart';
import '../../models/submission_model.dart';
import '../../theme/app_colors.dart';
import '../../providers/app_provider.dart';

/// "استكشف الحملات" - the campaigns marketplace feed.
///
/// Shown to content creators (to browse & submit) and, read-only, to
/// anyone curious what's running. Search + category chips + CPM-based
/// cards mirror the seller/product discovery screen's visual language so
/// the two feeds feel like one app.
class CampaignsScreen extends StatefulWidget {
  const CampaignsScreen({super.key});

  @override
  State<CampaignsScreen> createState() => _CampaignsScreenState();
}

class _CampaignsScreenState extends State<CampaignsScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'الكل';

  @override
  Widget build(BuildContext context) {
    final controller = AppProvider.of(context);
    final allCategories = <String>{'الكل'};
    for (final c in controller.campaigns) {
      allCategories.addAll(c.categories);
    }
    final campaigns = _searchQuery.isEmpty
        ? controller.getCampaignsByCategory(_selectedCategory)
        : controller.searchCampaigns(_searchQuery);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('استكشف الحملات')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.card.withValues(alpha: 0.8),
                hintText: '🔍 ابحث عن حملة أو جهة إعلانية...',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: allCategories.length,
              itemBuilder: (context, index) {
                final cat = allCategories.elementAt(index);
                final isSelected = cat == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                    backgroundColor: AppColors.card.withValues(alpha: 0.8),
                    selectedColor: AppColors.accent.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.accent : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: isSelected ? AppColors.accent : Colors.transparent),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: campaigns.isEmpty
                ? const Center(
                    child: Text('لا توجد حملات مطابقة', style: TextStyle(color: AppColors.textMuted)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: campaigns.length,
                    itemBuilder: (context, index) => _CampaignCard(campaign: campaigns[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CampaignCard extends StatelessWidget {
  final Campaign campaign;
  const _CampaignCard({required this.campaign});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.accent, AppColors.accentLight]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    campaign.displayBrandAvatar,
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(campaign.displayBrandName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                    Row(
                      children: [
                        const Icon(Icons.star, color: AppColors.warning, size: 12),
                        const SizedBox(width: 2),
                        Text(campaign.avgRating.toStringAsFixed(1),
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'CPM \$${campaign.cpm.toStringAsFixed(1)}',
                  style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(campaign.title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 6),
          Text(
            campaign.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statChip(Icons.visibility_outlined, '${_formatCount(campaign.viewsCount)} مشاهدة'),
              const SizedBox(width: 8),
              _statChip(Icons.schedule, '${campaign.daysRemaining} يوم متبقي'),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: campaign.budgetPercent / 100,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation(AppColors.accent),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('الميزانية: \$${campaign.spentBudget.toStringAsFixed(0)} / \$${campaign.budget.toStringAsFixed(0)}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              Text('${campaign.budgetPercent.toStringAsFixed(0)}%',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: () => _showCampaignDetails(context, campaign),
              child: const Text('عرض التفاصيل', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
      ],
    );
  }

  static String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }
}

void _showCampaignDetails(BuildContext context, Campaign campaign) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.card,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => _CampaignDetailsSheet(campaign: campaign),
  );
}

class _CampaignDetailsSheet extends StatelessWidget {
  final Campaign campaign;
  const _CampaignDetailsSheet({required this.campaign});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.textMuted.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(height: 20),
              Text(campaign.title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('بواسطة ${campaign.displayBrandName}', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
              const SizedBox(height: 16),
              Row(
                children: [
                  _pill('💰 \$${campaign.rewardPerSubmission.toStringAsFixed(1)}/تقديم'),
                  const SizedBox(width: 8),
                  _pill('📊 CPM \$${campaign.cpm.toStringAsFixed(1)}'),
                  const SizedBox(width: 8),
                  _pill('⏳ ${campaign.daysRemaining} يوم'),
                ],
              ),
              const SizedBox(height: 20),
              const Text('الوصف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(campaign.description, style: const TextStyle(color: AppColors.textSecondary, height: 1.5)),
              if (campaign.requirements.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text('المتطلبات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...campaign.requirements.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('•  ', style: TextStyle(color: AppColors.accent)),
                          Expanded(child: Text(r, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                        ],
                      ),
                    )),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: campaign.isFull
                      ? null
                      : () {
                          Navigator.pop(context);
                          _showSubmitDialog(context, campaign);
                        },
                  child: Text(
                    campaign.isFull ? 'اكتملت الحملة' : 'قدّم محتواك للحملة',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _pill(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: AppColors.background.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(10)),
        child: Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
      );
}

void _showSubmitDialog(BuildContext context, Campaign campaign) {
  final contentUrlController = TextEditingController();
  final captionController = TextEditingController();
  String platform = 'تيك توك';

  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.card,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: StatefulBuilder(
          builder: (ctx, setSheetState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🎬 تقديم محتوى للحملة', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _dialogField(contentUrlController, 'رابط المحتوى المنشور', '🔗'),
              const SizedBox(height: 12),
              _dialogField(captionController, 'وصف/ملاحظات', '📝', maxLines: 2),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: ['تيك توك', 'إنستغرام', 'يوتيوب', 'إكس'].map((p) {
                  final isSelected = p == platform;
                  return ChoiceChip(
                    label: Text(p),
                    selected: isSelected,
                    onSelected: (_) => setSheetState(() => platform = p),
                    backgroundColor: AppColors.background.withValues(alpha: 0.6),
                    selectedColor: AppColors.accent.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.accent : AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    if (contentUrlController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('يرجى إدخال رابط المحتوى')),
                      );
                      return;
                    }
                    final controller = AppProvider.of(ctx, listen: false);
                    final user = controller.user!;
                    controller.submitToCampaign(
                      Submission(
                        id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
                        campaignId: campaign.id,
                        influencerId: user.id,
                        contentUrl: contentUrlController.text.trim(),
                        caption: captionController.text.trim(),
                        platform: platform,
                        reward: campaign.rewardPerSubmission,
                        submittedAt: DateTime.now(),
                      ),
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('تم إرسال التقديم بنجاح ✅'),
                        backgroundColor: AppColors.success.withValues(alpha: 0.9),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.all(16),
                      ),
                    );
                  },
                  child: const Text('إرسال التقديم', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _dialogField(TextEditingController controller, String hint, String emoji, {int maxLines = 1}) {
  return TextField(
    controller: controller,
    maxLines: maxLines,
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
