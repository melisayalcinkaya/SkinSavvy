import '../core/utils/ids.dart';
import '../core/utils/text_utils.dart';
import '../data/local/keys.dart';
import '../data/models/review.dart';
import '../data/models/shelf_item.dart';
import 'user_store.dart';

class ReviewController extends UserStore {
  ReviewController(super.store, super.uid) {
    _reviews = readList(
      StoreKeys.reviews,
    ).map(Review.fromJson).where((e) => e.id.isNotEmpty).toList();
  }

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
      _save();
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
    _save();
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
    _save();
  }

  void delete(String id) {
    _reviews = _reviews.where((r) => r.id != id).toList();
    _save();
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

  void _save() {
    writeValue(StoreKeys.reviews, _reviews.map((e) => e.toJson()).toList());
    notifyListeners();
  }
}
