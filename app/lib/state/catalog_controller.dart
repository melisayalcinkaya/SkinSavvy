import '../core/utils/ids.dart';
import '../core/utils/text_utils.dart';
import '../data/demo/demo_catalog.dart';
import '../data/local/keys.dart';
import '../data/models/json.dart';
import '../data/models/product.dart';
import '../data/remote/api_client.dart';
import 'user_store.dart';

/// Ürün kataloğu, favoriler ve kullanıcının onaya gönderdiği ürünler.
///
/// Cihaz modunda katalog uygulamanın içindeki demo listesidir, öneriler
/// cihazda saklanır. Sunucu modunda ([api] verilirse) katalog ve önerilerin
/// durumu (bekliyor / onaylandı / reddedildi) API'den gelir. Favoriler her
/// iki modda cihazda kalır.
class CatalogController extends UserStore {
  CatalogController(
    super.store,
    super.uid, {
    List<Product> catalog = demoCatalog,
    this.api,
  }) : _catalog = catalog {
    _favorites = asStringList(readValue(StoreKeys.favorites)).toSet();
    if (api == null) {
      _submissions = readList(
        StoreKeys.submissions,
      ).map(Product.fromJson).toList();
    } else {
      _catalog = const [];
      reload();
    }
  }

  final ApiClient? api;
  List<Product> _catalog;
  Set<String> _favorites = {};
  List<Product> _submissions = [];
  bool _loading = false;
  String? _error;
  bool _disposed = false;

  bool get isRemote => api != null;
  bool get isLoading => _loading;

  /// Son yükleme hatası (sunucu modu); null ise sorun yok.
  String? get loadError => _error;

  /// Onaylı katalog + kullanıcının onay bekleyen ürünleri (yalnızca kendisi görür).
  List<Product> get products => [
    ..._submissions.where((p) => !p.isRejected),
    ..._catalog.where((p) => !_submissions.any((s) => s.id == p.id)),
  ];

  /// Kullanıcının önerileri; reddedilenler gerekçesiyle birlikte.
  List<Product> get submissions => List.unmodifiable(_submissions);

  /// Sunucudan katalog ve öneri durumlarını yeniden çeker.
  Future<void> reload() async {
    final client = api;
    if (client == null) return;
    _loading = true;
    _error = null;
    _notify();
    try {
      final page = asMap(
        await client.get('/products', query: {'limit': '100'}),
      );
      _catalog = [
        for (final p in page['items'] is List ? page['items'] as List : [])
          Product.fromJson(asMap(p)),
      ].where((p) => p.status == ProductStatus.approved).toList();
      _submissions = uid == null
          ? []
          : [
              for (final p in await client.get('/products/mine') as List)
                Product.fromJson(asMap(p)),
            ];
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _loading = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Product? byId(String? id) {
    if (id == null) return null;
    for (final p in [...products, ..._submissions]) {
      if (p.id == id) return p;
    }
    return null;
  }

  List<Product> search({String query = '', String category = 'Tümü'}) {
    final q = searchKey(query);
    return products.where((p) {
      final matchesQuery =
          q.isEmpty ||
          searchKey(p.name).contains(q) ||
          searchKey(p.brand).contains(q);
      final matchesCategory = category == 'Tümü' || p.category == category;
      return matchesQuery && matchesCategory;
    }).toList();
  }

  bool isFavorite(String productId) => _favorites.contains(productId);

  void toggleFavorite(String productId) {
    _favorites = {..._favorites};
    _favorites.contains(productId)
        ? _favorites.remove(productId)
        : _favorites.add(productId);
    writeValue(StoreKeys.favorites, _favorites.toList());
    notifyListeners();
  }

  /// Aynı ad ve markada ürün var mı? (büyük/küçük harf ve Türkçe karakter duyarsız)
  /// Sunucu da aynı kontrolü yapar; bu yalnızca kullanıcıyı erken uyarır.
  Product? findDuplicate(String name, String brand) {
    final n = searchKey(name);
    final b = searchKey(brand);
    for (final p in products) {
      if (searchKey(p.name) == n && searchKey(p.brand) == b) return p;
    }
    return null;
  }

  /// Ürünü yönetici onayına gönderir. Sunucu modunda hata olursa
  /// [ApiException] fırlatır (ör. 409: ürün zaten var).
  Future<Product> submit({
    required String name,
    required String brand,
    required String category,
    required List<String> skinTypes,
    required List<String> ingredients,
    String description = '',
    String? barcode,
    String imageUrl = '',
  }) async {
    final client = api;
    final cleanBarcode = barcode == null || barcode.isEmpty ? null : barcode;
    final Product product;
    if (client != null) {
      product = Product.fromJson(
        asMap(
          await client.post('/products', {
            'name': sanitizeInput(name),
            'brand': sanitizeInput(brand),
            'category': category,
            'skinTypes': skinTypes,
            'ingredients': ingredients,
            'description': sanitizeInput(description),
            'barcode': cleanBarcode,
            'imageUrl': imageUrl,
          }),
        ),
      );
    } else {
      product = Product(
        id: newId('p'),
        name: sanitizeInput(name),
        brand: sanitizeInput(brand),
        category: category,
        skinTypes: skinTypes,
        ingredients: ingredients,
        description: sanitizeInput(description),
        barcode: cleanBarcode,
        imageUrl: imageUrl,
        status: ProductStatus.pending,
      );
    }
    _submissions = [product, ..._submissions];
    if (client == null) {
      writeValue(
        StoreKeys.submissions,
        _submissions.map((e) => e.toJson()).toList(),
      );
    }
    _notify();
    return product;
  }
}

/// "Aqua, Glycerin, Niacinamide..." metnini içerik listesine çevirir.
/// Parantez içindeki virgülleri (ör. "Parfum (Fragrance, Koku)") bölmez.
List<String> parseIngredients(String text) {
  final items = <String>[];
  final buffer = StringBuffer();
  var depth = 0;
  for (final ch in text.split('')) {
    if (ch == '(') depth++;
    if (ch == ')' && depth > 0) depth--;
    if ((ch == ',' || ch == '\n' || ch == ';') && depth == 0) {
      items.add(buffer.toString());
      buffer.clear();
    } else {
      buffer.write(ch);
    }
  }
  items.add(buffer.toString());
  return items
      .map(
        (e) => sanitizeInput(
          e,
        ).replaceAll(RegExp(r'\s+'), ' ').replaceAll(RegExp(r'\.$'), ''),
      )
      .where((e) => e.isNotEmpty)
      .toList();
}
