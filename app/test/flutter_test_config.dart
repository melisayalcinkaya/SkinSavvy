import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tüm testlerden önce çalışır.
///
/// Flutter testleri varsayılan olarak her harfi kare çizen "Ahem" yazı tipini
/// kullanır; metinler gerçekte olduğundan çok daha geniş ölçülür. Gerçek
/// yerleşimi sınamak için Flutter SDK'sıyla gelen Roboto yüklenir.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final root = Platform.environment['FLUTTER_ROOT'];
  final dir = Directory('$root/bin/cache/artifacts/material_fonts');
  if (root != null && dir.existsSync()) {
    final fonts = dir.listSync().whereType<File>().where(
      (f) =>
          f.uri.pathSegments.last.startsWith('Roboto-') &&
          f.path.endsWith('.ttf'),
    );
    final loader = FontLoader('Roboto');
    for (final f in fonts) {
      loader.addFont(
        f.readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
      );
    }
    await loader.load();
  }
  await testMain();
}
