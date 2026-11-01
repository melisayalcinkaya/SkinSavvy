import '../core/utils/date_utils.dart';
import '../core/utils/ids.dart';
import '../data/local/keys.dart';
import '../data/models/product.dart';
import '../data/models/shelf_item.dart';
import 'user_store.dart';

/// Ürün dolabı: kullandıklarım, alınacaklar ve bitirdiklerim.
class ShelfController extends UserStore {
  ShelfController(super.store, super.uid) {
    _items = readList(
      StoreKeys.shelf,
    ).map(ShelfItem.fromJson).where((e) => e.id.isNotEmpty).toList();
  }

  List<ShelfItem> _items = [];

  List<ShelfItem> get all => List.unmodifiable(_items);

  List<ShelfItem> get owned =>
      _items.where((e) => e.status != ShelfStatus.wishlist).toList();

  List<ShelfItem> get using => _byStatus(ShelfStatus.using);

  List<ShelfItem> get wishlist => _byStatus(ShelfStatus.wishlist);

  List<ShelfItem> get finished => _byStatus(ShelfStatus.finished)
    ..sort(
      (a, b) =>
          (b.finishedOn ?? DateTime(0)).compareTo(a.finishedOn ?? DateTime(0)),
    );

  int get runningLowCount => using.where((e) => e.isRunningLow).length;

  int get favoriteCount => _items
      .where((e) => e.isFavorite && e.status != ShelfStatus.finished)
      .length;

  List<ShelfItem> _byStatus(ShelfStatus s) =>
      _items.where((e) => e.status == s).toList();

  ShelfItem? byId(String id) {
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  /// Katalog ürünü dolapta (bitmemiş olarak) var mı?
  ShelfItem? activeForProduct(String productId) {
    for (final item in _items) {
      if (item.productId == productId && item.status != ShelfStatus.finished) {
        return item;
      }
    }
    return null;
  }

  ShelfItem addProduct(
    Product product, {
    ShelfStatus status = ShelfStatus.using,
    DateTime? openedOn,
    DateTime? expiresOn,
    int? paoMonths,
    String amount = '',
    String usage = '',
  }) => add(
    ShelfItem(
      id: newId('s'),
      productId: product.id,
      name: product.name,
      brand: product.brand,
      category: product.category,
      imageUrl: product.imageUrl,
      ingredients: product.ingredients,
      price: product.price,
      status: status,
      openedOn: openedOn,
      expiresOn: expiresOn,
      paoMonths: paoMonths,
      amount: amount,
      usage: usage,
      addedOn: dateOnly(DateTime.now()),
    ),
  );

  ShelfItem add(ShelfItem item) {
    _items = [item, ..._items];
    _save();
    return item;
  }

  void update(ShelfItem item) {
    _items = [for (final e in _items) e.id == item.id ? item : e];
    _save();
  }

  void remove(String id) {
    _items = _items.where((e) => e.id != id).toList();
    _save();
  }

  void toggleFavorite(String id) {
    final item = byId(id);
    if (item != null) update(item.copyWith(isFavorite: !item.isFavorite));
  }

  void finish(
    String id, {
    required bool wouldRebuy,
    int rating = 0,
    String note = '',
  }) {
    final item = byId(id);
    if (item == null) return;
    update(
      item.copyWith(
        status: ShelfStatus.finished,
        remaining: 0,
        wouldRebuy: wouldRebuy,
        rating: rating > 0 ? rating : null,
        note: note.isEmpty ? null : note,
        finishedOn: dateOnly(DateTime.now()),
      ),
    );
  }

  /// Alınacaklar listesindeki ürünü kullanmaya başlar ya da bitmiş bir
  /// ürünün yenisini dolaba ekler ("Tekrar Kullan").
  ShelfItem startUsing(
    String id, {
    DateTime? openedOn,
    DateTime? expiresOn,
    int? paoMonths,
    String amount = '',
    String usage = '',
  }) {
    final item = byId(id)!;
    if (item.status == ShelfStatus.wishlist) {
      final updated = item.copyWith(
        status: ShelfStatus.using,
        remaining: 100,
        openedOn: openedOn,
        expiresOn: expiresOn,
        paoMonths: paoMonths,
        amount: amount,
        usage: usage,
      );
      update(updated);
      return updated;
    }
    return add(
      ShelfItem(
        id: newId('s'),
        productId: item.productId,
        name: item.name,
        brand: item.brand,
        category: item.category,
        imageUrl: item.imageUrl,
        ingredients: item.ingredients,
        price: item.price,
        openedOn: openedOn,
        expiresOn: expiresOn,
        paoMonths: paoMonths,
        amount: amount,
        usage: usage,
        addedOn: dateOnly(DateTime.now()),
      ),
    );
  }

  void _save() {
    writeValue(StoreKeys.shelf, _items.map((e) => e.toJson()).toList());
    notifyListeners();
  }
}
