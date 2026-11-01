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
    this.rating = 0,
    this.reviewCount = 0,
    this.ingredients = const [],
    this.benefits = const [],
    this.skinTypes = const [],
    this.description = '',
    this.barcode,
    this.status = ProductStatus.approved,
    this.rejectReason,
    this.addedBy,
    this.approvedAt,
    this.submittedBy,
    this.createdAt,
  });

  final String id;
  final String name;
  final String brand;
  final String category;
  final String imageUrl;
  final double rating;
  final int reviewCount;
  final List<String> ingredients;
  final List<String> benefits;
  final List<String> skinTypes;
  final String description;
  final String? barcode;
  final ProductStatus status;

  /// Yönetici reddettiyse gerekçesi (yalnızca ekleyen kişi görür).
  final String? rejectReason;

  /// Ürünü kataloğa ekleyen kişi ("Zeynep K."); e-posta asla taşınmaz.
  final String? addedBy;

  /// Ekibin onayladığı gün, ISO biçiminde ("2026-10-27").
  final String? approvedAt;

  /// Cihaz modunda öneren hesabın kimliği (görünürlük için). Sunucu bunu
  /// istemciye göndermez; orada görünürlüğü sunucu belirler.
  final String? submittedBy;

  /// Önerinin gönderildiği an, ISO biçiminde.
  final String? createdAt;

  DateTime? get approvedDate =>
      approvedAt == null ? null : DateTime.tryParse(approvedAt!);

  /// Son 14 günde onaylanan ürünler "Yeni" rozetiyle gösterilir.
  bool isNew(DateTime now) {
    final d = approvedDate;
    return d != null && !isPending && now.difference(d).inDays < 14;
  }

  Product copyWith({
    double? rating,
    int? reviewCount,
    ProductStatus? status,
    String? rejectReason,
    bool clearRejectReason = false,
    String? approvedAt,
  }) => Product(
    id: id,
    name: name,
    brand: brand,
    category: category,
    imageUrl: imageUrl,
    rating: rating ?? this.rating,
    reviewCount: reviewCount ?? this.reviewCount,
    ingredients: ingredients,
    benefits: benefits,
    skinTypes: skinTypes,
    description: description,
    barcode: barcode,
    status: status ?? this.status,
    rejectReason: clearRejectReason
        ? null
        : (rejectReason ?? this.rejectReason),
    addedBy: addedBy,
    approvedAt: approvedAt ?? this.approvedAt,
    submittedBy: submittedBy,
    createdAt: createdAt,
  );

  bool get isPending => status == ProductStatus.pending;
  bool get isRejected => status == ProductStatus.rejected;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'brand': brand,
    'category': category,
    'imageUrl': imageUrl,
    'rating': rating,
    'reviewCount': reviewCount,
    'ingredients': ingredients,
    'benefits': benefits,
    'skinTypes': skinTypes,
    'description': description,
    'barcode': barcode,
    'status': status.name,
    if (rejectReason != null) 'rejectReason': rejectReason,
    if (addedBy != null) 'addedBy': addedBy,
    if (approvedAt != null) 'approvedAt': approvedAt,
    if (submittedBy != null) 'submittedBy': submittedBy,
    if (createdAt != null) 'createdAt': createdAt,
  };

  factory Product.fromJson(Map<String, dynamic> j) => Product(
    id: asString(j['id']) ?? '',
    name: asString(j['name']) ?? '',
    brand: asString(j['brand']) ?? '',
    category: asString(j['category']) ?? 'Diğer',
    imageUrl: asString(j['imageUrl']) ?? '',
    rating: asDouble(j['rating']) ?? 0,
    reviewCount: asInt(j['reviewCount']),
    ingredients: asStringList(j['ingredients']),
    benefits: asStringList(j['benefits']),
    skinTypes: asStringList(j['skinTypes']),
    description: asString(j['description']) ?? '',
    barcode: asString(j['barcode']),
    status: asEnum(ProductStatus.values, j['status'], ProductStatus.approved),
    rejectReason: asString(j['rejectReason']),
    addedBy: asString(j['addedBy']),
    approvedAt: asString(j['approvedAt']),
    submittedBy: asString(j['submittedBy']),
    createdAt: asString(j['createdAt']),
  );
}
