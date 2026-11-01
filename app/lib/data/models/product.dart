import 'json.dart';

enum ProductStatus { approved, pending, rejected }

/// Katalogdaki ürün. Kullanıcının eklediği ürünler yönetici onayına kadar
/// `pending` durumunda kalır ve yalnızca ekleyen kişi görür.
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    this.imageUrl = '',
    this.price,
    this.rating = 0,
    this.reviewCount = 0,
    this.badge,
    this.ingredients = const [],
    this.benefits = const [],
    this.skinTypes = const [],
    this.description = '',
    this.barcode,
    this.status = ProductStatus.approved,
  });

  final String id;
  final String name;
  final String brand;
  final String category;
  final String imageUrl;
  final double? price;
  final double rating;
  final int reviewCount;
  final String? badge;
  final List<String> ingredients;
  final List<String> benefits;
  final List<String> skinTypes;
  final String description;
  final String? barcode;
  final ProductStatus status;

  bool get isPending => status == ProductStatus.pending;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'brand': brand,
    'category': category,
    'imageUrl': imageUrl,
    'price': price,
    'rating': rating,
    'reviewCount': reviewCount,
    'badge': badge,
    'ingredients': ingredients,
    'benefits': benefits,
    'skinTypes': skinTypes,
    'description': description,
    'barcode': barcode,
    'status': status.name,
  };

  factory Product.fromJson(Map<String, dynamic> j) => Product(
    id: asString(j['id']) ?? '',
    name: asString(j['name']) ?? '',
    brand: asString(j['brand']) ?? '',
    category: asString(j['category']) ?? 'Diğer',
    imageUrl: asString(j['imageUrl']) ?? '',
    price: asDouble(j['price']),
    rating: asDouble(j['rating']) ?? 0,
    reviewCount: asInt(j['reviewCount']),
    badge: asString(j['badge']),
    ingredients: asStringList(j['ingredients']),
    benefits: asStringList(j['benefits']),
    skinTypes: asStringList(j['skinTypes']),
    description: asString(j['description']) ?? '',
    barcode: asString(j['barcode']),
    status: asEnum(ProductStatus.values, j['status'], ProductStatus.approved),
  );
}
