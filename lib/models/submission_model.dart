import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:loob/models/user_model.dart';
import 'package:loob/models/campaign_model.dart';

/// Represents a content submission for a campaign.
class Submission {
  final String id;
  final String campaignId;
  final String influencerId;
  final String? contentUrl;
  final String? caption;
  final String? platform;
  final SubmissionStatus status;
  final String? feedback;
  final double? reward;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final DateTime? paidAt;
  final User? influencer;
  final Campaign? campaign;

  const Submission({
    required this.id,
    required this.campaignId,
    required this.influencerId,
    this.contentUrl,
    this.caption,
    this.platform,
    this.status = SubmissionStatus.pending,
    this.feedback,
    this.reward,
    required this.submittedAt,
    this.reviewedAt,
    this.paidAt,
    this.influencer,
    this.campaign,
  });

  factory Submission.fromJson(Map<String, dynamic> json) {
    return Submission(
      id: json['id'] as String,
      campaignId: json['campaignId'] as String,
      influencerId: json['influencerId'] as String,
      contentUrl: json['contentUrl'] as String?,
      caption: json['caption'] as String?,
      platform: json['platform'] as String?,
      status: SubmissionStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String? ?? 'pending'),
        orElse: () => SubmissionStatus.pending,
      ),
      feedback: json['feedback'] as String?,
      reward: (json['reward'] as num?)?.toDouble(),
      submittedAt: (json['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewedAt: (json['reviewedAt'] as Timestamp?)?.toDate(),
      paidAt: (json['paidAt'] as Timestamp?)?.toDate(),
      influencer: json['influencer'] != null
          ? User.fromJson(json['influencer'] as Map<String, dynamic>)
          : null,
      campaign: json['campaign'] != null
          ? Campaign.fromJson(json['campaign'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'campaignId': campaignId,
      'influencerId': influencerId,
      'contentUrl': contentUrl,
      'caption': caption,
      'platform': platform,
      'status': status.name,
      'feedback': feedback,
      'reward': reward,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'influencer': influencer?.toJson(),
      'campaign': campaign?.toJson(),
    };
  }

  Submission copyWith({
    String? id,
    String? campaignId,
    String? influencerId,
    String? contentUrl,
    String? caption,
    String? platform,
    SubmissionStatus? status,
    String? feedback,
    double? reward,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    DateTime? paidAt,
    User? influencer,
    Campaign? campaign,
  }) {
    return Submission(
      id: id ?? this.id,
      campaignId: campaignId ?? this.campaignId,
      influencerId: influencerId ?? this.influencerId,
      contentUrl: contentUrl ?? this.contentUrl,
      caption: caption ?? this.caption,
      platform: platform ?? this.platform,
      status: status ?? this.status,
      feedback: feedback ?? this.feedback,
      reward: reward ?? this.reward,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      paidAt: paidAt ?? this.paidAt,
      influencer: influencer ?? this.influencer,
      campaign: campaign ?? this.campaign,
    );
  }

  bool get isPending => status == SubmissionStatus.pending;
  bool get isApproved => status == SubmissionStatus.approved;
  bool get isPaid => status == SubmissionStatus.paid;

  @override
  String toString() => 'Submission(id: $id, campaignId: $campaignId, status: $status)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Submission && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

enum SubmissionStatus { pending, approved, rejected, paid, cancelled }
