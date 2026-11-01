import 'json.dart';

class Review {
  const Review({
    required this.id,
    required this.productName,
    required this.brand,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.productId,
    this.shelfItemId,
    this.imageUrl = '',
    this.updatedAt,
  });

  final String id;
  final String? productId;
  final String? shelfItemId;
  final String productName;
  final String brand;
  final String imageUrl;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Review copyWith({int? rating, String? comment, DateTime? updatedAt}) =>
      Review(
        id: id,
        productId: productId,
        shelfItemId: shelfItemId,
        productName: productName,
        brand: brand,
        imageUrl: imageUrl,
        rating: rating ?? this.rating,
        comment: comment ?? this.comment,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'productId': productId,
    'shelfItemId': shelfItemId,
    'productName': productName,
    'brand': brand,
    'imageUrl': imageUrl,
    'rating': rating,
    'comment': comment,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  factory Review.fromJson(Map<String, dynamic> j) => Review(
    id: asString(j['id']) ?? '',
    productId: asString(j['productId']),
    shelfItemId: asString(j['shelfItemId']),
    productName: asString(j['productName']) ?? '',
    brand: asString(j['brand']) ?? '',
    imageUrl: asString(j['imageUrl']) ?? '',
    rating: asInt(j['rating']).clamp(1, 5),
    comment: asString(j['comment']) ?? '',
    createdAt: asDate(j['createdAt']) ?? DateTime.now(),
    updatedAt: asDate(j['updatedAt']),
  );
}
