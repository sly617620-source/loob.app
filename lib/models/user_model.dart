import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a user in the Loob platform.
class User {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? phoneNumber;
  final UserRole role;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isActive;
  final double? balance;
  final String? bio;
  final List<String> socialLinks;
  final List<String> categories;
  final double? rating;
  final int? completedCampaigns;
  final int totalSubmissions;
  final int approvedSubmissions;
  final double totalEarnings;

  const User({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.phoneNumber,
    this.role = UserRole.customer,
    required this.createdAt,
    this.lastLoginAt,
    this.isActive = true,
    this.balance,
    this.bio,
    this.socialLinks = const [],
    this.categories = const [],
    this.rating,
    this.completedCampaigns,
    this.totalSubmissions = 0,
    this.approvedSubmissions = 0,
    this.totalEarnings = 0.0,
  });

  // compatibility aliases for older code that expected `name` and `avatar`.
  // Non-nullable with an empty-string fallback so call sites that render
  // these directly into a `Text()` widget compile safely.
  String get name => displayName ?? '';
  String get avatar => photoUrl ?? '';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      role: UserRole.values.firstWhere(
        (e) => e.name == (json['role'] as String? ?? 'customer'),
        orElse: () => UserRole.customer,
      ),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (json['lastLoginAt'] as Timestamp?)?.toDate(),
      isActive: json['isActive'] as bool? ?? true,
      balance: (json['balance'] as num?)?.toDouble(),
      bio: json['bio'] as String?,
      socialLinks: List<String>.from(json['socialLinks'] ?? []),
      categories: List<String>.from(json['categories'] ?? []),
      rating: (json['rating'] as num?)?.toDouble(),
      completedCampaigns: json['completedCampaigns'] as int?,
      totalSubmissions: json['totalSubmissions'] as int? ?? 0,
      approvedSubmissions: json['approvedSubmissions'] as int? ?? 0,
      totalEarnings: (json['totalEarnings'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Alias for [fromJson] to support map-based deserialization.
  factory User.fromMap(Map<String, dynamic> map) => User.fromJson(map);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'role': role.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'isActive': isActive,
      'balance': balance,
      'bio': bio,
      'socialLinks': socialLinks,
      'categories': categories,
      'rating': rating,
      'completedCampaigns': completedCampaigns,
      'totalSubmissions': totalSubmissions,
      'approvedSubmissions': approvedSubmissions,
      'totalEarnings': totalEarnings,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    UserRole? role,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isActive,
    double? balance,
    String? bio,
    List<String>? socialLinks,
    List<String>? categories,
    double? rating,
    int? completedCampaigns,
    int? totalSubmissions,
    int? approvedSubmissions,
    double? totalEarnings,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
      balance: balance ?? this.balance,
      bio: bio ?? this.bio,
      socialLinks: socialLinks ?? this.socialLinks,
      categories: categories ?? this.categories,
      rating: rating ?? this.rating,
      completedCampaigns: completedCampaigns ?? this.completedCampaigns,
      totalSubmissions: totalSubmissions ?? this.totalSubmissions,
      approvedSubmissions: approvedSubmissions ?? this.approvedSubmissions,
      totalEarnings: totalEarnings ?? this.totalEarnings,
    );
  }

  @override
  String toString() => 'User(id: $id, email: $email, name: $displayName, role: $role)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Account type. Determines which screens/navigation the user sees.
///
/// - [campaignCreator]: creates & funds advertising campaigns (formerly
///   "brand"). Sees campaign management + incoming submissions to review.
/// - [seller]: lists digital products in the marketplace. Sees the seller
///   dashboard (products, orders, analytics).
/// - [contentCreator]: browses campaigns and submits content against them
///   for a CPM-based payout (formerly "influencer"). Sees the campaigns
///   feed + "my submissions" + earnings.
/// - [customer]: just browses & buys products from the marketplace.
/// - [admin]: internal/staff account, kept for completeness.
enum UserRole { campaignCreator, seller, contentCreator, customer, admin }

extension UserRoleX on UserRole {
  /// Arabic display label used across the UI (settings, badges, dialogs).
  String get label {
    switch (this) {
      case UserRole.campaignCreator:
        return 'منشئ حملة';
      case UserRole.seller:
        return 'بائع';
      case UserRole.contentCreator:
        return 'صانع محتوى';
      case UserRole.customer:
        return 'عميل';
      case UserRole.admin:
        return 'مسؤول';
    }
  }

  /// Short one-line description shown under the label when picking a role.
  String get description {
    switch (this) {
      case UserRole.campaignCreator:
        return 'أنشئ حملات إعلانية وادفع لصناع المحتوى مقابل النشر';
      case UserRole.seller:
        return 'اعرض وبع منتجاتك الرقمية في السوق';
      case UserRole.contentCreator:
        return 'اكتشف الحملات وانشر محتوى لتربح مقابل كل ألف مشاهدة';
      case UserRole.customer:
        return 'تصفح السوق واشترِ المنتجات التي تحتاجها';
      case UserRole.admin:
        return 'حساب إداري داخلي';
    }
  }

  String get emoji {
    switch (this) {
      case UserRole.campaignCreator:
        return '📢';
      case UserRole.seller:
        return '🏪';
      case UserRole.contentCreator:
        return '🎬';
      case UserRole.customer:
        return '🛍️';
      case UserRole.admin:
        return '🛡️';
    }
  }

  bool get managesCampaigns => this == UserRole.campaignCreator;
  bool get managesProducts => this == UserRole.seller;
  bool get canSubmitToCampaigns => this == UserRole.contentCreator;
}
