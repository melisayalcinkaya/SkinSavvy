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
}
