import 'package:flutter_test/flutter_test.dart';
import 'package:skinsavvy_app/data/demo/demo_seed.dart';
import 'package:skinsavvy_app/data/local/keys.dart';
import 'package:skinsavvy_app/data/repositories/auth_repository.dart';

import '../helpers.dart';

void main() {
  test(
    'kayıt olan kullanıcı aynı şifreyle giriş yapabilir, oturum geri yüklenir',
    () async {
      final store = await emptyStore();
      final auth = fastAuth(store);
      final user = await auth.signUp(
        'Ece Demir',
        'Ece@Example.com',
        'gizli-sifre-1',
      );
      expect(user.email, 'ece@example.com');
      expect(user.onboarded, isFalse);

      await auth.signOut();
      expect(await auth.restoreSession(), isNull);

      final again = await auth.signIn('ECE@example.com', 'gizli-sifre-1');
      expect(again.id, user.id);
      expect((await auth.restoreSession())?.id, user.id);
    },
  );

  test('şifre düz metin olarak saklanmaz', () async {
    final store = await emptyStore();
    await fastAuth(store).signUp('Ece', 'ece@example.com', 'gizli-sifre-1');
    expect(
      store.read('auth.accounts').toString(),
      isNot(contains('gizli-sifre-1')),
    );
  });

  test('yanlış şifre ve olmayan hesap aynı mesajı verir', () async {
    final store = await emptyStore();
    final auth = fastAuth(store);
    await auth.signUp('Ece', 'ece@example.com', 'gizli-sifre-1');

    Future<String> messageOf(Future<void> f) async {
      try {
        await f;
        return '';
      } on AuthException catch (e) {
        return e.message;
      }
    }

    final wrong = await messageOf(
      auth.signIn('ece@example.com', 'yanlis-sifre'),
    );
    final missing = await messageOf(
      auth.signIn('yok@example.com', 'gizli-sifre-1'),
    );
    expect(wrong, isNotEmpty);
    expect(wrong, missing);
  });

  test('aynı e-posta ile ikinci kayıt ve kısa şifre reddedilir', () async {
    final auth = fastAuth(await emptyStore());
    await auth.signUp('Ece', 'ece@example.com', 'gizli-sifre-1');
    expect(
      () => auth.signUp('Başka', 'ECE@example.com', 'baska-sifre-1'),
      throwsA(isA<AuthException>()),
    );
    expect(
      () => auth.signUp('Kısa', 'kisa@example.com', '1234'),
      throwsA(isA<AuthException>()),
    );
  });

  test('pbkdf2 RFC 7914 test vektörünü üretir', () {
    // RFC 7914 §11: PBKDF2-HMAC-SHA256 (P="passwd", S="salt", c=1, dkLen=64)
    final out = pbkdf2('passwd'.codeUnits, 'salt'.codeUnits, 1, 64);
    final hex = out.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    expect(hex.substring(0, 32), '55ac046e56e3089fec1691c22544b605');
  });

  test(
    'demo hesabı örnek verilerle açılır ve hesap silinince veriler gider',
    () async {
      final store = await emptyStore();
      final auth = fastAuth(store);
      final demo = await auth.signInDemo();
      expect(demo.isDemo, isTrue);
      expect(demo.onboarded, isTrue);
      expect(store.read(StoreKeys.user(demo.id, StoreKeys.shelf)), isA<List>());

      await auth.deleteAccount(demo);
      expect(store.read(StoreKeys.user(demo.id, StoreKeys.shelf)), isNull);
      expect(await auth.restoreSession(), isNull);
      expect(DemoSeed.email, 'demo@skinsavvy.app');
    },
  );

  test('e-posta değişikliği başka hesapla çakışamaz', () async {
    final auth = fastAuth(await emptyStore());
    await auth.signUp('Bir', 'bir@example.com', 'gizli-sifre-1');
    final iki = await auth.signUp('İki', 'iki@example.com', 'gizli-sifre-2');
    expect(
      () => auth.saveUser(iki.copyWith(email: 'bir@example.com')),
      throwsA(isA<AuthException>()),
    );

    await auth.saveUser(iki.copyWith(email: 'yeni@example.com'));
    await auth.signOut();
    final relogin = await auth.signIn('yeni@example.com', 'gizli-sifre-2');
    expect(relogin.id, iki.id);
  });
}
