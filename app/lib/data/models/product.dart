import 'json.dart';

/// Bir ürünün katalogdaki durumu.
///
/// Kullanıcının eklediği ürün `pending` başlar ve yalnızca ekleyen görür.
/// Ekip onu (gerekirse düzeltip) onaylar → `approved`, aynısı zaten varsa
/// asıl ürüne bağlar → `duplicate`, spam/sahte ise siler → `removed`.
/// Reddetme yok: eksik ya da hatalı bilgiyi ekip düzeltir.
enum ProductStatus { approved, pending, duplicate, removed }

/// Katalogdaki ürün.
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
    this.duplicateOf,
    this.editedByTeam = false,
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

  /// Yinelenen öneride asıl ürünün kimliği.
  final String? duplicateOf;

  /// Ekip onaylamadan önce bilgileri düzeltti mi?
  final bool editedByTeam;

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
    String? name,
    String? brand,
    String? category,
    String? imageUrl,
    double? rating,
    int? reviewCount,
    List<String>? ingredients,
    List<String>? skinTypes,
    String? description,
    String? barcode,
    bool clearBarcode = false,
    ProductStatus? status,
    String? duplicateOf,
    bool? editedByTeam,
    String? approvedAt,
  }) => Product(
    id: id,
    name: name ?? this.name,
    brand: brand ?? this.brand,
    category: category ?? this.category,
    imageUrl: imageUrl ?? this.imageUrl,
    rating: rating ?? this.rating,
    reviewCount: reviewCount ?? this.reviewCount,
    ingredients: ingredients ?? this.ingredients,
    benefits: benefits,
    skinTypes: skinTypes ?? this.skinTypes,
    description: description ?? this.description,
    barcode: clearBarcode ? null : (barcode ?? this.barcode),
    status: status ?? this.status,
    duplicateOf: duplicateOf ?? this.duplicateOf,
    editedByTeam: editedByTeam ?? this.editedByTeam,
    addedBy: addedBy,
    approvedAt: approvedAt ?? this.approvedAt,
    submittedBy: submittedBy,
    createdAt: createdAt,
  );

  bool get isPending => status == ProductStatus.pending;
  bool get isApproved => status == ProductStatus.approved;
  bool get isDuplicate => status == ProductStatus.duplicate;
  bool get isRemoved => status == ProductStatus.removed;

  /// Katalogda yer alabilir mi (yinelenen ya da silinen değil)?
  bool get isLive => isApproved || isPending;

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
    if (duplicateOf != null) 'duplicateOf': duplicateOf,
    if (editedByTeam) 'editedByTeam': true,
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
    // Eski sürümde "rejected" vardı; artık yok, silinmiş sayılır.
    status: j['status'] == 'rejected'
        ? ProductStatus.removed
        : asEnum(ProductStatus.values, j['status'], ProductStatus.approved),
    duplicateOf: asString(j['duplicateOf']),
    editedByTeam: asBool(j['editedByTeam']),
    addedBy: asString(j['addedBy']),
    approvedAt: asString(j['approvedAt']),
    submittedBy: asString(j['submittedBy']),
    createdAt: asString(j['createdAt']),
  );
}
