import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skinsavvy_app/app.dart';
import 'package:skinsavvy_app/data/local/local_store.dart';
import 'package:skinsavvy_app/state/session_controller.dart';

import '../helpers.dart';

/// Uygulamanın tamamını telefon boyutunda başlatır.
Future<SessionController> pumpApp(
  WidgetTester tester, {
  LocalStore? store,
}) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
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
