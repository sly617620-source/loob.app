// lib/models/compat_shims.dart

// Small compatibility shims to restore older named parameters and types
// expected by existing call sites and tests. These should be removed or
// consolidated once the codebase is updated to the canonical models.

enum DiscountTypeCompat { percentage, fixedAmount }

class AffiliateLinkCompat {
  final String id;
  final String userId;
  final String productId;
  final String code;
  final double commissionPercent;
  final int clicks;
  final int conversions;
  final double totalEarnings;
  final DateTime createdAt;

  AffiliateLinkCompat({
    required this.id,
    required this.userId,
    required this.productId,
    required this.code,
    required this.commissionPercent,
    required this.clicks,
    required this.conversions,
    required this.totalEarnings,
    required this.createdAt,
  });
}

class LicenseCompat {
  final String id;
  final String productId;
  final String key;
  final int maxActivations;
  final int currentActivations;
  final DateTime createdAt;
  final DateTime? expiryDate;

  LicenseCompat({
    required this.id,
    required this.productId,
    required this.key,
    required this.maxActivations,
    required this.currentActivations,
    required this.createdAt,
    this.expiryDate,
  });
}
