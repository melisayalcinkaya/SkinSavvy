import '../demo/demo_seed.dart';
import '../local/keys.dart';
import '../local/local_store.dart';
import '../models/user.dart';
import '../remote/api_client.dart';
import 'auth_repository.dart';

/// Hesapları SkinSavvy API'sinde tutan mod.
///
/// Kimlik, ad, biyografi, fotoğraf ve cilt profili sunucuda; dolap, rutin ve
/// tamamlama kaydı (kişisel kullanım verisi) yine cihazda, kullanıcı kimliğiyle.
class RemoteAuthRepository implements AuthRepository {
  RemoteAuthRepository(this._api, this._store);

  final ApiClient _api;
  final LocalStore _store;

  static const demoEmail = 'demo@skinsavvy.app';
  static const demoPassword = 'demo-sifre-2026';

  AppUser _user(Map<String, dynamic> j) =>
      AppUser.fromJson({...j, 'isDemo': j['email'] == demoEmail});

  Future<AppUser> _run(Future<Object?> Function() call) async {
    try {
      final data = await call();
      return _user(Map<String, dynamic>.from(data! as Map));
    } on ApiException catch (e) {
      throw AuthException(e.message);
    }
  }

  @override
  Future<AppUser?> restoreSession() async {
    if (!_api.hasSession || !await _api.refresh()) return null;
    try {
      return _user(Map<String, dynamic>.from(await _api.get('/me') as Map));
    } on ApiException {
      return null;
    }
  }

  @override
  Future<AppUser> signIn(String email, String password) => _run(
    () async => _api.acceptTokens(
      Map<String, dynamic>.from(
        await _api.send(
              'POST',
              '/auth/login',
              body: {'email': email.trim(), 'password': password},
              auth: false,
            )
            as Map,
      ),
    ),
  );

  @override
  Future<AppUser> signUp(String name, String email, String password) => _run(
    () async => _api.acceptTokens(
      Map<String, dynamic>.from(
        await _api.send(
              'POST',
              '/auth/register',
              body: {
                'name': name.trim(),
                'email': email.trim(),
                'password': password,
              },
              auth: false,
            )
            as Map,
      ),
    ),
  );

  @override
  Future<AppUser> signInDemo() async {
    final user = await signIn(demoEmail, demoPassword);
    // Demo dolabı ve rutini cihazda yoksa örnek verilerle doldurulur.
    if (_store.read(StoreKeys.user(user.id, StoreKeys.shelf)) == null) {
      await DemoSeed.writeData(_store, user.id, DateTime.now());
    }
    return user;
  }

  @override
  Future<void> signOut() async {
    final token = _api.refreshToken;
    if (token != null) {
      try {
        await _api.send(
          'POST',
          '/auth/logout',
          body: {'refreshToken': token},
          auth: false,
        );
      } on ApiException {
        // Çevrimdışıysa da yerel oturum kapanır.
      }
    }
    await _api.clearSession();
  }

  @override
  Future<AppUser> saveUser(AppUser user) => _run(
    () => _api.patch('/me', {
      'name': user.name,
      'bio': user.bio,
      'avatar': user.avatar ?? '',
      'onboarded': user.onboarded,
      'skinProfile': user.skinProfile.toJson(),
    }),
  );

  @override
  Future<void> deleteAccount(AppUser user) async {
    try {
      await _api.delete('/me');
    } on ApiException catch (e) {
      throw AuthException(e.message);
    }
    await _store.removeWhere((k) => k.startsWith('u.${user.id}.'));
    await _api.clearSession();
  }

  @override
  bool get supportsPasswordReset => false;

  @override
  Future<void> requestPasswordReset(String email) async {
    throw const AuthException(
      'Şifre sıfırlama e-postası henüz desteklenmiyor. Şifrenizi unuttuysanız '
      'yöneticiye başvurun.',
    );
  }
}
