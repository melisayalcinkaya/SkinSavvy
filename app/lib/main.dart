import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/local/local_store.dart';
import 'data/repositories/auth_repository.dart';
import 'state/session_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = LocalStore(await SharedPreferences.getInstance());
  final session = SessionController(LocalAuthRepository(store));
  await session.restore();
  runApp(SkinSavvyApp(store: store, session: session));
}
