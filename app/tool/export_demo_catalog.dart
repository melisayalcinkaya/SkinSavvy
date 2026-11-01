// Demo kataloğunu sunucunun okuduğu JSON'a yazar:
//   cd app && dart run tool/export_demo_catalog.dart
// test/unit/catalog_sync_test.dart iki tarafın aynı kaldığını denetler.
import 'dart:convert';
import 'dart:io';

import 'package:skinsavvy_app/data/demo/demo_catalog.dart';

void main() {
  final file = File('../backend/app/data/demo_catalog.json');
  const encoder = JsonEncoder.withIndent('  ');
  file.writeAsStringSync(
    '${encoder.convert([for (final p in demoCatalog) p.toJson()])}\n',
  );
  stdout.writeln('${demoCatalog.length} ürün yazıldı: ${file.path}');
}
