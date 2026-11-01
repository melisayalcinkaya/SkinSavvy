import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:skinsavvy_app/data/demo/demo_catalog.dart';

/// Sunucu demo kataloğunu backend/app/data/demo_catalog.json'dan yükler.
/// Uygulamadaki liste değişip JSON güncellenmezse iki taraf ayrışır.
void main() {
  test('sunucunun demo kataloğu uygulamadakiyle aynı', () {
    final file = File('../backend/app/data/demo_catalog.json');
    final server = jsonDecode(file.readAsStringSync()) as List;
    final app = [for (final p in demoCatalog) p.toJson()];
    expect(
      jsonEncode(server),
      jsonEncode(app),
      reason:
          'Kataloğu değiştirdiysen JSON dosyasını da yeniden üret '
          '(README > Demo kataloğu).',
    );
  });
}
