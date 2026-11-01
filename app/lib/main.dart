import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/local/local_store.dart';
import 'data/remote/api_client.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/remote_auth_repository.dart';
import 'state/session_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = LocalStore(await SharedPreferences.getInstance());
  // API_URL verilmezse her şey cihazda çalışır (GitHub Pages demosu böyle).
  final api = apiUrl.isEmpty ? null : ApiClient(apiUrl, store);
  final session = SessionController(
    api == null ? LocalAuthRepository(store) : RemoteAuthRepository(api, store),
  );
  await session.restore();
  runApp(SkinSavvyApp(store: store, session: session, api: api));
}
