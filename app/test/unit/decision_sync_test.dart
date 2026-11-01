import 'package:flutter_test/flutter_test.dart';
import 'package:skinsavvy_app/data/local/local_store.dart';
import 'package:skinsavvy_app/data/models/product.dart';
import 'package:skinsavvy_app/data/models/shelf_item.dart';
import 'package:skinsavvy_app/state/catalog_controller.dart';
import 'package:skinsavvy_app/state/decision_sync.dart';
import 'package:skinsavvy_app/state/review_controller.dart';
import 'package:skinsavvy_app/state/shelf_controller.dart';

import '../helpers.dart';

const png = 'data:image/png;base64,iVBORw0KGgo=';

/// Ekip kararlarının önerenin dolabına ve yorumlarına yansıması.
void main() {
  late LocalStore store;
  late CatalogController mine;
  late ShelfController shelf;
  late ReviewController reviews;
  late DecisionSync sync;
  late CatalogController team;

  setUp(() async {
    store = await emptyStore();
    shelf = ShelfController(store, 'u1');
    reviews = ReviewController(store, 'u1');
    mine = CatalogController(store, 'u1', reviews: reviews);
    sync = DecisionSync(mine, shelf, reviews);
    team = CatalogController(store, 'admin', isAdmin: true);
  });

  tearDown(() => sync.dispose());

  /// Öneri + dolap kaydı (tarih ve notla) + yorum.
  Future<(Product, ShelfItem)> proposeAndShelve() async {
    final p = await mine.submit(
      name: 'Lumen Temizleyici',
      brand: 'Lumen',
      category: 'Temizleyici',
      skinTypes: const ['Tüm Cilt Tipleri'],
      ingredients: const ['Aqua', 'Glycerin'],
      imageUrl: png,
    );
    final item = shelf.addProduct(
      p,
      openedOn: DateTime(2026, 3, 1),
      paoMonths: 12,
      usage: 'Sabah',
    );
    reviews.save(item, rating: 4, comment: 'Cildimi kurutmadı, sevdim.');
    // Ekip başka bir hesapta: ortak listeyi yeniden okuyup öneriyi görür.
    await team.reload();
    return (p, item);
  }

  /// Karar başka bir cihaz/hesapta verildi; öneren uygulamayı yenileyince
  /// katalog değişir ve senkron çalışır.
  Future<void> reopen() => mine.reload();

  test(
    'yinelenen: kayıt tarihleri, notu ve yorumuyla asıl ürüne bağlanır',
    () async {
      final (p, item) = await proposeAndShelve();
      await team.markDuplicate(p.id, 'p-temizleyici-lumen');
      await reopen();

      final moved = shelf.byId(item.id)!;
      expect(moved.productId, 'p-temizleyici-lumen');
      expect(moved.name, 'Nem Dengesi Temizleyici');
      expect(moved.openedOn, DateTime(2026, 3, 1));
      expect(moved.paoMonths, 12);
      expect(moved.usage, 'Sabah');
      expect(reviews.forProduct(p.id), isNull);
      expect(reviews.forProduct('p-temizleyici-lumen')?.rating, 4);
    },
  );

  test('yinelenen: asıl ürüne zaten yorum yazılmışsa o korunur', () async {
    final (p, _) = await proposeAndShelve();
    final original = shelf.addProduct(mine.byId('p-temizleyici-lumen')!);
    reviews.save(original, rating: 2, comment: 'Önceki yorumum buydu.');
    await team.markDuplicate(p.id, 'p-temizleyici-lumen');
    await reopen();

    expect(reviews.all, hasLength(1));
    expect(reviews.forProduct('p-temizleyici-lumen')?.rating, 2);
  });

  test('silinen: dolaptan ve yorumlardan kalkar', () async {
    final (p, _) = await proposeAndShelve();
    await team.remove(p.id);
    await reopen();

    expect(shelf.all, isEmpty);
    expect(reviews.all, isEmpty);
    // Bildirim yine de görünür.
    expect(mine.unseenDecisions.single.isRemoved, isTrue);
  });

  test(
    'ekip düzeltmesi dolaba bir kez yansır, kullanıcı düzenlemesi ezilmez',
    () async {
      final (p, item) = await proposeAndShelve();
      await team.approve(
        p.id,
        edited: p.copyWith(name: 'Lumen Jel Temizleyici'),
      );
      await reopen();
      expect(shelf.byId(item.id)!.name, 'Lumen Jel Temizleyici');
      expect(shelf.byId(item.id)!.productId, p.id);

      // Kullanıcı kendi kaydını yeniden adlandırır; senkron tekrar çalışsa da
      // ekip düzeltmesi üzerine yazılmaz.
      shelf.update(shelf.byId(item.id)!.copyWith(name: 'Benim temizleyicim'));
      await reopen();
      expect(shelf.byId(item.id)!.name, 'Benim temizleyicim');
      expect(
        ShelfController(store, 'u1').byId(item.id)!.name,
        'Benim temizleyicim',
      );
    },
  );

  test('düzeltilmeden onaylanan ve bekleyen öneriye dokunulmaz', () async {
    final (p, item) = await proposeAndShelve();
    var notified = 0;
    shelf.addListener(() => notified++);
    await reopen();
    await team.approve(p.id);
    await reopen();
    expect(shelf.byId(item.id)!.name, 'Lumen Temizleyici');
    expect(notified, 0);
  });

  test('bitirdiklerim memnuniyete göre süzülür', () async {
    final a = shelf.addProduct(mine.byId('p-temizleyici-lumen')!);
    final b = shelf.addProduct(mine.byId('p-nemlendirici-jel-clarity')!);
    shelf.addProduct(mine.byId('p-temizleyici-lumen')!);
    shelf.finish(a.id, wouldRebuy: true);
    shelf.finish(b.id, wouldRebuy: false);
    expect(shelf.finishedBy().length, 2);
    expect(shelf.finishedBy(satisfied: true).single.id, a.id);
    expect(shelf.finishedBy(satisfied: false).single.id, b.id);
  });
}
