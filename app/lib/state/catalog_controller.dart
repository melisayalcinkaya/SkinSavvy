import '../core/utils/ids.dart';
import '../core/utils/text_utils.dart';
import '../data/demo/demo_catalog.dart';
import '../data/local/keys.dart';
import '../data/models/json.dart';
import '../data/models/product.dart';
import 'user_store.dart';

/// Ürün kataloğu, favoriler ve kullanıcının onaya gönderdiği ürünler.
class CatalogController extends UserStore {
  CatalogController(
    super.store,
    super.uid, {
    List<Product> catalog = demoCatalog,
  }) : _catalog = catalog {
    _favorites = asStringList(readValue(StoreKeys.favorites)).toSet();
    _submissions = readList(
      StoreKeys.submissions,
    ).map(Product.fromJson).toList();
  }

  final List<Product> _catalog;
  Set<String> _favorites = {};
  List<Product> _submissions = [];

  /// Onaylı katalog + kullanıcının onay bekleyen ürünleri (yalnızca kendisi görür).
  List<Product> get products => [..._submissions, ..._catalog];

  List<Product> get submissions => List.unmodifiable(_submissions);

  Product? byId(String? id) {
    if (id == null) return null;
    for (final p in products) {
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
  Product? findDuplicate(String name, String brand) {
    final n = searchKey(name);
    final b = searchKey(brand);
    for (final p in products) {
      if (searchKey(p.name) == n && searchKey(p.brand) == b) return p;
    }
    return null;
  }

  Product submit({
    required String name,
    required String brand,
    required String category,
    required List<String> skinTypes,
    required List<String> ingredients,
    String description = '',
    String? barcode,
    String imageUrl = '',
  }) {
    final product = Product(
      id: newId('p'),
      name: sanitizeInput(name),
      brand: sanitizeInput(brand),
      category: category,
      skinTypes: skinTypes,
      ingredients: ingredients,
      description: sanitizeInput(description),
      barcode: barcode == null || barcode.isEmpty ? null : barcode,
      imageUrl: imageUrl,
      status: ProductStatus.pending,
    );
    _submissions = [product, ..._submissions];
    writeValue(
      StoreKeys.submissions,
      _submissions.map((e) => e.toJson()).toList(),
    );
    notifyListeners();
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
