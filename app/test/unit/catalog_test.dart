import 'package:flutter_test/flutter_test.dart';
import 'package:skinsavvy_app/data/demo/demo_catalog.dart';
import 'package:skinsavvy_app/data/models/product.dart';
import 'package:skinsavvy_app/state/catalog_controller.dart';

import '../helpers.dart';

void main() {
  test('arama ad ve markada Türkçe karakter duyarsız çalışır', () async {
    final catalog = CatalogController(await emptyStore(), 'u1');
    expect(
      catalog.search(query: 'gunes').map((p) => p.category),
      contains('Güneş Kremi'),
    );
    expect(
      catalog.search(query: 'LUMEN').every((p) => p.brand == 'Lumen Lab'),
      isTrue,
    );
    expect(
      catalog.search(category: 'Serum').every((p) => p.category == 'Serum'),
      isTrue,
    );
  });

  test('onaya gönderilen ürün beklemede ve kalıcı, tekrar eklenemez', () async {
    final store = await emptyStore();
    final catalog = CatalogController(store, 'u1');
    final p = await catalog.submit(
      name: 'Gül Suyu Tonik',
      brand: 'Deneme',
      category: 'Tonik',
      skinTypes: const ['Tüm Cilt Tipleri'],
      ingredients: const ['Rosa Damascena Flower Water', 'Glycerin'],
    );
    expect(p.status, ProductStatus.pending);

    final reloaded = CatalogController(store, 'u1');
    expect(reloaded.byId(p.id)?.isPending, isTrue);
    expect(reloaded.findDuplicate('GÜL SUYU tonik', 'deneme')?.id, p.id);
    // Başka kullanıcı bekleyen ürünü görmez.
    expect(CatalogController(store, 'u2').byId(p.id), isNull);
  });

  test('favoriler kullanıcıya özeldir', () async {
    final store = await emptyStore();
    CatalogController(store, 'u1').toggleFavorite(demoCatalog.first.id);
    expect(
      CatalogController(store, 'u1').isFavorite(demoCatalog.first.id),
      isTrue,
    );
    expect(
      CatalogController(store, 'u2').isFavorite(demoCatalog.first.id),
      isFalse,
    );
  });

  test('demo kataloğundaki görseller var olan dosyaları gösterir', () {
    for (final p in demoCatalog) {
      expect(p.imageUrl, startsWith('assets/images/products/'), reason: p.name);
      expect(p.ingredients, isNotEmpty, reason: p.name);
    }
    expect(demoCatalog.map((p) => p.id).toSet(), hasLength(demoCatalog.length));
  });

  group('topluluk kataloğu (cihaz modu)', () {
    Future<Product> propose(
      CatalogController c, {
      String name = 'Papatya Tonik',
    }) => c.submit(
      name: name,
      brand: 'Bahçe',
      category: 'Tonik',
      skinTypes: const ['Hassas Cilt'],
      ingredients: const ['Aqua', 'Glycerin'],
      barcode: '8690000000017',
      submitterName: 'Ayşe Y.',
    );

    test('öneri ekip onayıyla herkese açılır, öneren bildirim alır', () async {
      final store = await emptyStore();
      final ayse = CatalogController(store, 'u1');
      final p = await propose(ayse);
      expect(p.addedBy, 'Ayşe Y.');

      // Başka kullanıcı ve yetkisiz biri görmez, karar veremez.
      final other = CatalogController(store, 'u2');
      expect(other.byId(p.id), isNull);
      expect(other.reviewQueue, isEmpty);
      await expectLater(other.approve(p.id), throwsStateError);

      // Ekip kuyruğunda görür ve onaylar.
      final team = CatalogController(store, 'admin', isAdmin: true);
      expect(team.reviewQueue.map((e) => e.id), [p.id]);
      await team.approve(p.id);
      expect(team.reviewQueue, isEmpty);

      final everyone = CatalogController(store, 'u2');
      final approved = everyone.byId(p.id)!;
      expect(approved.isPending, isFalse);
      expect(approved.approvedAt, isNotNull);
      expect(approved.isNew(DateTime.now()), isTrue);

      final again = CatalogController(store, 'u1');
      expect(again.unseenDecisions.map((e) => e.id), [p.id]);
      again.markDecisionSeen(p.id);
      expect(CatalogController(store, 'u1').unseenDecisions, isEmpty);
    });

    test(
      'reddedilen öneri gerekçesiyle önerene döner, düzeltilip gönderilir',
      () async {
        final store = await emptyStore();
        final ayse = CatalogController(store, 'u1');
        final p = await propose(ayse);
        await CatalogController(
          store,
          'a',
          isAdmin: true,
        ).reject(p.id, 'İçerik listesi eksik.');

        final back = CatalogController(store, 'u1');
        final rejected = back.byId(p.id)!;
        expect(rejected.isRejected, isTrue);
        expect(rejected.rejectReason, 'İçerik listesi eksik.');
        expect(back.products.any((e) => e.id == p.id), isFalse);
        expect(back.unseenDecisions.single.id, p.id);
        // Reddedilen ürün yeniden önerilmeyi engellemez.
        expect(back.findDuplicate('Papatya Tonik', 'Bahçe'), isNull);

        final fixed = await back.submit(
          name: 'Papatya Tonik',
          brand: 'Bahçe',
          category: 'Tonik',
          skinTypes: const ['Hassas Cilt'],
          ingredients: const ['Aqua', 'Chamomilla Recutita Flower Water'],
          replacing: p.id,
        );
        expect(back.submissions.map((e) => e.id), [fixed.id]);
        expect(fixed.isPending, isTrue);
      },
    );

    test('aynı barkodla ikinci öneri yakalanır', () async {
      final c = CatalogController(await emptyStore(), 'u1');
      await propose(c);
      expect(
        c.findDuplicate('Başka Ad', 'Başka Marka', barcode: '8690000000017'),
        isNotNull,
      );
      expect(c.search(query: '8690000000017'), isNotEmpty);
    });

    test('puanlar uydurulmaz: topluluk yorumlarından hesaplanır', () async {
      final c = CatalogController(await emptyStore(), 'u1');
      final cleanser = c.byId('p-temizleyici-lumen')!;
      expect(cleanser.reviewCount, 2);
      expect(cleanser.rating, 4.5);
      // Yorumu olmayan ürün puansız görünür.
      final gel = c.byId('p-nemlendirici-jel-clarity')!;
      expect(gel.reviewCount, 0);
    });

    test(
      'eski sürümün kullanıcıya özel önerileri ortak listeye taşınır',
      () async {
        final store = await emptyStore({
          'u.u1.submissions':
              '[{"id":"p-eski","name":"Eski","brand":"Marka","category":"Serum","status":"pending"}]',
        });
        final c = CatalogController(store, 'u1');
        expect(c.byId('p-eski')?.isPending, isTrue);
        expect(store.read('u.u1.submissions'), isNull);
        expect(
          CatalogController(store, 'a', isAdmin: true).reviewQueue.single.id,
          'p-eski',
        );
      },
    );
  });
}
