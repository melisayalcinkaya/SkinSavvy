/// Kullanıcıya özel kayıt anahtarları. Hesap silinince `u.<id>.` önekiyle
/// başlayan her şey temizlenir.
abstract final class StoreKeys {
  static String user(String uid, String name) => 'u.$uid.$name';

  static const shelf = 'shelf';
  static const routine = 'routine';
  static const completions = 'completions';
  static const reviews = 'reviews';
  static const settings = 'settings';
  static const favorites = 'favorites';
  static const submissions = 'submissions';
}
