class Coupon {
  final String id;
  final String code;
  final double discountPercent;
  final double? maxDiscount;
  final DateTime validUntil;
  final int? maxUses;
  int usedCount;
  final List<String>? applicableCategories;
  final String? createdBy;
  bool isActive;

  Coupon({
    required this.id,
    required this.code,
    required this.discountPercent,
    this.maxDiscount,
    required this.validUntil,
    this.maxUses,
    this.usedCount = 0,
    this.applicableCategories,
    this.createdBy,
    this.isActive = true,
  });

  bool get isValid =>
      isActive &&
      DateTime.now().isBefore(validUntil) &&
      (maxUses == null || usedCount < maxUses!);

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'discountPercent': discountPercent,
        'maxDiscount': maxDiscount,
        'validUntil': validUntil.toIso8601String(),
        'maxUses': maxUses,
        'usedCount': usedCount,
        'applicableCategories': applicableCategories,
        'createdBy': createdBy,
        'isActive': isActive,
      };

  factory Coupon.fromJson(Map<String, dynamic> json) => Coupon(
        id: json['id'],
        code: json['code'],
        discountPercent: json['discountPercent'],
        maxDiscount: json['maxDiscount'],
        validUntil: DateTime.parse(json['validUntil']),
        maxUses: json['maxUses'],
        usedCount: json['usedCount'] ?? 0,
        applicableCategories: json['applicableCategories'] != null
            ? List<String>.from(json['applicableCategories'])
            : null,
        createdBy: json['createdBy'],
        isActive: json['isActive'] ?? true,
      );
}
