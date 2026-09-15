class Review {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final String userAvatar;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final List<String>? images;
  final int helpfulCount;
  final String? sellerReply;

  Review({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.images,
    this.helpfulCount = 0,
    this.sellerReply,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        'userId': userId,
        'userName': userName,
        'userAvatar': userAvatar,
        'rating': rating,
        'comment': comment,
        'createdAt': createdAt.toIso8601String(),
        'images': images,
        'helpfulCount': helpfulCount,
        'sellerReply': sellerReply,
      };

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: json['id'],
        productId: json['productId'],
        userId: json['userId'],
        userName: json['userName'],
        userAvatar: json['userAvatar'],
        rating: json['rating'],
        comment: json['comment'],
        createdAt: DateTime.parse(json['createdAt']),
        images: json['images'] != null ? List<String>.from(json['images']) : null,
        helpfulCount: json['helpfulCount'] ?? 0,
        sellerReply: json['sellerReply'],
      );
}
