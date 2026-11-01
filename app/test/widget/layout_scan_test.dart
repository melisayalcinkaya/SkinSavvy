import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skinsavvy_app/presentation/screens/collections/edit_product_screen.dart';
import 'package:skinsavvy_app/presentation/screens/moderation/moderation_screen.dart';
import 'package:skinsavvy_app/presentation/screens/products/add_product_screen.dart';
import 'package:skinsavvy_app/presentation/screens/products/product_detail_screen.dart';
import 'package:skinsavvy_app/presentation/screens/profile/edit_profile_screen.dart';
import 'package:skinsavvy_app/presentation/screens/profile/edit_skin_profile_screen.dart';
import 'package:skinsavvy_app/presentation/screens/profile/notifications_screen.dart';
import 'package:skinsavvy_app/presentation/screens/reminders/reminders_screen.dart';
import 'package:skinsavvy_app/presentation/screens/routine/routine_editor_screen.dart';

import 'app_harness.dart';

/// Taşma taraması: ana ekranlar dar telefon (320 px), yaygın telefon (390 px)
/// ve masaüstü genişliğinde açılır. Gerçek Roboto ölçüleriyle çizildiği için
/// bir satır sığmazsa Flutter "RenderFlex overflowed" hatası verir ve test düşer.
void main() {
  const sizes = {
    'dar telefon': Size(320, 640),
    'telefon': Size(390, 844),
    'masaüstü': Size(1280, 800),
  };

  Future<void> back(WidgetTester tester, Type screen) async {
    Navigator.of(tester.element(find.byType(screen))).pop();
    await tester.pumpAndSettle();
  }

  // Sekmeler IndexedStack içinde; görünmeyen sekmedeki aynı metne
  // takılmamak için alt çubuktaki simgeyle geçilir.
  Future<void> tab(WidgetTester tester, IconData icon) =>
      tapFinder(tester, find.byIcon(icon).last);

  Future<void> scroll(WidgetTester tester) async {
    // Ekranın ortasından yukarı sürükle: hangi liste görünürse o kayar.
    final center = tester.view.physicalSize / tester.view.devicePixelRatio;
    await tester.dragFrom(
      Offset(center.width / 2, center.height / 2),
      const Offset(0, -2000),
    );
    await tester.pumpAndSettle();
  }

  for (final MapEntry(key: name, value: size) in sizes.entries) {
    testWidgets('$name (${size.width.toInt()} px): ekranlar taşmıyor', (
      tester,
    ) async {
      await pumpApp(tester, size: size);
      await tapText(tester, 'Demo hesabıyla dene');

      // Rutin (açılış sekmesi), uyarılar ve hatırlatmalar
      await scroll(tester);
      await tapFinder(tester, find.byType(ReminderBell));
      expect(find.byType(RemindersScreen), findsOneWidget);
      await back(tester, RemindersScreen);
      await tapFinder(tester, find.text('Düzenle').first);
      expect(find.byType(RoutineEditorScreen), findsOneWidget);
      await scroll(tester);
      await back(tester, RoutineEditorScreen);

      // Ürünler, ürün detayı, ürün ekleme
      await tab(tester, Icons.shopping_bag_outlined);
      await scroll(tester);
      await tapText(tester, 'Retinol %0.3 Gece Serumu');
      expect(find.byType(ProductDetailScreen), findsOneWidget);
      await scroll(tester);
      await back(tester, ProductDetailScreen);
      await tester.enterText(find.byType(TextField).first, 'olmayan ürün');
      await tester.pumpAndSettle();
      await tapText(tester, 'Bu ürünü sisteme ekle');
      expect(find.byType(AddProductScreen), findsOneWidget);
      await scroll(tester);
      await back(tester, AddProductScreen);
      await tester.enterText(find.byType(TextField).first, '');
      await tester.pumpAndSettle();

      // Koleksiyon sekmeleri ve ürün düzenleme
      await tab(tester, Icons.bookmarks_outlined);
      for (final tab in ['Kullandıklarım', 'Alınacaklar', 'Bitirdiklerim']) {
        await tapText(tester, tab);
        await scroll(tester);
      }
      await tapText(tester, 'Kullandıklarım');
      final edit = find.widgetWithText(OutlinedButton, 'Düzenle');
      if (edit.evaluate().isNotEmpty) {
        await tapFinder(tester, edit.first);
        expect(find.byType(EditProductScreen), findsOneWidget);
        await scroll(tester);
        await back(tester, EditProductScreen);
      }

      // Profil ve alt sayfaları
      await tab(tester, Icons.person_outline);
      await scroll(tester);
      for (final (label, screen) in [
        ('Profil Düzenle', EditProfileScreen),
        ('Bildirimler', NotificationsScreen),
      ]) {
        await tapText(tester, label);
        expect(find.byType(screen), findsOneWidget);
        await scroll(tester);
        await back(tester, screen);
      }
      await tapText(tester, 'Onay Bekleyen Ürünler');
      expect(find.byType(ModerationScreen), findsOneWidget);
      await back(tester, ModerationScreen);
      await tapFinder(tester, find.byTooltip('Cilt profilini düzenle'));
      expect(find.byType(EditSkinProfileScreen), findsOneWidget);
      await scroll(tester);
      await back(tester, EditSkinProfileScreen);
    });
  }
}
