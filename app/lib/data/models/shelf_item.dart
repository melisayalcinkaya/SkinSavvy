import 'json.dart';

enum ShelfStatus { using, wishlist, finished }

/// Kullanıcının dolabındaki bir ürün: kullandıkları, alınacaklar ya da
/// bitirdikleri. Eskiden üç ayrı sınıftı (MyProduct, WishlistProduct,
/// FinishedProduct) ve ekranlar arasında birbirine elle çevriliyordu.
class ShelfItem {
  const ShelfItem({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    this.productId,
    this.imageUrl = '',
    this.status = ShelfStatus.using,
    this.remaining = 100,
    this.openedOn,
    this.expiresOn,
    this.paoMonths,
    this.amount = '',
    this.usage = '',
    this.rating = 0,
    this.note = '',
    this.isFavorite = false,
    this.price,
    this.wouldRebuy,
    this.finishedOn,
    this.ingredients = const [],
    this.addedOn,
  });

  final String id;

  /// Katalogdaki karşılığı (varsa). İçerik analizi ve yorumlar bunu kullanır.
  final String? productId;
  final String name;
  final String brand;
  final String category;
  final String imageUrl;
  final ShelfStatus status;

  /// Kalan miktar yüzdesi (0-100).
  final int remaining;
  final DateTime? openedOn;

  /// Ambalajdaki son kullanma tarihi (SKT).
  final DateTime? expiresOn;

  /// Açıldıktan sonra kullanım süresi (ay). Kavanoz simgesindeki "12M" gibi.
  final int? paoMonths;
  final String amount;

  /// "Sabah", "Akşam" ya da "Sabah & Akşam".
  final String usage;
  final int rating;
  final String note;
  final bool isFavorite;
  final double? price;
  final bool? wouldRebuy;
  final DateTime? finishedOn;
  final List<String> ingredients;
  final DateTime? addedOn;

  static const lowStockThreshold = 20;

  bool get isRunningLow =>
      status == ShelfStatus.using && remaining < lowStockThreshold;

  String get statusLabel => switch (status) {
    ShelfStatus.wishlist => 'Alınacak',
    ShelfStatus.finished => 'Bitti',
    ShelfStatus.using => isRunningLow ? 'Bitmek Üzere' : 'Kullanımda',
  };

  ShelfItem copyWith({
    String? name,
    String? brand,
    String? category,
    String? imageUrl,
    ShelfStatus? status,
    int? remaining,
    DateTime? openedOn,
    bool clearOpenedOn = false,
    DateTime? expiresOn,
    bool clearExpiresOn = false,
    int? paoMonths,
    bool clearPaoMonths = false,
    String? amount,
    String? usage,
    int? rating,
    String? note,
    bool? isFavorite,
    double? price,
    bool? wouldRebuy,
    DateTime? finishedOn,
    List<String>? ingredients,
  }) => ShelfItem(
    id: id,
    productId: productId,
    name: name ?? this.name,
    brand: brand ?? this.brand,
    category: category ?? this.category,
    imageUrl: imageUrl ?? this.imageUrl,
    status: status ?? this.status,
    remaining: (remaining ?? this.remaining).clamp(0, 100),
    openedOn: clearOpenedOn ? null : (openedOn ?? this.openedOn),
    expiresOn: clearExpiresOn ? null : (expiresOn ?? this.expiresOn),
    paoMonths: clearPaoMonths ? null : (paoMonths ?? this.paoMonths),
    amount: amount ?? this.amount,
    usage: usage ?? this.usage,
    rating: rating ?? this.rating,
    note: note ?? this.note,
    isFavorite: isFavorite ?? this.isFavorite,
    price: price ?? this.price,
    wouldRebuy: wouldRebuy ?? this.wouldRebuy,
    finishedOn: finishedOn ?? this.finishedOn,
    ingredients: ingredients ?? this.ingredients,
    addedOn: addedOn,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'productId': productId,
    'name': name,
    'brand': brand,
    'category': category,
    'imageUrl': imageUrl,
    'status': status.name,
    'remaining': remaining,
    'openedOn': openedOn?.toIso8601String(),
    'expiresOn': expiresOn?.toIso8601String(),
    'paoMonths': paoMonths,
    'amount': amount,
    'usage': usage,
    'rating': rating,
    'note': note,
    'isFavorite': isFavorite,
    'price': price,
    'wouldRebuy': wouldRebuy,
    'finishedOn': finishedOn?.toIso8601String(),
    'ingredients': ingredients,
    'addedOn': addedOn?.toIso8601String(),
  };

  factory ShelfItem.fromJson(Map<String, dynamic> j) => ShelfItem(
    id: asString(j['id']) ?? '',
    productId: asString(j['productId']),
    name: asString(j['name']) ?? '',
    brand: asString(j['brand']) ?? '',
    category: asString(j['category']) ?? 'Diğer',
    imageUrl: asString(j['imageUrl']) ?? '',
    status: asEnum(ShelfStatus.values, j['status'], ShelfStatus.using),
    remaining: asInt(j['remaining'], 100).clamp(0, 100),
    openedOn: asDate(j['openedOn']),
    expiresOn: asDate(j['expiresOn']),
    paoMonths: j['paoMonths'] is num ? asInt(j['paoMonths']) : null,
    amount: asString(j['amount']) ?? '',
    usage: asString(j['usage']) ?? '',
    rating: asInt(j['rating']).clamp(0, 5),
    note: asString(j['note']) ?? '',
    isFavorite: asBool(j['isFavorite']),
    price: asDouble(j['price']),
    wouldRebuy: j['wouldRebuy'] is bool ? j['wouldRebuy'] as bool : null,
    finishedOn: asDate(j['finishedOn']),
    ingredients: asStringList(j['ingredients']),
    addedOn: asDate(j['addedOn']),
  );
}
