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
/// "onay bekliyor" olur ve yalnızca öneren görür → ekip (yönetici):
///
/// - **onaylar** (eksik/hatalı bilgiyi gerekirse kendisi düzeltip): ürün
///   herkese açılır;
/// - **yinelenen** olarak işaretler: öneri katalogdaki asıl ürüne bağlanır,
///   önerenin dolabındaki kayıt da asıl ürüne taşınır;
/// - **siler** (spam/sahte): öneri katalogdan ve önerenin dolabından kalkar.
///
/// Reddetme yoktur; her kararda önerene bildirim gider.
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
  List<Product> _remoteDelisted = [];

  /// Sunucu modunda listede olmayan ama doğrudan açılan ürünler (ör. dolapta
  /// duran, katalogdan kaldırılmış ürün).
  final Map<String, Product> _extra = {};
  final Set<String> _fetching = {};
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
    // Cihaz modunda ekibin düzelttiği ya da kaldırdığı hazır katalog ürünleri
    // ortak listede aynı kimlikle tutulur ve hazır kaydın yerine geçer.
    final overridden = {for (final p in _community) p.id};
    final approved = isRemote
        ? _catalog
        : [
            ..._community.where((p) => p.isApproved),
            ..._catalog.where((p) => !overridden.contains(p.id)),
          ];
    final list = [
      ...pending,
      ...approved.where((p) => !pending.any((s) => s.id == p.id)),
    ];
    return isRemote ? list : [for (final p in list) _withRating(p)];
  }

  /// Kullanıcının bütün önerileri (bekleyen, onaylanan, yinelenen, silinen).
  List<Product> get submissions => isRemote
      ? List.unmodifiable(_remoteSubmissions)
      : [
          for (final p in _community)
            if (uid != null && p.submittedBy == uid) p,
        ];

  /// Kullanıcının kataloğa kazandırdığı ürün sayısı (onaylı, bekleyen ve
  /// sonradan katalogdan kaldırılan; yinelenen ve silinen öneriler sayılmaz).
  int get contributionCount =>
      submissions.where((p) => p.isLive || p.isDelisted).length;

  /// Yöneticinin onay kuyruğu (en eski önce).
  List<Product> get reviewQueue {
    if (!isAdmin) return const [];
    if (isRemote) return List.unmodifiable(_remoteQueue);
    return _community.where((p) => p.isPending).toList()
      ..sort((a, b) => (a.createdAt ?? '').compareTo(b.createdAt ?? ''));
  }

  /// Katalogdan kaldırılan ürünler (ekibin geri alabilmesi için).
  List<Product> get delisted {
    if (!isAdmin) return const [];
    if (isRemote) return List.unmodifiable(_remoteDelisted);
    return _community.where((p) => p.isDelisted).toList()
      ..sort((a, b) => searchKey(a.name).compareTo(searchKey(b.name)));
  }

  /// Ürünü kimliğiyle bulur; katalogdan kaldırılmış ürünler de bulunur
  /// (dolabında olan açabilsin).
  Product? byId(String? id) {
    if (id == null) return null;
    for (final p in [...products, ...submissions, ...reviewQueue]) {
      if (p.id == id) return p;
    }
    if (isRemote) {
      for (final p in _remoteDelisted) {
        if (p.id == id) return p;
      }
      return _extra[id];
    }
    for (final p in _community) {
      if (p.id == id && p.isDelisted) return _withRating(p);
    }
    return null;
  }

  /// Sunucu modunda listede olmayan ürünü (ör. katalogdan kaldırılmış)
  /// sunucudan bir kez getirir; bulunamazsa false.
  Future<bool> ensureLoaded(String id) async {
    final client = api;
    if (client == null || byId(id) != null) return byId(id) != null;
    if (!_fetching.add(id)) return false;
    try {
      final p = Product.fromJson(
        asMap(await client.get('/products/${Uri.encodeComponent(id)}')),
      );
      _extra[id] = p;
      _notify();
      return true;
    } on ApiException {
      return false;
    }
  }

  /// Bu ürün için bir kez denendi mi (sunucu modu)?
  bool fetchTried(String id) => _fetching.contains(id);

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

  /// Katalog, öneri durumları ve (yöneticiyse) onay kuyruğunu yeniden yükler.
  /// Cihaz modunda ortak topluluk listesi yeniden okunur (aynı cihazdaki başka
  /// bir hesabın verdiği kararlar görünsün).
  Future<void> reload() async {
    final client = api;
    if (client == null) {
      _community = _readCommunity();
      _notify();
      return;
    }
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
        _remoteDelisted = [
          for (final p in await client.get('/admin/products') as List)
            Product.fromJson(asMap(p)),
        ];
      }
      _extra.clear();
      _fetching.clear();
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
  /// Türkçe karakter duyarsız. Yalnızca onaylı ve bekleyen ürünler sayılır;
  /// [ignoreId] (düzenlenen ürünün kendisi) atlanır. Sunucu da aynı kontrolü
  /// yapar; bu yalnızca kullanıcıyı erken uyarır.
  Product? findDuplicate(
    String name,
    String brand, {
    String? barcode,
    String? ignoreId,
  }) {
    final n = searchKey(name);
    final b = searchKey(brand);
    final code = barcode?.trim() ?? '';
    final pool = [
      ...products,
      if (!isRemote) ..._community,
      if (isRemote) ..._remoteQueue,
    ];
    for (final p in pool) {
      if (!p.isLive || p.id == ignoreId) continue;
      if (searchKey(p.name) == n && searchKey(p.brand) == b) return p;
      if (code.isNotEmpty && p.barcode == code) return p;
    }
    return null;
  }

  /// Ürünü ekip onayına gönderir. Fotoğraf zorunludur ([imageUrl], data URL).
  /// Sunucu modunda hata olursa [ApiException] fırlatır (ör. 409: ürün zaten
  /// var).
  Future<Product> submit({
    required String name,
    required String brand,
    required String category,
    required List<String> skinTypes,
    required List<String> ingredients,
    String description = '',
    String? barcode,
    required String imageUrl,
    String? submitterName,
  }) async {
    if (imageUrl.isEmpty) throw ArgumentError('Ürün fotoğrafı zorunlu.');
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
      _remoteSubmissions = [product, ..._remoteSubmissions];
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
    _community = [product, ..._community];
    _saveCommunity();
    return product;
  }

  // ── Ekip kararları ──────────────────────────────────────────

  /// Öneriyi onaylar; ürün herkese açılır. [edited] verilirse ekip ürünün
  /// bilgilerini (ad, marka, kategori, cilt tipi, içerik, açıklama, barkod,
  /// fotoğraf) düzeltmiştir; öneren "ekip düzenledi" notuyla bilgilendirilir.
  Future<void> approve(String productId, {Product? edited}) async {
    final pending = _requirePending(productId);
    final client = api;
    if (client != null) {
      await client.post(
        '/admin/submissions/${Uri.encodeComponent(productId)}/approve',
        edited == null ? null : _editBody(edited),
      );
      await reload();
      return;
    }
    if (edited != null) {
      final dup = findDuplicate(
        edited.name,
        edited.brand,
        barcode: edited.barcode,
        ignoreId: productId,
      );
      if (dup != null) {
        throw StateError('"${dup.brand} ${dup.name}" zaten katalogda.');
      }
    }
    final base = edited == null
        ? pending
        : pending.copyWith(
            name: sanitizeInput(edited.name),
            brand: sanitizeInput(edited.brand),
            category: edited.category,
            skinTypes: edited.skinTypes,
            ingredients: edited.ingredients,
            description: sanitizeInput(edited.description),
            barcode: edited.barcode,
            clearBarcode: edited.barcode == null,
            imageUrl: edited.imageUrl,
            editedByTeam: true,
          );
    _replace(
      base.copyWith(
        status: ProductStatus.approved,
        approvedAt: dateKey(DateTime.now()),
      ),
    );
  }

  /// Öneri katalogdaki [originalId] ürünüyle aynı: öneri yinelenen olarak
  /// işaretlenir, önerenin dolabındaki kayıt asıl ürüne bağlanır.
  Future<void> markDuplicate(String productId, String originalId) async {
    final pending = _requirePending(productId);
    final original = byId(originalId);
    if (originalId == productId || original == null || !original.isApproved) {
      throw StateError('Asıl ürün onaylı bir katalog ürünü olmalı.');
    }
    final client = api;
    if (client != null) {
      await client.post(
        '/admin/submissions/${Uri.encodeComponent(productId)}/duplicate',
        {'originalId': originalId},
      );
      await reload();
      return;
    }
    _replace(
      pending.copyWith(
        status: ProductStatus.duplicate,
        duplicateOf: originalId,
      ),
    );
  }

  /// Spam/sahte öneriyi siler: katalogda hiç görünmez, önerenin dolabından
  /// da kalkar.
  Future<void> remove(String productId) async {
    final pending = _requirePending(productId);
    final client = api;
    if (client != null) {
      await client.post(
        '/admin/submissions/${Uri.encodeComponent(productId)}/remove',
        null,
      );
      await reload();
      return;
    }
    // Fotoğraf ve içerik gibi kullanıcı verisi saklanmaz; bildirim için
    // yalnızca ad, marka ve öneren kalır.
    _replace(
      Product(
        id: pending.id,
        name: pending.name,
        brand: pending.brand,
        category: pending.category,
        status: ProductStatus.removed,
        submittedBy: pending.submittedBy,
        createdAt: pending.createdAt,
      ),
    );
  }

  Product _requirePending(String productId) {
    if (!isAdmin) throw StateError('Yalnızca yönetici karar verebilir.');
    final p = reviewQueue.where((p) => p.id == productId).firstOrNull;
    if (p == null) throw StateError('Bu öneri artık onay beklemiyor.');
    return p;
  }

  void _replace(Product updated) {
    _community = [for (final p in _community) p.id == updated.id ? updated : p];
    _saveCommunity();
  }

  static Map<String, Object?> _editBody(Product e) => {
    'name': sanitizeInput(e.name),
    'brand': sanitizeInput(e.brand),
    'category': e.category,
    'skinTypes': e.skinTypes,
    'ingredients': e.ingredients,
    'description': sanitizeInput(e.description),
    'barcode': e.barcode,
    'imageUrl': e.imageUrl,
  };

  // ── Katalogdaki ürünler (ekip) ──────────────────────────────

  /// Onaylı ya da kaldırılmış ürünün bilgilerini düzeltir.
  Future<void> editProduct(String productId, Product edited) async {
    final current = _requireCatalogProduct(productId);
    final client = api;
    if (client != null) {
      await client.put(
        '/admin/products/${Uri.encodeComponent(productId)}',
        _editBody(edited),
      );
      await reload();
      return;
    }
    final dup = findDuplicate(
      edited.name,
      edited.brand,
      barcode: edited.barcode,
      ignoreId: productId,
    );
    if (dup != null) {
      throw StateError('"${dup.brand} ${dup.name}" zaten katalogda.');
    }
    _upsertCommunity(
      current.copyWith(
        name: sanitizeInput(edited.name),
        brand: sanitizeInput(edited.brand),
        category: edited.category,
        skinTypes: edited.skinTypes,
        ingredients: edited.ingredients,
        description: sanitizeInput(edited.description),
        barcode: edited.barcode,
        clearBarcode: edited.barcode == null,
        imageUrl: edited.imageUrl,
      ),
    );
  }

  /// Ürünü katalogdan kaldırır: aramada görünmez, yeni kullanıcı dolabına
  /// ekleyemez. Daha önce ekleyenlerin kaydı ve yorumu durur.
  Future<void> delist(String productId) async {
    final current = _requireCatalogProduct(productId);
    if (!current.isApproved) throw StateError('Ürün zaten kaldırılmış.');
    final client = api;
    if (client != null) {
      await client.post(
        '/admin/products/${Uri.encodeComponent(productId)}/delist',
        null,
      );
      await reload();
      return;
    }
    _upsertCommunity(current.copyWith(status: ProductStatus.delisted));
  }

  /// Kaldırılan ürünü kataloğa geri alır.
  Future<void> relist(String productId) async {
    final current = _requireCatalogProduct(productId);
    if (!current.isDelisted) throw StateError('Ürün zaten katalogda.');
    final client = api;
    if (client != null) {
      await client.post(
        '/admin/products/${Uri.encodeComponent(productId)}/relist',
        null,
      );
      await reload();
      return;
    }
    // Kaldırılmışken aynı ürün yeniden eklendiyse ikisi birden olmasın.
    final dup = findDuplicate(
      current.name,
      current.brand,
      barcode: current.barcode,
      ignoreId: productId,
    );
    if (dup != null) {
      throw StateError('Katalogda aynı ürün var; geri alınamaz.');
    }
    _upsertCommunity(current.copyWith(status: ProductStatus.approved));
  }

  Product _requireCatalogProduct(String productId) {
    if (!isAdmin) throw StateError('Yalnızca ekip yapabilir.');
    final p = byId(productId);
    if (p == null || !(p.isApproved || p.isDelisted)) {
      throw StateError('Ürün katalogda bulunamadı.');
    }
    return p;
  }

  /// Ortak listede kaydı günceller; hazır katalog ürünüyse kopyasını ekler.
  void _upsertCommunity(Product updated) {
    final exists = _community.any((p) => p.id == updated.id);
    _community = exists
        ? [for (final p in _community) p.id == updated.id ? updated : p]
        : [updated, ..._community];
    _saveCommunity();
  }

  // ── Öneriyi geri çekme ──────────────────────────────────────

  /// Kullanıcı, ekip karar vermeden önce kendi önerisini geri çeker; öneri
  /// tamamen silinir.
  Future<void> withdraw(String productId) async {
    final p = submissions.where((s) => s.id == productId).firstOrNull;
    if (p == null) throw StateError('Öneri bulunamadı.');
    if (!p.isPending) {
      throw StateError('Ekip bu öneriye karar verdi; geri çekilemez.');
    }
    final client = api;
    if (client != null) {
      await client.delete('/products/${Uri.encodeComponent(productId)}');
      _remoteSubmissions = [
        for (final s in _remoteSubmissions)
          if (s.id != productId) s,
      ];
      _notify();
      return;
    }
    _community = [
      for (final s in _community)
        if (s.id != productId) s,
    ];
    _saveCommunity();
  }

  // ── Karar bildirimleri ──────────────────────────────────────

  /// Kullanıcının henüz görmediği ekip kararları.
  List<Product> get unseenDecisions => [
    for (final p in submissions)
      // Katalogdan kaldırma öneri kararı değildir; önerene bildirilmez.
      if (!p.isPending && !p.isDelisted && !_seen.contains(_decisionKey(p))) p,
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
