import 'package:flutter/foundation.dart';

import '../data/local/keys.dart';
import '../data/local/local_store.dart';
import '../data/models/json.dart';

/// Oturumdaki kullanıcıya ait verileri tutan denetleyicilerin ortak tabanı.
///
/// Kullanıcı değişince (çıkış/giriş) sağlayıcı yeni bir örnek oluşturur;
/// böylece bir hesabın verisi asla diğerine karışmaz. `uid` null ise
/// (oturum yok) denetleyici boş çalışır ve hiçbir şey yazmaz.
abstract class UserStore extends ChangeNotifier {
  UserStore(this.store, this.uid);

  final LocalStore store;
  final String? uid;

  Object? readValue(String name) =>
      uid == null ? null : store.read(StoreKeys.user(uid!, name));

  List<Map<String, dynamic>> readList(String name) {
    final value = readValue(name);
    return value is List ? value.map(asMap).toList() : <Map<String, dynamic>>[];
  }

  void writeValue(String name, Object? value) {
    if (uid == null) return;
    store.write(StoreKeys.user(uid!, name), value);
  }
}
