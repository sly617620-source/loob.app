// services/bot_protection.dart
//
// حماية بسيطة من الروبوتات والهجمات المتكررة.
// لا توقف الإطلاق أبداً — مجرد تسجيل/مراقبة في الخلفية.

import 'dart:async';
import 'package:flutter/foundation.dart';

class BotProtection {
  static final BotProtection _instance = BotProtection._internal();
  factory BotProtection() => _instance;
  BotProtection._internal();

  final Map<String, List<DateTime>> _actionLog = {};

  /// فحص honeypot: أي قيمة غير فارغة تعني بوت
  bool checkHoneypot(String value) {
    return value.trim().isNotEmpty;
  }

  /// فحص معدل المحاولات (rate limiting)
  ///
  /// المعلمات:
  ///   - identifier: معرف فريد للمستخدم (email أو 'anonymous')
  ///   - action: نوع الإجراء ('login', 'register', 'app_launch', ...)
  ///   - minInterval: الحد الأدنى بين المحاولات
  ///   - maxPerWindow: الحد الأقصى للمحاولات في الفترة
  ///   - window: مدة الفترة الزمنية
  ///
  /// تعيد: true إذا كان المعدل مقبولاً، false إذا تجاوز الحد
  Future<bool> checkRateLimit(
    String identifier, {
    required String action,
    Duration minInterval = const Duration(seconds: 1),
    int maxPerWindow = 10,
    Duration window = const Duration(minutes: 5),
  }) async {
    final key = '$identifier:$action';
    final now = DateTime.now();

    _actionLog.putIfAbsent(key, () => []);
    final log = _actionLog[key]!;

    // إزالة السجلات القديمة خارج النافذة الزمنية
    log.removeWhere((t) => now.difference(t) > window);

    // التحقق من عدد المحاولات في النافذة
    if (log.length >= maxPerWindow) {
      debugPrint('🛡️ Rate limit exceeded for $key: ${log.length} attempts in $window');
      return false;
    }

    // التحقق من الفاصل الزمني بين آخر محاولة والحالية
    if (log.isNotEmpty) {
      final lastAttempt = log.last;
      if (now.difference(lastAttempt) < minInterval) {
        debugPrint('🛡️ Min interval not met for $key');
        return false;
      }
    }

    // تسجيل المحاولة
    log.add(now);
    return true;
  }
}
