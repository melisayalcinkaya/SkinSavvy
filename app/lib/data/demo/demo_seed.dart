import '../../core/utils/date_utils.dart';
import '../local/keys.dart';
import '../local/local_store.dart';
import '../models/product.dart';
import '../models/review.dart';
import '../models/routine.dart';
import '../models/shelf_item.dart';
import '../models/user.dart';
import 'demo_catalog.dart';

/// "Demo hesabıyla dene" için örnek veri. Tarihler bugüne göre üretilir;
/// böylece demo her açıldığında güncel görünür ve hatırlatmalar tetiklenir.
abstract final class DemoSeed {
  static const email = 'demo@skinsavvy.app';

  static const user = AppUser(
    id: 'demo',
    name: 'Ece Demir',
    email: email,
    bio: 'Karma cilt, leke ve sivilce odaklı rutin.',
    onboarded: true,
    isDemo: true,
    skinProfile: SkinProfile(
      skinType: 'Karma Cilt',
      concerns: {'Sivilce / Akne', 'Leke / Renk Eşitsizliği'},
      allergens: {'Parfüm / Fragrance'},
      intensity: 'Orta (4-6 adım)',
    ),
  );

  static Product _p(String id) => demoCatalog.firstWhere((p) => p.id == id);

  static ShelfItem _fromProduct(
    String id,
    String productId, {
    ShelfStatus status = ShelfStatus.using,
    DateTime? openedOn,
    int? paoMonths,
    DateTime? expiresOn,
    int remaining = 100,
    String amount = '',
    String usage = '',
    int rating = 0,
    String note = '',
    bool isFavorite = false,
    bool? wouldRebuy,
    DateTime? finishedOn,
    DateTime? addedOn,
  }) {
    final p = _p(productId);
    return ShelfItem(
      id: id,
      productId: p.id,
      name: p.name,
      brand: p.brand,
      category: p.category,
      imageUrl: p.imageUrl,
      ingredients: p.ingredients,
      price: p.price,
      status: status,
      openedOn: openedOn,
      paoMonths: paoMonths,
      expiresOn: expiresOn,
      remaining: remaining,
      amount: amount,
      usage: usage,
      rating: rating,
      note: note,
      isFavorite: isFavorite,
      wouldRebuy: wouldRebuy,
      finishedOn: finishedOn,
      addedOn: addedOn,
    );
  }

  static List<ShelfItem> shelf(DateTime now) {
    final today = dateOnly(now);
    DateTime ago(int days) => today.subtract(Duration(days: days));
    DateTime later(int days) => today.add(Duration(days: days));
    return [
      _fromProduct(
        's-temizleyici',
        'p-temizleyici-lumen',
        openedOn: ago(70),
        paoMonths: 12,
        expiresOn: later(520),
        remaining: 75,
        amount: '236 ml',
        usage: 'Sabah & Akşam',
        rating: 5,
        note: 'Cildi kurutmuyor, çok seviyorum!',
        isFavorite: true,
        addedOn: ago(72),
      ),
      _fromProduct(
        's-c-serum',
        'p-serum-c-aurora',
        openedOn: ago(166),
        paoMonths: 6,
        expiresOn: later(300),
        remaining: 40,
        amount: '30 ml',
        usage: 'Sabah',
        rating: 4,
        note: 'Lekeler için harika!',
        isFavorite: true,
        addedOn: ago(168),
      ),
      _fromProduct(
        's-retinol',
        'p-serum-retinol-aurora',
        openedOn: ago(120),
        paoMonths: 6,
        expiresOn: later(240),
        remaining: 15,
        amount: '30 ml',
        usage: 'Akşam',
        rating: 4,
        note: 'Bitmek üzere, yenisini almayı unutma!',
        addedOn: ago(121),
      ),
      _fromProduct(
        's-spf',
        'p-gunes-mineral-solara',
        openedOn: ago(30),
        paoMonths: 12,
        expiresOn: later(400),
        remaining: 60,
        amount: '50 ml',
        usage: 'Sabah',
        rating: 4,
        addedOn: ago(31),
      ),
      _fromProduct(
        's-bha',
        'p-tonik-bha-clarity',
        openedOn: ago(45),
        paoMonths: 12,
        expiresOn: later(600),
        remaining: 55,
        amount: '118 ml',
        usage: 'Akşam',
        rating: 5,
        addedOn: ago(46),
      ),
      _fromProduct(
        's-niacinamide',
        'p-serum-niacinamide-clarity',
        status: ShelfStatus.wishlist,
        addedOn: ago(12),
      ),
      _fromProduct(
        's-maske',
        'p-maske-kil-terra',
        status: ShelfStatus.wishlist,
        addedOn: ago(5),
      ),
      _fromProduct(
        's-hyaluronik',
        'p-serum-hyaluronik-aurora',
        status: ShelfStatus.finished,
        remaining: 0,
        rating: 5,
        wouldRebuy: true,
        note: 'Tekrar alırım, nem etkisi harikaydı.',
        finishedOn: ago(20),
        addedOn: ago(140),
      ),
      _fromProduct(
        's-temizleme-yagi',
        'p-temizleyici-yag-terra',
        status: ShelfStatus.finished,
        remaining: 0,
        rating: 2,
        wouldRebuy: false,
        note: 'Tekrar almam, parfümü cildimi tahriş etti.',
        finishedOn: ago(60),
        addedOn: ago(150),
      ),
    ];
  }

  static List<RoutineEntry> routine() => const [
    RoutineEntry(
      id: 'r-m1',
      shelfItemId: 's-temizleyici',
      slot: RoutineSlot.morning,
      order: 0,
    ),
    RoutineEntry(
      id: 'r-m2',
      shelfItemId: 's-c-serum',
      slot: RoutineSlot.morning,
      order: 1,
    ),
    RoutineEntry(
      id: 'r-m3',
      shelfItemId: 's-spf',
      slot: RoutineSlot.morning,
      order: 2,
    ),
    RoutineEntry(
      id: 'r-e1',
      shelfItemId: 's-temizleyici',
      slot: RoutineSlot.evening,
      order: 0,
    ),
    RoutineEntry(
      id: 'r-e2',
      shelfItemId: 's-bha',
      slot: RoutineSlot.evening,
      weekdays: {1, 3, 5},
      order: 1,
    ),
    RoutineEntry(
      id: 'r-e3',
      shelfItemId: 's-retinol',
      slot: RoutineSlot.evening,
      order: 2,
    ),
  ];

  /// Son 30 günün tamamlama kaydı: 8 ve 19 gün önce birer eksik;
  /// bugün sabah rutininin ilk iki adımı yapılmış.
  static Map<String, List<String>> completions(DateTime now) {
    final today = dateOnly(now);
    final result = <String, List<String>>{};
    for (var i = 1; i <= 30; i++) {
      final day = today.subtract(Duration(days: i));
      final ids = routine()
          .where((e) => e.appliesOn(day))
          .map((e) => e.id)
          .toList();
      if (i == 8 || i == 19) ids.remove('r-e3');
      result[dateKey(day)] = ids;
    }
    result[dateKey(today)] = ['r-m1', 'r-m2'];
    return result;
  }

  static List<Review> reviews(DateTime now) {
    final today = dateOnly(now);
    Review r(
      String id,
      String shelfId,
      String productId,
      int rating,
      String comment,
      int daysAgo,
    ) {
      final p = _p(productId);
      return Review(
        id: id,
        shelfItemId: shelfId,
        productId: productId,
        productName: p.name,
        brand: p.brand,
        imageUrl: p.imageUrl,
        rating: rating,
        comment: comment,
        createdAt: today.subtract(Duration(days: daysAgo)),
      );
    }

    return [
      r(
        'rv-1',
        's-temizleyici',
        'p-temizleyici-lumen',
        5,
        'Cildi kurutmuyor, sabah ve akşam kullanıyorum. Hassas cildime çok iyi geldi.',
        30,
      ),
      r(
        'rv-2',
        's-c-serum',
        'p-serum-c-aurora',
        4,
        'Lekeler için gerçekten işe yarıyor. Kokusu biraz belirgin ama alışılıyor.',
        60,
      ),
      r(
        'rv-3',
        's-hyaluronik',
        'p-serum-hyaluronik-aurora',
        5,
        'Nemlendirme etkisi çok iyi. Kesinlikle tekrar alacağım.',
        22,
      ),
    ];
  }

  static Future<void> writeData(
    LocalStore store,
    String uid,
    DateTime now,
  ) async {
    String key(String name) => StoreKeys.user(uid, name);
    await store.write(
      key(StoreKeys.shelf),
      shelf(now).map((e) => e.toJson()).toList(),
    );
    await store.write(
      key(StoreKeys.routine),
      routine().map((e) => e.toJson()).toList(),
    );
    await store.write(key(StoreKeys.completions), completions(now));
    await store.write(
      key(StoreKeys.reviews),
      reviews(now).map((e) => e.toJson()).toList(),
    );
    await store.write(key(StoreKeys.favorites), [
      'p-serum-c-aurora',
      'p-temizleyici-lumen',
    ]);
  }
}
