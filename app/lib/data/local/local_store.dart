import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences üzerinde JSON okuyup yazan ince katman.
///
/// Web'de tarayıcının localStorage'ına, Android/iOS'ta platformun anahtar-değer
/// deposuna yazar. Okuma eşzamanlıdır (veriler açılışta belleğe yüklenir),
/// yazma arka planda tamamlanır.
class LocalStore {
  LocalStore(this._prefs);

  final SharedPreferences _prefs;

  Object? read(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } on FormatException {
      return null; // Bozuk kayıt uygulamayı çökertmesin.
    }
  }

  Future<void> write(String key, Object? value) => value == null
      ? _prefs.remove(key)
      : _prefs.setString(key, jsonEncode(value));

  Future<void> remove(String key) => _prefs.remove(key);

  Future<void> removeWhere(bool Function(String key) test) async {
    for (final key in _prefs.getKeys().where(test).toList()) {
      await _prefs.remove(key);
    }
  }
}
