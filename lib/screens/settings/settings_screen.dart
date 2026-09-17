import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../providers/app_provider.dart';
import '../../services/settings_controller.dart';

/// Fully editable settings screen.
///
/// Every field here is backed by a real [User] field and persisted through
/// `AppController.updateProfile` (which updates local state instantly and
/// best-effort syncs to Firestore) - nothing on this screen is a dead
/// `onTap: () {}` stub.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _bioController;
  late final TextEditingController _categoryController;
  late final TextEditingController _socialController;
  late List<String> _categories;
  late List<String> _socialLinks;
  late UserRole _role;

  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    final user = AppProvider.of(context, listen: false).user!;
    _nameController = TextEditingController(text: user.displayName ?? '');
    _phoneController = TextEditingController(text: user.phoneNumber ?? '');
    _bioController = TextEditingController(text: user.bio ?? '');
    _categoryController = TextEditingController();
    _socialController = TextEditingController();
    _categories = List<String>.from(user.categories);
    _socialLinks = List<String>.from(user.socialLinks);
    _role = user.role;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _categoryController.dispose();
    _socialController.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _save() async {
    final controller = AppProvider.of(context, listen: false);
    final user = controller.user!;
    final updated = user.copyWith(
      displayName: _nameController.text.trim().isEmpty
          ? user.displayName
          : _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      bio: _bioController.text.trim(),
      categories: _categories,
      socialLinks: _socialLinks,
      role: _role,
    );
    await controller.updateProfile(updated);
    if (!mounted) return;
    setState(() => _dirty = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('تم حفظ التغييرات ✅'),
        backgroundColor: AppColors.success.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('الإعدادات'),
        actions: [
          if (_dirty)
            TextButton(
              onPressed: _save,
              child: const Text('حفظ', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('المعلومات الشخصية'),
            _card(
              child: Column(
                children: [
                  _textField(_nameController, 'الاسم الكامل', '👤'),
                  const SizedBox(height: 12),
                  _textField(_phoneController, 'رقم الهاتف', '📱', keyboardType: TextInputType.phone),
                  const SizedBox(height: 12),
                  _textField(_bioController, 'نبذة عنك', '📝', maxLines: 3),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _sectionTitle('المظهر والإشعارات'),
            _card(child: _appearanceAndNotifications()),
            const SizedBox(height: 20),
            _sectionTitle('نوع الحساب'),
            _card(child: _roleDisplay()),
            const SizedBox(height: 20),
            _sectionTitle('التصنيفات المفضّلة'),
            _card(child: _chipEditor(
              values: _categories,
              controller: _categoryController,
              hint: 'أضف تصنيفًا (مثال: تسويق)',
              onAdd: (v) {
                setState(() => _categories.add(v));
                _markDirty();
              },
              onRemove: (v) {
                setState(() => _categories.remove(v));
                _markDirty();
              },
            )),
            const SizedBox(height: 20),
            _sectionTitle('روابط التواصل الاجتماعي'),
            _card(child: _chipEditor(
              values: _socialLinks,
              controller: _socialController,
              hint: 'أضف رابط حسابك (مثال: instagram.com/you)',
              onAdd: (v) {
                setState(() => _socialLinks.add(v));
                _markDirty();
              },
              onRemove: (v) {
                setState(() => _socialLinks.remove(v));
                _markDirty();
              },
            )),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _dirty ? _save : null,
                child: const Text('حفظ التغييرات', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8, right: 4),
        child: Text(
          title,
          style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      );

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: child,
      );

  Widget _textField(
    TextEditingController controller,
    String hint,
    String emoji, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: (_) => _markDirty(),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.background.withValues(alpha: 0.6),
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(emoji, style: const TextStyle(fontSize: 18)),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 1),
        ),
      ),
    );
  }

  /// Dark/light theme toggle + notifications toggle, both persisted
  /// through [SettingsController] (SharedPreferences-backed) so they
  /// survive app restarts. Wrapped in its own [AnimatedBuilder] so it
  /// reacts instantly without needing the whole screen's `setState`.
  Widget _appearanceAndNotifications() {
    return AnimatedBuilder(
      animation: SettingsController.to,
      builder: (context, _) {
        final settings = SettingsController.to;
        return Column(
          children: [
            _settingsSwitchRow(
              emoji: '🌗',
              title: 'الوضع الداكن',
              subtitle: settings.isDarkMode ? 'مفعّل حاليًا' : 'الوضع الفاتح مفعّل',
              value: settings.isDarkMode,
              onChanged: (v) => settings.setThemeMode(v ? ThemeMode.dark : ThemeMode.light),
            ),
            const Divider(color: AppColors.textMuted, height: 24, thickness: 0.2),
            _settingsSwitchRow(
              emoji: '🔔',
              title: 'الإشعارات',
              subtitle: settings.notificationsEnabled
                  ? 'ستصلك إشعارات الطلبات والرسائل'
                  : 'الإشعارات متوقفة',
              value: settings.notificationsEnabled,
              onChanged: settings.setNotificationsEnabled,
            ),
          ],
        );
      },
    );
  }

  Widget _settingsSwitchRow({
    required String emoji,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.accent,
        ),
      ],
    );
  }

  /// Read-only by product requirement: the account type chosen at signup
  /// can't be changed from inside the app - only app management can change
  /// it (see the note on [AppController.updateProfile] and
  /// firestore.rules). This replaces what used to be a tappable picker
  /// with the same visual row, just without the [GestureDetector]/
  /// `setState` that let it be changed.
  Widget _roleDisplay() {
    final r = _role;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(r.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text(r.description, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
              ),
              const Icon(Icons.lock_outline, color: AppColors.textMuted, size: 18),
            ],
          ),
          const Divider(color: AppColors.textMuted, height: 20, thickness: 0.2),
          const Text(
            'لا يمكن تغيير نوع الحساب من داخل التطبيق. للتغيير، يرجى التواصل مع إدارة التطبيق.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _chipEditor({
    required List<String> values,
    required TextEditingController controller,
    required String hint,
    required void Function(String) onAdd,
    required void Function(String) onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (values.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: values.map((v) => Chip(
                  label: Text(v, style: const TextStyle(color: Colors.white, fontSize: 12)),
                  backgroundColor: AppColors.background.withValues(alpha: 0.8),
                  deleteIcon: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
                  onDeleted: () => onRemove(v),
                  side: BorderSide.none,
                )).toList(),
          ),
        if (values.isNotEmpty) const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: AppColors.background.withValues(alpha: 0.6),
                  hintText: hint,
                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onSubmitted: (v) {
                  final trimmed = v.trim();
                  if (trimmed.isEmpty) return;
                  onAdd(trimmed);
                  controller.clear();
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_circle, color: AppColors.accent),
              onPressed: () {
                final trimmed = controller.text.trim();
                if (trimmed.isEmpty) return;
                onAdd(trimmed);
                controller.clear();
              },
            ),
          ],
        ),
      ],
    );
  }
}
