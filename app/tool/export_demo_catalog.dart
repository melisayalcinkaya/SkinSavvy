// Demo kataloğunu ve topluluk yorumlarını sunucunun okuduğu JSON'lara yazar:
//   cd app && dart run tool/export_demo_catalog.dart
// test/unit/catalog_sync_test.dart iki tarafın aynı kaldığını denetler.
import 'dart:convert';
import 'dart:io';

import 'package:skinsavvy_app/data/demo/demo_catalog.dart';
import 'package:skinsavvy_app/data/demo/demo_reviews.dart';

void main() {
  const encoder = JsonEncoder.withIndent('  ');
  void write(String name, List<Map<String, dynamic>> items) {
    final file = File('../backend/app/data/$name');
    file.writeAsStringSync('${encoder.convert(items)}\n');
    stdout.writeln('${items.length} kayıt yazıldı: ${file.path}');
  }

  write('demo_catalog.json', [for (final p in demoCatalog) p.toJson()]);
  write('demo_reviews.json', [for (final r in demoReviews) r.toJson()]);
}
