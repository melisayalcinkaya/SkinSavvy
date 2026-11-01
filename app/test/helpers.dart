import 'package:shared_preferences/shared_preferences.dart';
import 'package:skinsavvy_app/data/local/local_store.dart';
import 'package:skinsavvy_app/data/repositories/auth_repository.dart';

/// Boş bir bellek içi SharedPreferences ile LocalStore.
Future<LocalStore> emptyStore([Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues(values);
  return LocalStore(await SharedPreferences.getInstance());
}

/// Testlerde PBKDF2 tur sayısı düşük tutulur (hız için).
LocalAuthRepository fastAuth(LocalStore store) =>
    LocalAuthRepository(store, iterations: 200);
