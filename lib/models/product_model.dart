enum ProductType { digital, course, template, license, hybrid, ugc }
enum ProductStatus { active, pending, rejected, draft }

class Product {
  final String id;
  final String title;
  final String description;
  final String sellerId;
  final String sellerName;
  final String sellerAvatar;
  double price;
  double? originalPrice;
  final ProductType type;
  final List<String> images;
  final List<String> tags;
  final String category;
  final String? previewUrl;
  final List<String> features;
  final Map<String, dynamic>? metadata;
  final ProductStatus status;
  final DateTime createdAt;
  int salesCount;
  double rating;
  int reviewsCount;
  bool isFeatured;
  String? licenseKey;
  int? stock;
  bool isPayAsYouSell;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.sellerId,
    required this.sellerName,
    required this.sellerAvatar,
    required this.price,
    this.originalPrice,
    required this.type,
    required this.images,
    required this.tags,
    required this.category,
    this.previewUrl,
    required this.features,
    this.metadata,
    this.status = ProductStatus.active,
    required this.createdAt,
    this.salesCount = 0,
    this.rating = 0.0,
    this.reviewsCount = 0,
    this.isFeatured = false,
    this.licenseKey,
    this.stock,
    this.isPayAsYouSell = false,
  });

  double get discountPercent => originalPrice != null && originalPrice! > 0
      ? ((originalPrice! - price) / originalPrice! * 100).roundToDouble()
      : 0;

  bool get isOnSale => originalPrice != null && originalPrice! > price;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'sellerId': sellerId,
        'sellerName': sellerName,
        'sellerAvatar': sellerAvatar,
        'price': price,
        'originalPrice': originalPrice,
        'type': type.index,
        'images': images,
        'tags': tags,
        'category': category,
        'previewUrl': previewUrl,
        'features': features,
        'metadata': metadata,
        'status': status.index,
        'createdAt': createdAt.toIso8601String(),
        'salesCount': salesCount,
        'rating': rating,
        'reviewsCount': reviewsCount,
        'isFeatured': isFeatured,
        'licenseKey': licenseKey,
        'stock': stock,
        'isPayAsYouSell': isPayAsYouSell,
      };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        sellerId: json['sellerId'],
        sellerName: json['sellerName'],
        sellerAvatar: json['sellerAvatar'],
        price: json['price'],
        originalPrice: json['originalPrice'],
        type: ProductType.values.firstWhere(
        (e) => e.index == (json['type'] as int? ?? 0),
        orElse: () => ProductType.digital,
      ),
        images: List<String>.from(json['images']),
        tags: List<String>.from(json['tags']),
        category: json['category'],
        previewUrl: json['previewUrl'],
        features: List<String>.from(json['features']),
        metadata: json['metadata'],
        status: ProductStatus.values.firstWhere(
        (e) => e.index == (json['status'] as int? ?? 0),
        orElse: () => ProductStatus.active,
      ),
        createdAt: DateTime.parse(json['createdAt']),
        salesCount: json['salesCount'] ?? 0,
        rating: json['rating'] ?? 0.0,
        reviewsCount: json['reviewsCount'] ?? 0,
        isFeatured: json['isFeatured'] ?? false,
        licenseKey: json['licenseKey'],
        stock: json['stock'],
        isPayAsYouSell: json['isPayAsYouSell'] ?? false,
      );
}
