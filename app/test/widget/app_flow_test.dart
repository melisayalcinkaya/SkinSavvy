import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skinsavvy_app/presentation/screens/auth/login_screen.dart';
import 'package:skinsavvy_app/presentation/screens/main_navigation.dart';
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
}
