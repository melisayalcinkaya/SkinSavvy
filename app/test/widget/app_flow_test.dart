import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skinsavvy_app/presentation/screens/reminders/reminders_screen.dart';
import 'package:skinsavvy_app/presentation/screens/auth/login_screen.dart';
import 'package:skinsavvy_app/presentation/screens/main_navigation.dart';
import 'package:skinsavvy_app/presentation/screens/moderation/moderation_screen.dart';
import 'package:skinsavvy_app/presentation/screens/products/product_detail_screen.dart';
import 'package:skinsavvy_app/presentation/screens/onboarding/onboarding_flow.dart';

import 'app_harness.dart';

void main() {
  testWidgets('oturum yoksa giriş ekranı açılır', (tester) async {
    await pumpApp(tester);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('SkinSavvy'), findsOneWidget);
  });

  testWidgets('geçersiz form gönderilmez, hata mesajı gösterilir', (
    tester,
  ) async {
    await pumpApp(tester);
    await tapButton<ElevatedButton>(tester, 'Giriş Yap');
    expect(find.text('Geçerli bir e-posta adresi girin.'), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('demo hesabı ana sayfayı örnek verilerle açar', (tester) async {
    await pumpApp(tester);
    await tapText(tester, 'Demo hesabıyla dene');
    expect(find.byType(MainNavigation), findsOneWidget);
    expect(find.text('Merhaba Ece 👋'), findsOneWidget);
    expect(find.text('Nem Dengesi Temizleyici'), findsWidgets);

    // Demo rutininde BHA tonik (Pzt/Çar/Cum) ile retinol aynı akşamda.
    expect(find.text('Rutin uyarıları'), findsOneWidget);
    expect(find.text('Retinoid ve asit aynı vakitte'), findsOneWidget);
    expect(find.textContaining('Akşam · Pzt, Çar, Cum'), findsOneWidget);

    // Zil: 166 gün önce açılan 6 aylık C vitamini serumu ve %15 kalan
    // retinol serumu hatırlatılır.
    await tapFinder(tester, find.byType(ReminderBell));
    expect(find.text('Hatırlatmalar'), findsOneWidget);
    expect(find.textContaining('gün kaldı'), findsWidgets);
    expect(find.textContaining('bitmek üzere'), findsWidgets);
    await tapFinder(tester, find.byTooltip('Geri'));

    // Ürün detayında profile göre içerik analizi.
    await tapText(tester, 'Ürünler');
    await tapText(tester, 'Retinol %0.3 Gece Serumu');
    expect(find.text('İçerik Analizi'), findsOneWidget);
    await tapFinder(tester, find.byTooltip('Geri'));

    // Koleksiyon sekmesinde dolap ürünleri görünür.
    await tapText(tester, 'Koleksiyon');
    expect(find.text('Koleksiyonlarım'), findsOneWidget);
    expect(find.text('C Vitamini %15 Serum'), findsWidgets);
  });

  testWidgets('kayıt → karşılama → ana sayfa; profil kaydedilir', (
    tester,
  ) async {
    final session = await pumpApp(tester);
    await tapText(tester, 'Kayıt Ol');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Adınız Soyadınız'),
      'Deniz Kaya',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'ornek@email.com'),
      'deniz@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Şifre'),
      'cok-gizli-123',
    );
    await tapButton<ElevatedButton>(tester, 'Kayıt Ol');

    expect(find.byType(OnboardingFlow), findsOneWidget);
    await tapText(tester, 'Yağlı Cilt');
    await tapText(tester, 'Devam Et');
    await tapText(tester, 'Gözenek');
    await tapText(tester, 'Devam Et');
    await tapText(tester, 'Retinol');
    await tapText(tester, 'Devam Et');
    await tapText(tester, 'Devam Et');
    expect(find.textContaining('Kaçınılacak: Retinol'), findsOneWidget);
    await tapText(tester, 'Uygulamaya Başla');

    expect(find.byType(MainNavigation), findsOneWidget);
    expect(find.text('Merhaba Deniz 👋'), findsOneWidget);
    final profile = session.user!.skinProfile;
    expect(profile.skinType, 'Yağlı Cilt');
    expect(profile.concerns, {'Gözenek'});
    expect(profile.allergens, {'Retinol'});
    expect(session.user!.onboarded, isTrue);
  });

  testWidgets(
    'ürün önerisi: ekip onaylar, herkese açılır, önerene bildirim gider',
    (tester) async {
      await pumpApp(tester);
      await tapText(tester, 'Demo hesabıyla dene');

      // Katalogda yok → öner.
      await tapFinder(tester, find.byIcon(Icons.shopping_bag_outlined).last);
      await tester.enterText(find.byType(TextField).first, 'Papatya Tonik');
      await tester.pumpAndSettle();
      await tapText(tester, 'Bu ürünü sisteme ekle');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'örn: CeraVe'),
        'Bahçe Kozmetik',
      );
      await tapFinder(tester, find.text('Kategori seçin'));
      await tapFinder(tester, find.text('Tonik').last);
      await tapFinder(tester, find.text('Hassas Cilt').last);
      await tapText(tester, 'Devam Et');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Aqua, Glycerin, Niacinamide...'),
        'Aqua, Chamomilla Recutita Flower Water, Glycerin, Allantoin',
      );
      await tester.pumpAndSettle();
      await tapText(tester, 'Devam Et');
      await tapText(tester, 'İncelemeye Gönder');
      expect(find.text('İncelemeye Gönderildi!'), findsOneWidget);

      // Ekip (demo hesabı bu yetkiye sahip) onaylar.
      await tapText(tester, 'Onay ekranını aç');
      expect(find.byType(ModerationScreen), findsOneWidget);
      expect(find.text('Papatya Tonik'), findsOneWidget);
      expect(find.textContaining('Öneren: Ece D.'), findsOneWidget);
      await tapText(tester, 'Onayla');
      expect(find.text('İncelenecek öneri yok'), findsOneWidget);
      await tapFinder(tester, find.byTooltip('Geri'));
      await tapText(tester, 'Koleksiyonuma Git');

      // Öneren zilde kararı görür; ürün katalogda "Ekleyen" bilgisiyle.
      await tapFinder(tester, find.byIcon(Icons.calendar_today_outlined).last);
      await tapFinder(tester, find.byType(ReminderBell));
      await tapText(tester, 'Papatya Tonik onaylandı');
      expect(find.byType(ProductDetailScreen), findsOneWidget);
      expect(find.textContaining('Ekleyen: Ece D.'), findsOneWidget);
      expect(find.text('Yeni'), findsOneWidget);
      expect(find.text('Henüz değerlendirme yok'), findsOneWidget);
      await tapFinder(tester, find.byTooltip('Geri'));
      // Bildirim görüldü, listeden kalktı.
      expect(find.text('Papatya Tonik onaylandı'), findsNothing);
    },
  );
}
