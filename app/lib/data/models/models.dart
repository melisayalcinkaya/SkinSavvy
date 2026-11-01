class ProductModel {
  final String id;
  final String name;
  final String brand;
  final String category;
  final String imageUrl;
  final double price;
  final double rating;
  final int reviewCount;
  final String? badge;
  bool isFavorite;

  ProductModel({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.imageUrl,
    required this.price,
    required this.rating,
    required this.reviewCount,
    this.badge,
    this.isFavorite = false,
  });
}

class RoutineItem {
  final String id;
  final String productName;
  final String brand;
  final String time;
  final String emoji;
  bool isCompleted;

  RoutineItem({
    required this.id,
    required this.productName,
    required this.brand,
    required this.time,
    required this.emoji,
    this.isCompleted = false,
  });
}

class MyProduct {
  final String name;
  final String brand;
  final String imageUrl;
  final String category;
  final String status; // 'Kullanımda' | 'Bitmek Üzere'
  final int remaining;
  final String openDate;
  final String expiryDate;
  final String amount;
  final String usage;
  final int rating;
  final String note;
  final bool isFavorite;

  MyProduct({
    required this.name,
    required this.brand,
    required this.imageUrl,
    required this.category,
    required this.status,
    required this.remaining,
    required this.openDate,
    required this.expiryDate,
    required this.amount,
    required this.usage,
    required this.rating,
    required this.note,
    this.isFavorite = false,
  });
}

class WishlistProduct {
  final String name;
  final String brand;
  final String imageUrl;
  final String category;
  final String price;

  WishlistProduct({required this.name, required this.brand, required this.imageUrl, required this.category, required this.price});
}

class FinishedProduct {
  final String name;
  final String brand;
  final String imageUrl;
  final String category;
  final bool wouldRebuy;
  final String note;

  FinishedProduct({required this.name, required this.brand, required this.imageUrl, required this.category, required this.wouldRebuy, required this.note});
}