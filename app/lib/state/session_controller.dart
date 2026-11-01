import 'package:flutter/foundation.dart';

import '../core/utils/text_utils.dart';
import '../data/models/user.dart';
import '../data/repositories/auth_repository.dart';

/// Oturum durumu. Yönlendirici bunu dinler: kullanıcı yoksa giriş ekranına,
/// karşılama akışını bitirmediyse oraya yönlendirir.
class SessionController extends ChangeNotifier {
  SessionController(this._auth);

  final AuthRepository _auth;
  AppUser? _user;
  bool _ready = false;

  AppUser? get user => _user;
  bool get isSignedIn => _user != null;
  bool get isReady => _ready;
  bool get supportsPasswordReset => _auth.supportsPasswordReset;

  Future<void> restore() async {
    _user = await _auth.restoreSession();
    _ready = true;
    notifyListeners();
  }

  Future<void> signIn(String email, String password) =>
      _set(_auth.signIn(email, password));

  Future<void> signUp(String name, String email, String password) =>
      _set(_auth.signUp(name, email, password));

  Future<void> signInDemo() => _set(_auth.signInDemo());

  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    notifyListeners();
  }

  Future<void> requestPasswordReset(String email) =>
      _auth.requestPasswordReset(email);

  Future<void> updateProfile({
    String? name,
    String? email,
    String? bio,
    String? avatar,
  }) {
    final current = _require();
    return _set(
      _auth.saveUser(
        current.copyWith(
          name: name == null ? null : sanitizeInput(name),
          email: email?.trim().toLowerCase(),
          bio: bio == null ? null : sanitizeInput(bio),
          avatar: avatar,
        ),
      ),
    );
  }

  Future<void> removeAvatar() =>
      _set(_auth.saveUser(_require().copyWith(clearAvatar: true)));

  /// Karşılama akışı bitince ve "Cilt Profilim" düzenlenince çağrılır.
  Future<void> saveSkinProfile(
    SkinProfile profile, {
    bool completeOnboarding = false,
  }) {
    final current = _require();
    return _set(
      _auth.saveUser(
        current.copyWith(
          skinProfile: profile,
          onboarded: completeOnboarding ? true : null,
        ),
      ),
    );
  }

  Future<void> deleteAccount() async {
    await _auth.deleteAccount(_require());
    _user = null;
    notifyListeners();
  }

  AppUser _require() {
    final current = _user;
    if (current == null) throw const AuthException('Oturum bulunamadı.');
    return current;
  }

  Future<void> _set(Future<AppUser> pending) async {
    _user = await pending;
    notifyListeners();
  }
}
