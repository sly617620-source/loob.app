class SellerAnalytics {
  final double totalRevenue;
  final int totalSales;
  final int totalViews;
  final double conversionRate;
  final List<DailySale> dailySales;
  final List<CategoryStat> categoryStats;
  final List<ProductPerformance> topProducts;

  SellerAnalytics({
    required this.totalRevenue,
    required this.totalSales,
    required this.totalViews,
    required this.conversionRate,
    required this.dailySales,
    required this.categoryStats,
    required this.topProducts,
  });
}

class DailySale {
  final DateTime date;
  final double revenue;
  final int sales;

  DailySale({required this.date, required this.revenue, required this.sales});
}

class CategoryStat {
  final String category;
  final int sales;
  final double revenue;

  CategoryStat(
      {required this.category, required this.sales, required this.revenue});
}

class ProductPerformance {
  final String productId;
  final String title;
  final int views;
  final int sales;
  final double revenue;

  ProductPerformance({
    required this.productId,
    required this.title,
    required this.views,
    required this.sales,
    required this.revenue,
  });
}
