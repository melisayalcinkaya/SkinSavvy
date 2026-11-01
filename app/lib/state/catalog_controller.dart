import '../core/utils/date_utils.dart';
import '../core/utils/ids.dart';
import '../core/utils/text_utils.dart';
import '../data/demo/demo_catalog.dart';
import '../data/demo/demo_reviews.dart';
import '../data/local/keys.dart';
import '../data/models/json.dart';
import '../data/models/product.dart';
import '../data/remote/api_client.dart';
import 'review_controller.dart';
import 'user_store.dart';

/// Ürün kataloğu: topluluğun eklediği, ekibin onayladığı ürünler.
///
/// Akış (iki modda aynı): kullanıcı aradığı ürünü bulamazsa önerir → ürün
/// "onay bekliyor" olur ve yalnızca öneren görür → ekip (yönetici) onaylarsa
/// herkese açılır, reddederse gerekçesi önerene gösterilir.
///
/// - **Cihaz modu:** öneriler cihazdaki bütün hesapların ortak listesinde
///   ([communityKey]) tutulur; demo hesabı yönetici yetkisine sahiptir.
/// - **Sunucu modu** ([api] verilirse): katalog, öneriler ve onay kuyruğu
///   API'den gelir.
///
/// Puan ve yorum sayısı uydurulmaz: cihaz modunda topluluk yorumlarından
/// ([demoReviews]) ve kullanıcının kendi yorumundan, sunucu modunda
/// sunucudaki gerçek yorumlardan hesaplanır.
class CatalogController extends UserStore {
  CatalogController(
    super.store,
    super.uid, {
    List<Product> catalog = demoCatalog,
    this.api,
    this.isAdmin = false,
    this.reviews,
  }) : _seed = catalog {
    _favorites = asStringList(readValue(StoreKeys.favorites)).toSet();
    _seen = asStringList(readValue(_seenKey)).toSet();
    if (api == null) {
      _migrateOldSubmissions();
      _community = _readCommunity();
      _catalog = _seed;
      reviews?.addListener(_notify);
    } else {
      _catalog = const [];
      reload();
    }
  }

  /// Cihazdaki bütün hesapların ortak topluluk listesi (cihaz modu).
  static const communityKey = 'community.products';
  static const _seenKey = 'decisionsSeen';

  final ApiClient? api;
  final bool isAdmin;
  final ReviewController? reviews;
  final List<Product> _seed;

  List<Product> _catalog = const [];
  List<Product> _community = [];
  List<Product> _remoteSubmissions = [];
  List<Product> _remoteQueue = [];
  Set<String> _favorites = {};
  Set<String> _seen = {};
  bool _loading = false;
  String? _error;
  bool _disposed = false;

  bool get isRemote => api != null;
  bool get isLoading => _loading;

  /// Son yükleme hatası (sunucu modu); null ise sorun yok.
  String? get loadError => _error;

  // ── Görünür ürünler ─────────────────────────────────────────

  /// Onaylı katalog + kullanıcının onay bekleyen ürünleri (yalnızca kendisi görür).
  List<Product> get products {
    final pending = submissions.where((p) => p.isPending);
    final approved = isRemote
        ? _catalog
        : [
            ..._community.where((p) => p.status == ProductStatus.approved),
            ..._catalog,
          ];
    final list = [
      ...pending,
      ...approved.where((p) => !pending.any((s) => s.id == p.id)),
    ];
    return isRemote ? list : [for (final p in list) _withRating(p)];
  }

  /// Kullanıcının önerileri; reddedilenler gerekçesiyle birlikte.
  List<Product> get submissions => isRemote
      ? List.unmodifiable(_remoteSubmissions)
      : [
          for (final p in _community)
            if (uid != null && p.submittedBy == uid) p,
        ];

  /// Yöneticinin onay kuyruğu (en eski önce).
  List<Product> get reviewQueue {
    if (!isAdmin) return const [];
    if (isRemote) return List.unmodifiable(_remoteQueue);
    return _community.where((p) => p.isPending).toList()
      ..sort((a, b) => (a.createdAt ?? '').compareTo(b.createdAt ?? ''));
  }

  Product? byId(String? id) {
    if (id == null) return null;
    for (final p in [...products, ...submissions, ...reviewQueue]) {
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
          searchKey(p.brand).contains(q) ||
          (p.barcode != null && p.barcode == query.trim());
      final matchesCategory = category == 'Tümü' || p.category == category;
      return matchesQuery && matchesCategory;
    }).toList();
  }

  // ── Puan (cihaz modu) ───────────────────────────────────────

  /// Bu ürüne yazılmış topluluk yorumları (cihaz modu).
  List<CommunityReview> communityReviews(String productId) => [
    for (final r in demoReviews)
      if (r.productId == productId) r,
  ];

  Product _withRating(Product p) {
    final ratings = [
      for (final r in communityReviews(p.id)) r.rating,
      if (reviews?.forProduct(p.id) case final mine?) mine.rating,
    ];
    if (ratings.isEmpty) return p.copyWith(rating: 0, reviewCount: 0);
    final avg = ratings.reduce((a, b) => a + b) / ratings.length;
    return p.copyWith(
      rating: (avg * 10).round() / 10,
      reviewCount: ratings.length,
    );
  }

  // ── Sunucudan yükleme ───────────────────────────────────────

  /// Sunucudan katalog, öneri durumları ve (yöneticiyse) onay kuyruğunu çeker.
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
      if (uid != null) {
        _remoteSubmissions = [
          for (final p in await client.get('/products/mine') as List)
            Product.fromJson(asMap(p)),
        ];
      }
      if (isAdmin) {
        _remoteQueue = [
          for (final p in await client.get('/admin/submissions') as List)
            Product.fromJson(asMap(p)),
        ];
      }
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
    reviews?.removeListener(_notify);
    super.dispose();
  }

  // ── Favoriler ───────────────────────────────────────────────

  bool isFavorite(String productId) => _favorites.contains(productId);

  void toggleFavorite(String productId) {
    _favorites = {..._favorites};
    _favorites.contains(productId)
        ? _favorites.remove(productId)
        : _favorites.add(productId);
    writeValue(StoreKeys.favorites, _favorites.toList());
    notifyListeners();
  }

  // ── Öneri ───────────────────────────────────────────────────

  /// Aynı ad ve markada (ya da aynı barkodla) ürün var mı? Büyük/küçük harf ve
  /// Türkçe karakter duyarsız. Reddedilenler sayılmaz. Sunucu da aynı kontrolü
  /// yapar; bu yalnızca kullanıcıyı erken uyarır.
  Product? findDuplicate(String name, String brand, {String? barcode}) {
    final n = searchKey(name);
    final b = searchKey(brand);
    final code = barcode?.trim() ?? '';
    final pool = [...products, if (!isRemote) ..._community];
    for (final p in pool) {
      if (p.isRejected) continue;
      if (searchKey(p.name) == n && searchKey(p.brand) == b) return p;
      if (code.isNotEmpty && p.barcode == code) return p;
    }
    return null;
  }

  /// Ürünü ekip onayına gönderir. [replacing] reddedilmiş bir önerinin
  /// düzeltilmiş hâliyse eskisi listeden kalkar. Sunucu modunda hata olursa
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
    String? submitterName,
    String? replacing,
  }) async {
    final client = api;
    final cleanBarcode = barcode == null || barcode.isEmpty ? null : barcode;
    if (client != null) {
      final product = Product.fromJson(
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
      _remoteSubmissions = [
        product,
        ..._remoteSubmissions.where((p) => p.id != replacing),
      ];
      _notify();
      return product;
    }
    final product = Product(
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
      submittedBy: uid,
      addedBy: submitterName,
      createdAt: DateTime.now().toIso8601String(),
    );
    _community = [
      product,
      ..._community.where((p) => !(p.id == replacing && p.isRejected)),
    ];
    _saveCommunity();
    return product;
  }

  // ── Ekip onayı ──────────────────────────────────────────────

  /// Öneriyi onaylar; ürün herkese açılır.
  Future<void> approve(String productId) => _decide(productId, approve: true);

  /// Öneriyi gerekçeyle reddeder; gerekçe yalnızca önerene görünür.
  Future<void> reject(String productId, String reason) =>
      _decide(productId, approve: false, reason: reason);

  Future<void> _decide(
    String productId, {
    required bool approve,
    String? reason,
  }) async {
    if (!isAdmin) throw StateError('Yalnızca yönetici karar verebilir.');
    final client = api;
    if (client != null) {
      final id = Uri.encodeComponent(productId);
      await client.post(
        '/admin/submissions/$id/${approve ? 'approve' : 'reject'}',
        approve ? null : {'reason': reason},
      );
      await reload();
      return;
    }
    _community = [
      for (final p in _community)
        if (p.id == productId && p.isPending)
          approve
              ? p.copyWith(
                  status: ProductStatus.approved,
                  approvedAt: dateKey(DateTime.now()),
                  clearRejectReason: true,
                )
              : p.copyWith(status: ProductStatus.rejected, rejectReason: reason)
        else
          p,
    ];
    _saveCommunity();
  }

  // ── Karar bildirimleri ──────────────────────────────────────

  /// Kullanıcının henüz görmediği onay/ret kararları.
  List<Product> get unseenDecisions => [
    for (final p in submissions)
      if (!p.isPending && !_seen.contains(_decisionKey(p))) p,
  ];

  void markDecisionSeen(String productId) {
    final p = submissions.where((s) => s.id == productId).firstOrNull;
    if (p == null || p.isPending) return;
    _seen = {..._seen, _decisionKey(p)};
    writeValue(_seenKey, _seen.toList());
    _notify();
  }

  static String _decisionKey(Product p) => '${p.id}:${p.status.name}';

  // ── Cihaz modu kayıtları ────────────────────────────────────

  List<Product> _readCommunity() {
    final raw = store.read(communityKey);
    return raw is List
        ? [
            for (final p in raw) Product.fromJson(asMap(p)),
          ].where((p) => p.id.isNotEmpty).toList()
        : [];
  }

  void _saveCommunity() {
    store.write(communityKey, [for (final p in _community) p.toJson()]);
    _notify();
  }

  /// Eski sürüm önerileri kullanıcıya özel anahtarda tutuyordu; ortak
  /// listeye taşınır ki ekip onaylayabilsin.
  void _migrateOldSubmissions() {
    final old = readList(StoreKeys.submissions);
    if (old.isEmpty || uid == null) return;
    final community = _readCommunity();
    final known = {for (final p in community) p.id};
    final moved = [
      for (final j in old)
        if (!known.contains(j['id']))
          Product.fromJson({...j, 'submittedBy': uid}),
    ];
    store.write(communityKey, [
      for (final p in [...moved, ...community]) p.toJson(),
    ]);
    writeValue(StoreKeys.submissions, null);
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
