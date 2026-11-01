import '../data/local/keys.dart';
import '../data/models/app_settings.dart';
import '../data/models/json.dart';
import 'user_store.dart';

class SettingsController extends UserStore {
  SettingsController(super.store, super.uid) {
    _settings = AppSettings.fromJson(asMap(readValue(StoreKeys.settings)));
  }

  AppSettings _settings = const AppSettings();

  AppSettings get settings => _settings;

  void update(AppSettings settings) {
    _settings = settings;
    writeValue(StoreKeys.settings, settings.toJson());
    notifyListeners();
  }
}
