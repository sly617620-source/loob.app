import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../data/country_codes.dart';

/// Compact "🇾🇪 +967 ▾" button that opens a searchable bottom sheet of
/// [countryCodes] and reports the pick via [onChanged]. Meant to sit
/// directly beside a phone-number [TextField] inside the same bordered
/// container, not as a full field of its own.
class CountryCodeField extends StatelessWidget {
  final CountryCode selected;
  final ValueChanged<CountryCode> onChanged;

  const CountryCodeField({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () async {
        final picked = await showModalBottomSheet<CountryCode>(
          context: context,
          backgroundColor: AppColors.card,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (ctx) => const _CountryPickerSheet(),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.keyboard_arrow_down, color: AppColors.textMuted, size: 16),
            const SizedBox(width: 4),
            Text(selected.dialCode, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(width: 6),
            Text(selected.flag, style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}

class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet();

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final results = _query.isEmpty
        ? countryCodes
        : countryCodes
            .where((c) => c.nameAr.contains(_query) || c.dialCode.contains(_query))
            .toList();

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text('اختر الدولة', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              autofocus: false,
              onChanged: (v) => setState(() => _query = v.trim()),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.background.withValues(alpha: 0.6),
                hintText: 'ابحث بالاسم أو المفتاح...',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: results.isEmpty
                ? const Center(child: Text('لا توجد نتائج', style: TextStyle(color: AppColors.textMuted)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final c = results[index];
                      return ListTile(
                        leading: Text(c.flag, style: const TextStyle(fontSize: 22)),
                        title: Text(c.nameAr, style: const TextStyle(color: Colors.white, fontSize: 14)),
                        trailing: Text(c.dialCode, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                        onTap: () => Navigator.pop(context, c),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
