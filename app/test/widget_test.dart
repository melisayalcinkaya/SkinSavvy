import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:skinsavvy_app/main.dart';

void main() {
  testWidgets('SkinSavvy app starts and shows login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const SkinSavvyApp());

    // Login ekranındaki marka adı görünüyor mu kontrol et
    expect(find.text('SkinSavvy'), findsOneWidget);
  });
}