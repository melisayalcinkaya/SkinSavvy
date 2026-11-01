import '../core/utils/ids.dart';
import '../core/utils/text_utils.dart';
import '../data/local/keys.dart';
import '../data/models/json.dart';
import '../data/models/product.dart';
import '../data/models/review.dart';
import '../data/models/shelf_item.dart';
import '../data/remote/api_client.dart';
import 'user_store.dart';

/// Kullanıcının yorumları.
///
/// Yorum her zaman önce cihaza yazılır (çevrimdışı da çalışsın). Sunucu
/// modunda ([api] verilirse) katalog ürünlerine yazılan yorumlar ayrıca
/// sunucuya gönderilir; gönderilemeyenler kuyrukta kalır ve bir sonraki
/// açılışta ya da yorum işleminde yeniden denenir.
class ReviewController extends UserStore {
  ReviewController(super.store, super.uid, {this.api}) {
    _reviews = readList(
      StoreKeys.reviews,
    ).map(Review.fromJson).where((e) => e.id.isNotEmpty).toList();
    _unsynced = asStringList(readValue(_syncKey)).toSet();
    if (api != null && _unsynced.isNotEmpty) sync();
  }

  final ApiClient? api;
  static const _syncKey = 'reviewSync';

  /// Sunucuya gönderilmeyi bekleyen ürün kimlikleri.
  Set<String> _unsynced = {};
  Future<void>? _syncing;

  /// Her değişiklikte artan sayaç: gönderim sürerken aynı ürünün yorumu
  /// yeniden değişirse (ör. kaydet → hemen sil) eski yanıt kuyruğu temizlemez.
  final Map<String, int> _generation = {};

  Set<String> get pendingSync => Set.unmodifiable(_unsynced);

  static const minLength = 10;
  static const maxLength = 500;

  List<Review> _reviews = [];

  List<Review> get all =>
      [..._reviews]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  int get count => _reviews.length;

  Review? forShelfItem(String shelfItemId) {
    for (final r in _reviews) {
      if (r.shelfItemId == shelfItemId) return r;
    }
    return null;
  }

  Review? forProduct(String? productId) {
    if (productId == null) return null;
    for (final r in _reviews) {
      if (r.productId == productId) return r;
    }
    return null;
  }

  /// Aynı ürüne ikinci yorum yazılırsa yenisi oluşturulmaz, mevcut güncellenir.
  Review save(ShelfItem item, {required int rating, required String comment}) {
    final text = _validate(rating, comment);
    final existing = forShelfItem(item.id) ?? forProduct(item.productId);
    if (existing != null) {
      final updated = existing.copyWith(
        rating: rating,
        comment: text,
        updatedAt: DateTime.now(),
      );
      _reviews = [for (final r in _reviews) r.id == existing.id ? updated : r];
      _save(updated.productId);
      return updated;
    }
    final review = Review(
      id: newId('rv'),
      shelfItemId: item.id,
      productId: item.productId,
      productName: item.name,
      brand: item.brand,
      imageUrl: item.imageUrl,
      rating: rating,
      comment: text,
      createdAt: DateTime.now(),
    );
    _reviews = [..._reviews, review];
    _save(review.productId);
    return review;
  }

  void edit(String id, {required int rating, required String comment}) {
    final text = _validate(rating, comment);
    _reviews = [
      for (final r in _reviews)
        r.id == id
            ? r.copyWith(
                rating: rating,
                comment: text,
                updatedAt: DateTime.now(),
              )
            : r,
    ];
    _save(_byId(id)?.productId);
  }

  void delete(String id) {
    final productId = _byId(id)?.productId;
    _reviews = _reviews.where((r) => r.id != id).toList();
    _save(productId);
  }

  /// Ekip kararlarını yorumlara yansıtır: silinen önerinin yorumu kalkar,
  /// yinelenen önerinin yorumu asıl ürüne taşınır (asıl ürüne zaten yorum
  /// yazılmışsa o korunur). Tekrar çağrılması güvenlidir.
  void applyDecisions(Iterable<Product> submissions) {
    var reviews = _reviews;
    final moved = <String>{};
    for (final p in submissions) {
      if (!p.isRemoved && !(p.isDuplicate && p.duplicateOf != null)) continue;
      final mine = reviews.where((r) => r.productId == p.id).toList();
      if (mine.isEmpty) continue;
      reviews = reviews.where((r) => r.productId != p.id).toList();
      if (p.isRemoved) {
        _unsynced = {..._unsynced}..remove(p.id);
        continue;
      }
      final target = p.duplicateOf!;
      if (reviews.any((r) => r.productId == target)) continue;
      reviews = [...reviews, mine.first.copyWith(productId: target)];
      moved.add(target);
    }
    if (identical(reviews, _reviews)) return;
    _reviews = reviews;
    if (moved.isEmpty) {
      writeValue(_syncKey, _unsynced.toList());
      _save();
    } else {
      for (final id in moved) {
        _save(id);
      }
    }
  }

  Review? _byId(String id) {
    for (final r in _reviews) {
      if (r.id == id) return r;
    }
    return null;
  }

  String _validate(int rating, String comment) {
    if (rating < 1 || rating > 5) {
      throw ArgumentError('Puan 1-5 arasında olmalı.');
    }
    final text = sanitizeInput(comment);
    if (text.length < minLength) {
      throw ArgumentError('Yorum en az $minLength karakter olmalı.');
    }
    return text.length > maxLength ? text.substring(0, maxLength) : text;
  }

  void _save([String? changedProductId]) {
    writeValue(StoreKeys.reviews, _reviews.map((e) => e.toJson()).toList());
    if (api != null && changedProductId != null) {
      _unsynced = {..._unsynced, changedProductId};
      _generation[changedProductId] = (_generation[changedProductId] ?? 0) + 1;
      writeValue(_syncKey, _unsynced.toList());
      sync();
    }
    notifyListeners();
  }

  /// Bekleyen yorumları sunucuya gönderir. Aynı anda tek gönderim çalışır.
  Future<void> sync() => _syncing ??= _flush().whenComplete(() {
    _syncing = null;
  });

  Future<void> _flush() async {
    final client = api;
    if (client == null) return;
    var again = true;
    while (again) {
      again = false;
      for (final productId in _unsynced.toList()) {
        final generation = _generation[productId];
        final review = forProduct(productId);
        final path = '/products/${Uri.encodeComponent(productId)}/reviews/me';
        try {
          if (review == null) {
            await client.delete(path);
          } else {
            await client.put(path, {
              'rating': review.rating,
              'comment': review.comment,
            });
          }
        } on ApiException catch (e) {
          // Bağlantı ya da oturum sorunu: kuyrukta kalsın, sonra denenir.
          if (e.status == 0 || e.status == 401 || e.status >= 500) return;
          // 404/409/422: ürün sunucuda yok ya da onay bekliyor; yorum cihazda kalır.
        }
        if (_generation[productId] != generation) {
          again = true; // gönderim sırasında yeniden değişti
          continue;
        }
        _unsynced = {..._unsynced}..remove(productId);
        writeValue(_syncKey, _unsynced.toList());
      }
    }
  }
}
