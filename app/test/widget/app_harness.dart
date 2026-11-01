import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:skinsavvy_app/app.dart';
import 'package:skinsavvy_app/data/local/local_store.dart';
import 'package:skinsavvy_app/state/session_controller.dart';

import '../helpers.dart';

/// 1×1 PNG: fotoğraf seçici testlerde bunu döndürür.
final testPng = Uint8List.fromList(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
  ),
);

/// Galeriyi açmadan seçilmiş bir fotoğraf döndüren sahte seçici.
class FakeImagePicker extends ImagePickerPlatform {
  FakeImagePicker(this.bytes);

  /// Döndürülecek dosya; null ise kullanıcı vazgeçmiş sayılır.
  Uint8List? bytes;
  int calls = 0;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    calls++;
    final b = bytes;
    return b == null ? null : XFile.fromData(b, name: 'urun.png');
  }
}

/// Sahte seçiciyi kurar (her test için yenisi).
FakeImagePicker installFakePicker([Uint8List? bytes]) {
  final fake = FakeImagePicker(bytes ?? testPng);
  ImagePickerPlatform.instance = fake;
  return fake;
}

/// Uygulamanın tamamını telefon boyutunda başlatır.
Future<SessionController> pumpApp(
  WidgetTester tester, {
  LocalStore? store,
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final s = store ?? await emptyStore();
  final session = SessionController(fastAuth(s));
  await session.restore();
  await tester.pumpWidget(SkinSavvyApp(store: s, session: session));
  await tester.pumpAndSettle();
  return session;
}

/// Metni içeren ilk öğeyi görünür hâle getirip dokunur.
Future<void> tapText(WidgetTester tester, String text) =>
    tapFinder(tester, find.textContaining(text).first);

/// Belirli bir düğme türündeki metne dokunur (aynı metin başka yerde de varsa).
Future<void> tapButton<T extends Widget>(WidgetTester tester, String text) =>
    tapFinder(tester, find.widgetWithText(T, text).first);

Future<void> tapFinder(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
