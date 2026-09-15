import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:loob/models/user_model.dart';

/// Represents a marketing campaign in the Loob platform.
class Campaign {
  final String id;
  final String brandId;
  final String title;
  final String description;
  final String? imageUrl;
  final double budget;
  final double rewardPerSubmission;
  final CampaignStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> requirements;
  final List<String> categories;
  final int maxSubmissions;
  final int currentSubmissions;
  final DateTime createdAt;
  final DateTime updatedAt;
  final User? brand;

  // --- Fields added to power the campaigns marketplace card (CPM-based
  // "clipping" campaigns: brand pays per 1000 views a creator's post gets).
  /// Display name of the campaign owner (kept even without a full [brand]
  /// object, e.g. for locally-created mock/demo campaigns).
  final String? brandName;

  /// 1-2 letter avatar/initials shown in the campaign card, e.g. "AS".
  final String? brandAvatar;

  /// Cost-per-mille: amount paid per 1000 verified views a submission gets.
  final double cpm;

  /// Total views accumulated across all approved submissions so far.
  final int viewsCount;

  /// Average rating creators give this campaign/brand (0-5).
  final double avgRating;

  /// Amount of [budget] already committed/paid out so far.
  final double spentBudget;

  const Campaign({
    required this.id,
    required this.brandId,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.budget,
    required this.rewardPerSubmission,
    this.status = CampaignStatus.pending,
    required this.startDate,
    required this.endDate,
    this.requirements = const [],
    this.categories = const [],
    required this.maxSubmissions,
    this.currentSubmissions = 0,
    required this.createdAt,
    required this.updatedAt,
    this.brand,
    this.brandName,
    this.brandAvatar,
    this.cpm = 0.0,
    this.viewsCount = 0,
    this.avgRating = 0.0,
    this.spentBudget = 0.0,
  });

  factory Campaign.fromJson(Map<String, dynamic> json) {
    return Campaign(
      id: json['id'] as String,
      brandId: json['brandId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String?,
      budget: (json['budget'] as num).toDouble(),
      rewardPerSubmission: (json['rewardPerSubmission'] as num).toDouble(),
      status: CampaignStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String? ?? 'pending'),
        orElse: () => CampaignStatus.pending,
      ),
      startDate: (json['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (json['endDate'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 30)),
      requirements: List<String>.from(json['requirements'] ?? []),
      categories: List<String>.from(json['categories'] ?? []),
      maxSubmissions: json['maxSubmissions'] as int? ?? 100,
      currentSubmissions: json['currentSubmissions'] as int? ?? 0,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      brand: json['brand'] != null ? User.fromJson(json['brand'] as Map<String, dynamic>) : null,
      brandName: json['brandName'] as String?,
      brandAvatar: json['brandAvatar'] as String?,
      cpm: (json['cpm'] as num?)?.toDouble() ?? 0.0,
      viewsCount: json['viewsCount'] as int? ?? 0,
      avgRating: (json['avgRating'] as num?)?.toDouble() ?? 0.0,
      spentBudget: (json['spentBudget'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'brandId': brandId,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'budget': budget,
      'rewardPerSubmission': rewardPerSubmission,
      'status': status.name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'requirements': requirements,
      'categories': categories,
      'maxSubmissions': maxSubmissions,
      'currentSubmissions': currentSubmissions,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'brand': brand?.toJson(),
      'brandName': brandName,
      'brandAvatar': brandAvatar,
      'cpm': cpm,
      'viewsCount': viewsCount,
      'avgRating': avgRating,
      'spentBudget': spentBudget,
    };
  }

  Campaign copyWith({
    String? id,
    String? brandId,
    String? title,
    String? description,
    String? imageUrl,
    double? budget,
    double? rewardPerSubmission,
    CampaignStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? requirements,
    List<String>? categories,
    int? maxSubmissions,
    int? currentSubmissions,
    DateTime? createdAt,
    DateTime? updatedAt,
    User? brand,
    String? brandName,
    String? brandAvatar,
    double? cpm,
    int? viewsCount,
    double? avgRating,
    double? spentBudget,
  }) {
    return Campaign(
      id: id ?? this.id,
      brandId: brandId ?? this.brandId,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      budget: budget ?? this.budget,
      rewardPerSubmission: rewardPerSubmission ?? this.rewardPerSubmission,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      requirements: requirements ?? this.requirements,
      categories: categories ?? this.categories,
      maxSubmissions: maxSubmissions ?? this.maxSubmissions,
      currentSubmissions: currentSubmissions ?? this.currentSubmissions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      brand: brand ?? this.brand,
      brandName: brandName ?? this.brandName,
      brandAvatar: brandAvatar ?? this.brandAvatar,
      cpm: cpm ?? this.cpm,
      viewsCount: viewsCount ?? this.viewsCount,
      avgRating: avgRating ?? this.avgRating,
      spentBudget: spentBudget ?? this.spentBudget,
    );
  }

  bool get isActive => status == CampaignStatus.active && DateTime.now().isBefore(endDate);
  bool get isFull => currentSubmissions >= maxSubmissions;
  double get progress => maxSubmissions > 0 ? currentSubmissions / maxSubmissions : 0.0;

  /// Display name for the card header; falls back gracefully when the
  /// campaign has no linked [brand] user object.
  String get displayBrandName => brand?.name.isNotEmpty == true ? brand!.name : (brandName ?? 'جهة إعلانية');
  String get displayBrandAvatar {
    if (brandAvatar != null && brandAvatar!.isNotEmpty) return brandAvatar!;
    final name = displayBrandName.trim();
    if (name.isEmpty) return '؟';
    return name.substring(0, name.length >= 2 ? 2 : 1);
  }

  int get daysRemaining => endDate.difference(DateTime.now()).inDays.clamp(0, 100000);

  /// Percentage (0-100) of [budget] already spent.
  double get budgetPercent =>
      budget > 0 ? (spentBudget / budget * 100).clamp(0, 100) : 0.0;

  @override
  String toString() => 'Campaign(id: $id, title: $title, status: $status)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Campaign && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

enum CampaignStatus { pending, active, paused, completed, cancelled }
