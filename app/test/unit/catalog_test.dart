import 'package:flutter_test/flutter_test.dart';
import 'package:skinsavvy_app/data/demo/demo_catalog.dart';
import 'package:skinsavvy_app/data/models/product.dart';
import 'package:skinsavvy_app/state/catalog_controller.dart';

import '../helpers.dart';

const png = 'data:image/png;base64,iVBORw0KGgo=';

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
      imageUrl: png,
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
      imageUrl: png,
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

    test('fotoğrafsız öneri kabul edilmez', () async {
      final c = CatalogController(await emptyStore(), 'u1');
      await expectLater(
        c.submit(
          name: 'Fotoğrafsız',
          brand: 'Marka',
          category: 'Tonik',
          skinTypes: const ['Hassas Cilt'],
          ingredients: const ['Aqua', 'Glycerin'],
          imageUrl: '',
        ),
        throwsArgumentError,
      );
      expect(c.submissions, isEmpty);
    });

    test(
      'ekip düzeltip onaylar; öneren "ekip düzenledi" notunu görür',
      () async {
        final store = await emptyStore();
        final p = await propose(
          CatalogController(store, 'u1'),
          name: 'papatya tnk',
        );
        final team = CatalogController(store, 'a', isAdmin: true);
        await team.approve(
          p.id,
          edited: p.copyWith(
            name: 'Papatya Tonik',
            ingredients: const ['Aqua', 'Chamomilla Recutita Flower Water'],
            barcode: null,
            clearBarcode: true,
          ),
        );
        final approved = CatalogController(store, 'u2').byId(p.id)!;
        expect(approved.name, 'Papatya Tonik');
        expect(approved.isApproved, isTrue);
        expect(approved.editedByTeam, isTrue);
        expect(approved.barcode, isNull);
        expect(approved.ingredients, hasLength(2));
        expect(
          CatalogController(store, 'u1').unseenDecisions.single.editedByTeam,
          isTrue,
        );
      },
    );

    test('düzeltme katalogdaki başka ürünle çakışamaz', () async {
      final store = await emptyStore();
      final p = await propose(CatalogController(store, 'u1'));
      final team = CatalogController(store, 'a', isAdmin: true);
      final lumen = team.byId('p-temizleyici-lumen')!;
      await expectLater(
        team.approve(
          p.id,
          edited: p.copyWith(name: lumen.name, brand: lumen.brand),
        ),
        throwsStateError,
      );
      expect(team.reviewQueue.single.id, p.id);
    });

    test('yinelenen öneri asıl ürüne bağlanır, katalogda görünmez', () async {
      final store = await emptyStore();
      final p = await propose(CatalogController(store, 'u1'));
      final team = CatalogController(store, 'a', isAdmin: true);
      // Asıl ürün onaylı olmalı; önerinin kendisi ya da olmayan ürün olmaz.
      await expectLater(team.markDuplicate(p.id, p.id), throwsStateError);
      await expectLater(team.markDuplicate(p.id, 'yok'), throwsStateError);
      await team.markDuplicate(p.id, 'p-temizleyici-lumen');
      expect(team.reviewQueue, isEmpty);
      await expectLater(team.remove(p.id), throwsStateError);

      final back = CatalogController(store, 'u1');
      final dup = back.submissions.single;
      expect(dup.isDuplicate, isTrue);
      expect(dup.duplicateOf, 'p-temizleyici-lumen');
      expect(back.products.any((e) => e.id == p.id), isFalse);
      expect(back.unseenDecisions.single.id, p.id);
      expect(back.contributionCount, 0);
    });

    test(
      'silinen öneri içeriğiyle birlikte kalkar, önerene bildirilir',
      () async {
        final store = await emptyStore();
        final p = await propose(CatalogController(store, 'u1'));
        await CatalogController(store, 'a', isAdmin: true).remove(p.id);

        final back = CatalogController(store, 'u1');
        final removed = back.submissions.single;
        expect(removed.isRemoved, isTrue);
        expect(removed.imageUrl, isEmpty);
        expect(removed.ingredients, isEmpty);
        expect(removed.barcode, isNull);
        expect(back.products.any((e) => e.id == p.id), isFalse);
        expect(back.unseenDecisions.single.id, p.id);
        // Silinen öneri yinelenen kontrolüne takılmaz.
        expect(back.findDuplicate('Papatya Tonik', 'Bahçe'), isNull);
      },
    );

    test('eski sürümün "rejected" kaydı silinmiş sayılır', () {
      final p = Product.fromJson({
        'id': 'p1',
        'name': 'Eski',
        'brand': 'Marka',
        'category': 'Serum',
        'status': 'rejected',
      });
      expect(p.isRemoved, isTrue);
      expect(Product.fromJson(p.toJson()).isRemoved, isTrue);
    });

    test('katkı sayısı onaylı ve bekleyen önerileri sayar', () async {
      final store = await emptyStore();
      final c = CatalogController(store, 'u1');
      final a = await propose(c);
      await propose(c, name: 'Gül Suyu');
      await CatalogController(store, 'a', isAdmin: true).approve(a.id);
      expect(CatalogController(store, 'u1').contributionCount, 2);
    });

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
