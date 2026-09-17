import 'package:flutter/material.dart';
import '../../models/campaign_model.dart';
import '../../models/submission_model.dart';
import '../../theme/app_colors.dart';
import '../../services/app_controller.dart';
import '../../providers/app_provider.dart';

/// Dashboard for the "منشئ حملة" (campaign creator) role: manage owned
/// campaigns (create/edit/delete, fully interactive) and review incoming
/// content-creator submissions (approve/reject).
class CampaignDashboardScreen extends StatefulWidget {
  const CampaignDashboardScreen({super.key});

  @override
  State<CampaignDashboardScreen> createState() => _CampaignDashboardScreenState();
}

class _CampaignDashboardScreenState extends State<CampaignDashboardScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final controller = AppProvider.of(context);
    final user = controller.user!;
    final myCampaigns = controller.getCampaignsByOwner(user.id);
    final incomingSubmissions = controller.getSubmissionsForOwner(user.id);
    final pendingCount = incomingSubmissions.where((s) => s.isPending).length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('لوحة الحملات'),
        actions: [
          IconButton(
            icon: const Text('➕', style: TextStyle(fontSize: 20)),
            onPressed: () => _showCampaignForm(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(child: _statCard('📢', 'حملاتي', '${myCampaigns.length}', AppColors.accent)),
                const SizedBox(width: 12),
                Expanded(child: _statCard('📥', 'تقديمات معلّقة', '$pendingCount', AppColors.warning)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _tab('حملاتي', 0),
              _tab('التقديمات الواردة', 1),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _selectedTab == 0
                ? _campaignsList(myCampaigns, controller)
                : _submissionsList(incomingSubmissions, controller),
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
          Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _tab(String label, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: isSelected ? AppColors.accent : Colors.transparent, width: 2)),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: isSelected ? AppColors.accent : AppColors.textMuted, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
          ),
        ),
      ),
    );
  }

  Widget _campaignsList(List<Campaign> campaigns, AppController controller) {
    if (campaigns.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📭', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            const Text('لا توجد حملات بعد', style: TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: () => _showCampaignForm(context), child: const Text('إنشاء حملة جديدة')),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: campaigns.map((c) {
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
                    child: Text(c.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  _statusBadge(c.status),
                  PopupMenuButton<String>(
                    color: AppColors.card,
                    icon: const Icon(Icons.more_vert, color: AppColors.textMuted, size: 20),
                    onSelected: (v) {
                      if (v == 'edit') _showCampaignForm(context, existing: c);
                      if (v == 'delete') _confirmDeleteCampaign(context, c);
                      if (v == 'pause') controller.updateCampaign(c.copyWith(status: c.status == CampaignStatus.active ? CampaignStatus.paused : CampaignStatus.active));
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('تعديل', style: TextStyle(color: Colors.white))),
                      PopupMenuItem(value: 'pause', child: Text(c.status == CampaignStatus.active ? 'إيقاف مؤقت' : 'تفعيل', style: const TextStyle(color: Colors.white))),
                      const PopupMenuItem(value: 'delete', child: Text('حذف', style: TextStyle(color: AppColors.error))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('${c.currentSubmissions}/${c.maxSubmissions} تقديم • \$${c.spentBudget.toStringAsFixed(0)} من \$${c.budget.toStringAsFixed(0)}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: c.progress.clamp(0, 1),
                  minHeight: 6,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _statusBadge(CampaignStatus status) {
    final labels = {
      CampaignStatus.pending: 'قيد المراجعة',
      CampaignStatus.active: 'نشطة',
      CampaignStatus.paused: 'متوقفة',
      CampaignStatus.completed: 'مكتملة',
      CampaignStatus.cancelled: 'ملغاة',
    };
    final colors = {
      CampaignStatus.pending: AppColors.warning,
      CampaignStatus.active: AppColors.success,
      CampaignStatus.paused: AppColors.textMuted,
      CampaignStatus.completed: AppColors.accent,
      CampaignStatus.cancelled: AppColors.error,
    };
    final color = colors[status]!;
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
      child: Text(labels[status]!, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _submissionsList(List<Submission> submissions, AppController controller) {
    if (submissions.isEmpty) {
      return const Center(child: Text('لا توجد تقديمات بعد', style: TextStyle(color: AppColors.textMuted)));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: submissions.map((s) {
        final statusLabel = {
          SubmissionStatus.pending: 'قيد المراجعة',
          SubmissionStatus.approved: 'مقبول',
          SubmissionStatus.rejected: 'مرفوض',
          SubmissionStatus.paid: 'مدفوع',
          SubmissionStatus.cancelled: 'ملغى',
        }[s.status]!;
        final statusColor = {
          SubmissionStatus.pending: AppColors.warning,
          SubmissionStatus.approved: AppColors.success,
          SubmissionStatus.rejected: AppColors.error,
          SubmissionStatus.paid: AppColors.accent,
          SubmissionStatus.cancelled: AppColors.textMuted,
        }[s.status]!;
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
                    child: Text(s.contentUrl ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                    child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              if ((s.caption ?? '').isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(s.caption!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
              const SizedBox(height: 6),
              Text('${s.platform ?? ''} • \$${(s.reward ?? 0).toStringAsFixed(1)}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              if (s.isPending) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
                        onPressed: () => controller.reviewSubmission(s.id, SubmissionStatus.rejected),
                        child: const Text('رفض'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => controller.reviewSubmission(s.id, SubmissionStatus.approved),
                        child: const Text('قبول'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  void _confirmDeleteCampaign(BuildContext context, Campaign c) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('حذف الحملة', style: TextStyle(color: Colors.white)),
        content: Text('هل أنت متأكد من حذف "${c.title}"؟', style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              AppProvider.of(context, listen: false).deleteCampaign(c.id);
              Navigator.pop(ctx);
            },
            child: const Text('حذف', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showCampaignForm(BuildContext context, {Campaign? existing}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _CampaignFormSheet(existing: existing),
    );
  }
}

class _CampaignFormSheet extends StatefulWidget {
  final Campaign? existing;
  const _CampaignFormSheet({this.existing});

  @override
  State<_CampaignFormSheet> createState() => _CampaignFormSheetState();
}

class _CampaignFormSheetState extends State<_CampaignFormSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _budgetController;
  late final TextEditingController _cpmController;
  late final TextEditingController _rewardController;
  late final TextEditingController _maxSubmissionsController;
  late final TextEditingController _categoryController;
  final List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleController = TextEditingController(text: e?.title ?? '');
    _descController = TextEditingController(text: e?.description ?? '');
    _budgetController = TextEditingController(text: e != null ? e.budget.toStringAsFixed(0) : '');
    _cpmController = TextEditingController(text: e != null ? e.cpm.toStringAsFixed(1) : '');
    _rewardController = TextEditingController(text: e != null ? e.rewardPerSubmission.toStringAsFixed(1) : '');
    _maxSubmissionsController = TextEditingController(text: e != null ? e.maxSubmissions.toString() : '100');
    _categoryController = TextEditingController();
    if (e != null) _categories.addAll(e.categories);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _budgetController.dispose();
    _cpmController.dispose();
    _rewardController.dispose();
    _maxSubmissionsController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _save() {
    if (_titleController.text.trim().isEmpty || _budgetController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى ملء العنوان والميزانية على الأقل')));
      return;
    }
    final controller = AppProvider.of(context, listen: false);
    final user = controller.user!;
    final budget = double.tryParse(_budgetController.text.trim()) ?? 0;
    final cpm = double.tryParse(_cpmController.text.trim()) ?? 0;
    final reward = double.tryParse(_rewardController.text.trim()) ?? 0;
    final maxSubs = int.tryParse(_maxSubmissionsController.text.trim()) ?? 100;

    if (widget.existing != null) {
      controller.updateCampaign(widget.existing!.copyWith(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        budget: budget,
        cpm: cpm,
        rewardPerSubmission: reward,
        maxSubmissions: maxSubs,
        categories: _categories,
        updatedAt: DateTime.now(),
      ));
    } else {
      controller.addCampaign(Campaign(
        id: 'cmp_${DateTime.now().millisecondsSinceEpoch}',
        brandId: user.id,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        budget: budget,
        rewardPerSubmission: reward,
        status: CampaignStatus.active,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        categories: _categories,
        maxSubmissions: maxSubs,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        brandName: user.name.isNotEmpty ? user.name : 'حسابي',
        brandAvatar: user.name.isNotEmpty ? user.name.substring(0, user.name.length >= 2 ? 2 : 1) : '؟',
        cpm: cpm,
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
            Text(widget.existing != null ? '✏️ تعديل الحملة' : '📢 إنشاء حملة جديدة',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _field(_titleController, 'عنوان الحملة', '📌'),
            const SizedBox(height: 12),
            _field(_descController, 'وصف الحملة', '📝', maxLines: 3),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _field(_budgetController, 'الميزانية (\$)', '💰', keyboardType: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(child: _field(_cpmController, 'CPM (\$)', '📊', keyboardType: const TextInputType.numberWithOptions(decimal: true))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _field(_rewardController, 'مكافأة كل تقديم (\$)', '🎁', keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                const SizedBox(width: 10),
                Expanded(child: _field(_maxSubmissionsController, 'أقصى عدد تقديمات', '🔢', keyboardType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._categories.map((c) => Chip(
                      label: Text(c, style: const TextStyle(color: Colors.white, fontSize: 12)),
                      backgroundColor: AppColors.background.withValues(alpha: 0.8),
                      onDeleted: () => setState(() => _categories.remove(c)),
                      side: BorderSide.none,
                    )),
                SizedBox(
                  width: 160,
                  child: TextField(
                    controller: _categoryController,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: '+ أضف تصنيف',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      filled: true,
                      fillColor: AppColors.background.withValues(alpha: 0.6),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onSubmitted: (v) {
                      if (v.trim().isEmpty) return;
                      setState(() => _categories.add(v.trim()));
                      _categoryController.clear();
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
                child: Text(widget.existing != null ? 'حفظ التعديلات' : 'إنشاء الحملة', style: const TextStyle(fontWeight: FontWeight.bold)),
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
