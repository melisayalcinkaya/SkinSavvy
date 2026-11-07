import '../data/models/json.dart';
import 'user_store.dart';

/// Kullanıcıya bir kez gösterilen tanıtım ipuçları (ör. "ürünü sen ekle").
/// Kapatılan ipucu o hesapta bir daha çıkmaz.
class TipsController extends UserStore {
  TipsController(super.store, super.uid) {
    _seen = asStringList(readValue(_key)).toSet();
  }

  static const _key = 'tipsSeen';

  /// Ürünler sekmesindeki "katalog seninle büyüyor" kartı.
  static const addProduct = 'addProduct';

  Set<String> _seen = {};

  bool isSeen(String id) => _seen.contains(id);

  void dismiss(String id) {
    if (!_seen.add(id)) return;
    writeValue(_key, _seen.toList());
    notifyListeners();
  }
}
