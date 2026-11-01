import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../../core/utils/ids.dart';
import '../../core/utils/text_utils.dart';
import '../demo/demo_seed.dart';
import '../local/local_store.dart';
import '../models/json.dart';
import '../models/user.dart';

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Kimlik doğrulama sözleşmesi. Ekranlar yalnızca bunu bilir; verinin
/// cihazda mı sunucuda mı tutulduğu uygulamanın geri kalanını ilgilendirmez.
abstract class AuthRepository {
  Future<AppUser?> restoreSession();
  Future<AppUser> signIn(String email, String password);
  Future<AppUser> signUp(String name, String email, String password);
  Future<AppUser> signInDemo();
  Future<void> signOut();
  Future<AppUser> saveUser(AppUser user);
  Future<void> deleteAccount(AppUser user);

  /// Sunucu modunda e-posta gönderir; yerel modda desteklenmez.
  bool get supportsPasswordReset;
  Future<void> requestPasswordReset(String email);
}

const minPasswordLength = 8;

/// Hesapları cihazda tutan uygulama içi mod (çevrimdışı demo için).
///
/// Şifreler asla düz metin saklanmaz: her hesap için rastgele bir tuz üretilir
/// ve PBKDF2-HMAC-SHA256 ile türetilen özet saklanır. Gerçek çok kullanıcılı
/// kullanımda kimlik doğrulama sunucuda yapılmalıdır (bkz. backend).
class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository(this._store, {this.iterations = 10000});

  final LocalStore _store;
  final int iterations;

  static const _accountsKey = 'auth.accounts';
  static const _sessionKey = 'auth.session';

  Map<String, dynamic> get _accounts => asMap(_store.read(_accountsKey));

  Future<void> _saveAccounts(Map<String, dynamic> accounts) =>
      _store.write(_accountsKey, accounts);

  @override
  Future<AppUser?> restoreSession() async {
    final email = asString(_store.read(_sessionKey));
    if (email == null) return null;
    final account = asMap(_accounts[email]);
    if (account.isEmpty) return null;
    return AppUser.fromJson(asMap(account['user']));
  }

  @override
  Future<AppUser> signIn(String email, String password) async {
    final key = email.trim().toLowerCase();
    final account = asMap(_accounts[key]);
    final salt = asString(account['salt']);
    final hash = asString(account['hash']);
    // Hesap yoksa da aynı mesaj: hangi e-postaların kayıtlı olduğu sızmasın.
    if (salt == null ||
        hash == null ||
        !_constantTimeEquals(_hash(password, salt), hash)) {
      throw const AuthException('E-posta veya şifre hatalı.');
    }
    await _store.write(_sessionKey, key);
    return AppUser.fromJson(asMap(account['user']));
  }

  @override
  Future<AppUser> signUp(String name, String email, String password) async {
    final cleanName = sanitizeInput(name);
    final key = email.trim().toLowerCase();
    if (cleanName.length < 2) {
      throw const AuthException('Lütfen adınızı girin.');
    }
    if (!isValidEmail(key)) {
      throw const AuthException('Geçerli bir e-posta adresi girin.');
    }
    if (password.length < minPasswordLength) {
      throw const AuthException(
        'Şifre en az $minPasswordLength karakter olmalı.',
      );
    }
    final accounts = _accounts;
    if (accounts.containsKey(key)) {
      throw const AuthException('Bu e-posta ile kayıtlı bir hesap var.');
    }
    final salt = _newSalt();
    final user = AppUser(id: newId('u'), name: cleanName, email: key);
    accounts[key] = {
      'salt': salt,
      'hash': _hash(password, salt),
      'user': user.toJson(),
    };
    await _saveAccounts(accounts);
    await _store.write(_sessionKey, key);
    return user;
  }

  @override
  Future<AppUser> signInDemo() async {
    final accounts = _accounts;
    var user = AppUser.fromJson(asMap(asMap(accounts[DemoSeed.email])['user']));
    if (user.id.isEmpty) {
      user = DemoSeed.user;
      // Demo hesabının şifresi yok: yalnızca "Demo hesabıyla dene" ile girilir.
      accounts[DemoSeed.email] = {'user': user.toJson()};
      await _saveAccounts(accounts);
      await DemoSeed.writeData(_store, user.id, DateTime.now());
    }
    await _store.write(_sessionKey, DemoSeed.email);
    return user;
  }

  @override
  Future<void> signOut() => _store.remove(_sessionKey);

  @override
  Future<AppUser> saveUser(AppUser user) async {
    final accounts = _accounts;
    final oldKey = accounts.keys.firstWhere(
      (k) => asString(asMap(asMap(accounts[k])['user'])['id']) == user.id,
      orElse: () => throw const AuthException('Hesap bulunamadı.'),
    );
    final newKey = user.email.trim().toLowerCase();
    if (newKey != oldKey) {
      if (!isValidEmail(newKey)) {
        throw const AuthException('Geçerli bir e-posta adresi girin.');
      }
      if (accounts.containsKey(newKey)) {
        throw const AuthException('Bu e-posta başka bir hesapta kullanılıyor.');
      }
    }
    final account = asMap(accounts.remove(oldKey))..['user'] = user.toJson();
    accounts[newKey] = account;
    await _saveAccounts(accounts);
    if (asString(_store.read(_sessionKey)) == oldKey) {
      await _store.write(_sessionKey, newKey);
    }
    return user;
  }

  @override
  Future<void> deleteAccount(AppUser user) async {
    final accounts = _accounts
      ..removeWhere(
        (_, v) => asString(asMap(asMap(v)['user'])['id']) == user.id,
      );
    await _saveAccounts(accounts);
    await _store.removeWhere((k) => k.startsWith('u.${user.id}.'));
    await signOut();
  }

  @override
  bool get supportsPasswordReset => false;

  @override
  Future<void> requestPasswordReset(String email) async {
    throw const AuthException(
      'Cihaz modunda e-posta gönderilemez. Sunucuya bağlı sürümde sıfırlama bağlantısı e-postanıza gelir.',
    );
  }

  String _newSalt() {
    final r = Random.secure();
    return base64UrlEncode(List.generate(16, (_) => r.nextInt(256)));
  }

  String _hash(String password, String salt) => base64UrlEncode(
    pbkdf2(utf8.encode(password), utf8.encode(salt), iterations, 32),
  );

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}

/// RFC 8018 PBKDF2-HMAC-SHA256.
List<int> pbkdf2(
  List<int> password,
  List<int> salt,
  int iterations,
  int length,
) {
  final hmac = Hmac(sha256, password);
  final out = <int>[];
  for (var block = 1; out.length < length; block++) {
    var u = hmac.convert([
      ...salt,
      block >> 24 & 0xff,
      block >> 16 & 0xff,
      block >> 8 & 0xff,
      block & 0xff,
    ]).bytes;
    final t = List<int>.of(u);
    for (var i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < t.length; j++) {
        t[j] ^= u[j];
      }
    }
    out.addAll(t);
  }
  return out.sublist(0, length);
}
