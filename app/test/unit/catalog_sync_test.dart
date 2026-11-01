import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:skinsavvy_app/data/demo/demo_catalog.dart';
import 'package:skinsavvy_app/data/demo/demo_reviews.dart';

/// Sunucu demo verisini backend/app/data/*.json dosyalarından yükler.
/// Uygulamadaki liste değişip JSON güncellenmezse iki taraf ayrışır.
void main() {
  void same(String file, List<Map<String, dynamic>> app) {
    final server = jsonDecode(
      File('../backend/app/data/$file').readAsStringSync(),
    );
    expect(
      jsonEncode(server),
      jsonEncode(app),
      reason:
          '$file güncel değil: cd app && dart run tool/export_demo_catalog.dart',
    );
  }

  test('sunucunun demo kataloğu uygulamadakiyle aynı', () {
    same('demo_catalog.json', [for (final p in demoCatalog) p.toJson()]);
  });

  test('sunucunun topluluk yorumları uygulamadakiyle aynı', () {
    same('demo_reviews.json', [for (final r in demoReviews) r.toJson()]);
  });

  test('demo verisinde fiyat ve uydurma puan yok', () {
    for (final p in demoCatalog) {
      final json = p.toJson();
      expect(json.containsKey('price'), isFalse);
      expect(p.rating, 0, reason: 'Puan yorumlardan hesaplanır: ${p.name}');
      expect(p.addedBy, isNotNull);
    }
    final ids = {for (final p in demoCatalog) p.id};
    expect(demoReviews.every((r) => ids.contains(r.productId)), isTrue);
  });
}
