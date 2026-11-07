import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:skinsavvy_app/state/shelf_controller.dart';
import 'package:skinsavvy_app/presentation/screens/reminders/reminders_screen.dart';
import 'package:skinsavvy_app/presentation/screens/auth/login_screen.dart';
import 'package:skinsavvy_app/presentation/screens/main_navigation.dart';
import 'package:skinsavvy_app/presentation/screens/moderation/moderation_screen.dart';
import 'package:skinsavvy_app/presentation/screens/products/add_product_screen.dart';
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
    expect(find.textContaining('"Ürün Ekle" butonuyla'), findsOneWidget);
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
      // Fotoğraf zorunlu: seçilmeden gönderilemez.
      final picker = installFakePicker();
      await tapText(tester, 'İncelemeye Gönder');
      expect(find.textContaining('Ürün fotoğrafı ekleyin'), findsOneWidget);
      await tapFinder(tester, find.text('Fotoğraf Seç'));
      expect(picker.calls, 1);
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

  ShelfController shelfOf(WidgetTester tester) => tester
      .element(find.byType(MainNavigation, skipOffstage: false))
      .read<ShelfController>();

  /// Demo hesabıyla bir ürün önerir ve onay ekranını açar.
  Future<void> proposeAndOpenQueue(WidgetTester tester, String name) async {
    await tapText(tester, 'Demo hesabıyla dene');
    await tapFinder(tester, find.byIcon(Icons.shopping_bag_outlined).last);
    await tester.enterText(find.byType(TextField).first, name);
    await tester.pumpAndSettle();
    await tapText(tester, 'Bu ürünü sisteme ekle');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'örn: CeraVe'),
      'Lumen Lab',
    );
    await tapFinder(tester, find.text('Kategori seçin'));
    await tapFinder(tester, find.text('Temizleyici').last);
    await tapFinder(tester, find.text('Hassas Cilt').last);
    await tapText(tester, 'Devam Et');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Aqua, Glycerin, Niacinamide...'),
      'Aqua, Glycerin, Panthenol, Allantoin',
    );
    await tester.pumpAndSettle();
    await tapText(tester, 'Devam Et');
    installFakePicker();
    await tapFinder(tester, find.text('Fotoğraf Seç'));
    await tapText(tester, 'İncelemeye Gönder');
    await tapText(tester, 'Onay ekranını aç');
    expect(find.byType(ModerationScreen), findsOneWidget);
  }

  testWidgets('yinelenen öneri asıl ürüne bağlanır, dolap kaydı taşınır', (
    tester,
  ) async {
    await pumpApp(tester);
    await proposeAndOpenQueue(tester, 'Nem Dengesi Temizleyicisi');
    // Ekip benzer ürünü önerir; tek dokunuşla bağlanır.
    expect(find.textContaining('Katalogda benzer ürün var'), findsOneWidget);
    await tapButton<TextButton>(tester, 'Bağla');
    await tapButton<TextButton>(tester, 'Asıl ürüne bağla');
    expect(find.text('İncelenecek öneri yok'), findsOneWidget);
    await tapFinder(tester, find.byTooltip('Geri'));
    await tapText(tester, 'Koleksiyonuma Git');

    // Zil: karar bildirimi; dokununca asıl ürün açılır.
    await tapFinder(tester, find.byIcon(Icons.calendar_today_outlined).last);
    await tapFinder(tester, find.byType(ReminderBell));
    expect(
      find.text('Nem Dengesi Temizleyicisi zaten katalogdaymış'),
      findsOneWidget,
    );
    await tapText(tester, 'Nem Dengesi Temizleyicisi zaten katalogdaymış');
    expect(find.byType(ProductDetailScreen), findsOneWidget);
    expect(find.text('Nem Dengesi Temizleyici'), findsWidgets);

    // Dolapta yinelenen kayıt kalmaz; kayıt asıl ürüne bağlanmıştır.
    final items = shelfOf(tester).all;
    expect(items.any((e) => e.name == 'Nem Dengesi Temizleyicisi'), isFalse);
    expect(
      items.where((e) => e.productId == 'p-temizleyici-lumen').length,
      greaterThan(1),
    );
  });

  testWidgets('spam öneri silinir, önerenin dolabından da kalkar', (
    tester,
  ) async {
    await pumpApp(tester);
    await proposeAndOpenQueue(tester, 'Mucize Krem 3000');
    await tapButton<OutlinedButton>(tester, 'Sil');
    await tapButton<TextButton>(tester, 'Sil');
    expect(find.text('İncelenecek öneri yok'), findsOneWidget);
    await tapFinder(tester, find.byTooltip('Geri'));
    await tapText(tester, 'Koleksiyonuma Git');
    expect(
      shelfOf(tester).all.any((e) => e.name == 'Mucize Krem 3000'),
      isFalse,
    );
    await tapFinder(tester, find.byIcon(Icons.calendar_today_outlined).last);
    await tapFinder(tester, find.byType(ReminderBell));
    expect(find.text('Mucize Krem 3000 kataloğa eklenmedi'), findsOneWidget);
  });

  testWidgets('ekip düzeltip onaylar; önerene "ekip düzeltti" notu gider', (
    tester,
  ) async {
    await pumpApp(tester);
    await proposeAndOpenQueue(tester, 'Gul Suyu Tonik');
    await tapButton<OutlinedButton>(tester, 'Düzenle');
    expect(find.text('Düzenle ve onayla'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Ürün adı'),
      'Gül Suyu Tonik',
    );
    await tapText(tester, 'Kaydet ve onayla');
    expect(find.text('İncelenecek öneri yok'), findsOneWidget);
    await tapFinder(tester, find.byTooltip('Geri'));
    await tapText(tester, 'Koleksiyonuma Git');
    // Ekip düzeltmesi önerenin dolabına da yansır.
    final names = shelfOf(tester).all.map((e) => e.name);
    expect(names, contains('Gül Suyu Tonik'));
    expect(names, isNot(contains('Gul Suyu Tonik')));
    await tapFinder(tester, find.byIcon(Icons.calendar_today_outlined).last);
    await tapFinder(tester, find.byType(ReminderBell));
    expect(find.text('Gül Suyu Tonik onaylandı'), findsOneWidget);
    expect(find.textContaining('Ekip bazı bilgilerini'), findsOneWidget);
  });

  testWidgets('bitirdiklerim memnuniyete göre süzülür', (tester) async {
    await pumpApp(tester);
    await tapText(tester, 'Demo hesabıyla dene');
    await tapFinder(tester, find.byIcon(Icons.bookmarks_outlined).last);
    await tapText(tester, 'Bitirdiklerim');
    final all = find.textContaining('Tekrar Al');
    final total = all.evaluate().length;
    expect(total, greaterThan(0));
    await tapText(tester, 'Memnun kaldıklarım');
    final liked = find.text('✓ Tekrar Alırım').evaluate().length;
    expect(find.text('✗ Tekrar Almam'), findsNothing);
    await tapText(tester, 'Memnun kalmadıklarım');
    expect(find.text('✓ Tekrar Alırım'), findsNothing);
    expect(liked + find.text('✗ Tekrar Almam').evaluate().length, total);
  });

  testWidgets('ürün ekleme her zaman görünür; tanıtım kartı bir kez çıkar', (
    tester,
  ) async {
    await pumpApp(tester);
    await tapText(tester, 'Demo hesabıyla dene');
    await tapFinder(tester, find.byIcon(Icons.shopping_bag_outlined).last);
    const intro = 'Katalog seninle büyüyor 🌱';
    expect(find.text(intro), findsOneWidget);

    // Sağ alttaki sabit buton arama yapmadan formu açar.
    await tapFinder(
      tester,
      find.widgetWithText(FloatingActionButton, 'Ürün Ekle'),
    );
    expect(find.byType(AddProductScreen), findsOneWidget);
    await tapFinder(tester, find.byTooltip('Geri').last);

    // Form bir kez açıldı: kart kalktı, buton duruyor.
    expect(find.text(intro), findsNothing);
    expect(
      find.widgetWithText(FloatingActionButton, 'Ürün Ekle'),
      findsOneWidget,
    );
  });

  testWidgets(
    'tanıtım kartı "Anladım" ile kapanır, Koleksiyon\'dan da ulaşılır',
    (tester) async {
      await pumpApp(tester);
      await tapText(tester, 'Demo hesabıyla dene');
      await tapFinder(tester, find.byIcon(Icons.shopping_bag_outlined).last);
      await tapText(tester, 'Anladım');
      expect(find.text('Katalog seninle büyüyor 🌱'), findsNothing);

      // Koleksiyon'daki "Ürün ekle" Ürünler sekmesine götürür.
      await tapFinder(tester, find.byIcon(Icons.bookmarks_outlined).last);
      await tapButton<TextButton>(tester, 'Ürün ekle');
      expect(
        find.widgetWithText(FloatingActionButton, 'Ürün Ekle'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'ekip ürünü katalogdan kaldırır; dolaptaki kayıt durur, geri alınır',
    (tester) async {
      await pumpApp(tester);
      await tapText(tester, 'Demo hesabıyla dene');
      await tapFinder(tester, find.byIcon(Icons.shopping_bag_outlined).last);
      await tapText(tester, 'Nem Dengesi Temizleyici');
      expect(find.byType(ProductDetailScreen), findsOneWidget);
      await tapFinder(tester, find.byTooltip('Ekip işlemleri'));
      await tapText(tester, 'Katalogdan kaldır');
      await tapButton<TextButton>(tester, 'Kaldır');
      expect(find.text('Katalogdan kaldırıldı'), findsOneWidget);
      expect(find.textContaining('Dolabındaki kaydın'), findsOneWidget);
      await tapFinder(tester, find.byTooltip('Geri'));

      // Aramada çıkmaz; dolaptaki kayıt durur ve işaretlenir.
      await tester.enterText(find.byType(TextField).first, 'Nem Dengesi');
      await tester.pumpAndSettle();
      expect(find.text('Ürün bulunamadı'), findsOneWidget);
      expect(
        shelfOf(tester).all.any((e) => e.productId == 'p-temizleyici-lumen'),
        isTrue,
      );
      await tester.enterText(find.byType(TextField).first, '');
      await tapFinder(tester, find.byIcon(Icons.bookmarks_outlined).last);
      expect(find.text('Katalogdan kaldırıldı'), findsOneWidget);

      // Ekip onay ekranından geri alır.
      await tapFinder(tester, find.byIcon(Icons.person_outline).last);
      await tapText(tester, 'Onay Bekleyen Ürünler');
      expect(find.text('Katalogdan kaldırılanlar (1)'), findsOneWidget);
      await tapButton<TextButton>(tester, 'Geri al');
      expect(find.textContaining('Katalogdan kaldırılanlar'), findsNothing);
    },
  );

  testWidgets('ekip katalogdaki ürünü düzenler', (tester) async {
    await pumpApp(tester);
    await tapText(tester, 'Demo hesabıyla dene');
    await tapFinder(tester, find.byIcon(Icons.shopping_bag_outlined).last);
    await tapText(tester, 'Retinol %0.3 Gece Serumu');
    await tapFinder(tester, find.byTooltip('Ekip işlemleri'));
    await tapText(tester, 'Düzenle');
    expect(find.text('Ürünü düzenle'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Ürün adı'),
      'Retinol %0.3 Gece Serumu Yeni',
    );
    await tapText(tester, 'Kaydet');
    expect(find.text('Retinol %0.3 Gece Serumu Yeni'), findsOneWidget);
  });

  testWidgets('kullanıcı bekleyen önerisini geri çeker', (tester) async {
    await pumpApp(tester);
    await proposeAndOpenQueue(tester, 'Lavanta Tonik');
    await tapFinder(tester, find.byTooltip('Geri'));
    await tapText(tester, 'Koleksiyonuma Git');
    await tapFinder(tester, find.byIcon(Icons.shopping_bag_outlined).last);
    await tester.enterText(find.byType(TextField).first, '');
    await tester.pumpAndSettle();
    await tapText(tester, 'Lavanta Tonik');
    await tapButton<OutlinedButton>(tester, 'Öneriyi geri çek');
    await tapButton<TextButton>(tester, 'Geri çek');
    expect(find.byType(ProductDetailScreen), findsNothing);
    expect(shelfOf(tester).all.any((e) => e.name == 'Lavanta Tonik'), isFalse);
    await tapFinder(tester, find.byIcon(Icons.person_outline).last);
    await tapText(tester, 'Onay Bekleyen Ürünler');
    expect(find.text('İncelenecek öneri yok'), findsOneWidget);
  });
}
