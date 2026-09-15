enum OrderStatus { pending, completed, refunded, disputed }

class Order {
  final String id;
  final String productId;
  final String productTitle;
  final String buyerId;
  final String sellerId;
  final double amount;
  final double? platformFee;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? licenseKey;
  final String? downloadUrl;
  final String? couponCode;
  final double? discountAmount;

  Order({
    required this.id,
    required this.productId,
    required this.productTitle,
    required this.buyerId,
    required this.sellerId,
    required this.amount,
    this.platformFee,
    this.status = OrderStatus.pending,
    required this.createdAt,
    this.completedAt,
    this.licenseKey,
    this.downloadUrl,
    this.couponCode,
    this.discountAmount,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        'productTitle': productTitle,
        'buyerId': buyerId,
        'sellerId': sellerId,
        'amount': amount,
        'platformFee': platformFee,
        'status': status.index,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'licenseKey': licenseKey,
        'downloadUrl': downloadUrl,
        'couponCode': couponCode,
        'discountAmount': discountAmount,
      };

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'],
        productId: json['productId'],
        productTitle: json['productTitle'],
        buyerId: json['buyerId'],
        sellerId: json['sellerId'],
        amount: json['amount'],
        platformFee: json['platformFee'],
        status: OrderStatus.values.firstWhere(
        (e) => e.index == (json['status'] as int? ?? 0),
        orElse: () => OrderStatus.pending,
      ),
        createdAt: DateTime.parse(json['createdAt']),
        completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
        licenseKey: json['licenseKey'],
        downloadUrl: json['downloadUrl'],
        couponCode: json['couponCode'],
        discountAmount: json['discountAmount'],
      );
}
