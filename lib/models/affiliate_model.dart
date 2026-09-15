import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents an affiliate/referral relationship.
class Affiliate {
  final String id;
  final String userId;
  final String referralCode;
  final int totalClicks;
  final int totalConversions;
  final double totalEarnings;
  final double pendingEarnings;
  final double paidEarnings;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final List<AffiliateClick> clicks;
  final List<AffiliateConversion> conversions;

  const Affiliate({
    required this.id,
    required this.userId,
    required this.referralCode,
    this.totalClicks = 0,
    this.totalConversions = 0,
    this.totalEarnings = 0.0,
    this.pendingEarnings = 0.0,
    this.paidEarnings = 0.0,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.clicks = const [],
    this.conversions = const [],
  });

  factory Affiliate.fromJson(Map<String, dynamic> json) {
    return Affiliate(
      id: json['id'] as String,
      userId: json['userId'] as String,
      referralCode: json['referralCode'] as String,
      totalClicks: json['totalClicks'] as int? ?? 0,
      totalConversions: json['totalConversions'] as int? ?? 0,
      totalEarnings: (json['totalEarnings'] as num?)?.toDouble() ?? 0.0,
      pendingEarnings: (json['pendingEarnings'] as num?)?.toDouble() ?? 0.0,
      paidEarnings: (json['paidEarnings'] as num?)?.toDouble() ?? 0.0,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: json['isActive'] as bool? ?? true,
      clicks: (json['clicks'] as List<dynamic>?)
              ?.map((e) => AffiliateClick.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      conversions: (json['conversions'] as List<dynamic>?)
              ?.map((e) => AffiliateConversion.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'referralCode': referralCode,
      'totalClicks': totalClicks,
      'totalConversions': totalConversions,
      'totalEarnings': totalEarnings,
      'pendingEarnings': pendingEarnings,
      'paidEarnings': paidEarnings,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'clicks': clicks.map((e) => e.toJson()).toList(),
      'conversions': conversions.map((e) => e.toJson()).toList(),
    };
  }

  /// Calculates conversion rate with zero-division protection.
  double get conversionRate {
    if (totalClicks <= 0) return 0.0;
    return totalConversions / totalClicks;
  }

  /// Calculates earnings per click with zero-division protection.
  double get earningsPerClick {
    if (totalClicks <= 0) return 0.0;
    return totalEarnings / totalClicks;
  }

  Affiliate copyWith({
    String? id,
    String? userId,
    String? referralCode,
    int? totalClicks,
    int? totalConversions,
    double? totalEarnings,
    double? pendingEarnings,
    double? paidEarnings,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    List<AffiliateClick>? clicks,
    List<AffiliateConversion>? conversions,
  }) {
    return Affiliate(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      referralCode: referralCode ?? this.referralCode,
      totalClicks: totalClicks ?? this.totalClicks,
      totalConversions: totalConversions ?? this.totalConversions,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      pendingEarnings: pendingEarnings ?? this.pendingEarnings,
      paidEarnings: paidEarnings ?? this.paidEarnings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      clicks: clicks ?? this.clicks,
      conversions: conversions ?? this.conversions,
    );
  }

  @override
  String toString() => 'Affiliate(id: $id, userId: $userId, code: $referralCode)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Affiliate && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Represents a single affiliate click.
class AffiliateClick {
  final String id;
  final String affiliateId;
  final String? ipAddress;
  final String? userAgent;
  final String? referrer;
  final DateTime clickedAt;
  final bool converted;

  const AffiliateClick({
    required this.id,
    required this.affiliateId,
    this.ipAddress,
    this.userAgent,
    this.referrer,
    required this.clickedAt,
    this.converted = false,
  });

  factory AffiliateClick.fromJson(Map<String, dynamic> json) {
    return AffiliateClick(
      id: json['id'] as String,
      affiliateId: json['affiliateId'] as String,
      ipAddress: json['ipAddress'] as String?,
      userAgent: json['userAgent'] as String?,
      referrer: json['referrer'] as String?,
      clickedAt: (json['clickedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      converted: json['converted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'affiliateId': affiliateId,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'referrer': referrer,
      'clickedAt': Timestamp.fromDate(clickedAt),
      'converted': converted,
    };
  }
}

/// Represents an affiliate conversion (successful referral).
class AffiliateConversion {
  final String id;
  final String affiliateId;
  final String clickId;
  final String? referredUserId;
  final double commission;
  final DateTime convertedAt;
  final bool isPaid;
  final DateTime? paidAt;

  const AffiliateConversion({
    required this.id,
    required this.affiliateId,
    required this.clickId,
    this.referredUserId,
    required this.commission,
    required this.convertedAt,
    this.isPaid = false,
    this.paidAt,
  });

  factory AffiliateConversion.fromJson(Map<String, dynamic> json) {
    return AffiliateConversion(
      id: json['id'] as String,
      affiliateId: json['affiliateId'] as String,
      clickId: json['clickId'] as String,
      referredUserId: json['referredUserId'] as String?,
      commission: (json['commission'] as num).toDouble(),
      convertedAt: (json['convertedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPaid: json['isPaid'] as bool? ?? false,
      paidAt: (json['paidAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'affiliateId': affiliateId,
      'clickId': clickId,
      'referredUserId': referredUserId,
      'commission': commission,
      'convertedAt': Timestamp.fromDate(convertedAt),
      'isPaid': isPaid,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
    };
  }
}
