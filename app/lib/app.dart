import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'data/local/local_store.dart';
import 'data/remote/api_client.dart';
import 'router.dart';
import 'state/catalog_controller.dart';
import 'state/decision_sync.dart';
import 'state/tips_controller.dart';
import 'state/review_controller.dart';
import 'state/routine_controller.dart';
import 'state/session_controller.dart';
import 'state/settings_controller.dart';
import 'state/shelf_controller.dart';

class SkinSavvyApp extends StatefulWidget {
  const SkinSavvyApp({
    super.key,
    required this.store,
    required this.session,
    this.api,
  });

  final LocalStore store;
  final SessionController session;

  /// Sunucu modunda API istemcisi; cihaz modunda null.
  final ApiClient? api;

  @override
  State<SkinSavvyApp> createState() => _SkinSavvyAppState();
}

class _SkinSavvyAppState extends State<SkinSavvyApp> {
  late final GoRouter _router = buildRouter(widget.session);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  /// Kullanıcı değişince denetleyicinin yenisi oluşturulur; aynı kullanıcı
  /// için (ör. ad değişikliği) mevcut örnek korunur.
  ChangeNotifierProxyProvider<SessionController, T>
  _perUser<T extends ChangeNotifier>(
    T Function(String? uid) create,
    String? Function(T) uidOf,
  ) => ChangeNotifierProxyProvider<SessionController, T>(
    create: (_) => create(widget.session.user?.id),
    update: (_, session, previous) =>
        previous != null && uidOf(previous) == session.user?.id
        ? previous
        : create(session.user?.id),
  );

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final api = widget.api;
    return MultiProvider(
      providers: [
        Provider.value(value: store),
        Provider<ApiClient?>.value(value: api),
        ChangeNotifierProvider.value(value: widget.session),
        _perUser<SettingsController>(
          (uid) => SettingsController(store, uid),
          (c) => c.uid,
        ),
        _perUser<ShelfController>(
          (uid) => ShelfController(store, uid),
          (c) => c.uid,
        ),
        _perUser<TipsController>(
          (uid) => TipsController(store, uid),
          (c) => c.uid,
        ),
        _perUser<ReviewController>(
          (uid) => ReviewController(store, uid, api: api),
          (c) => c.uid,
        ),
        // Katalog, puanları kullanıcının yorumlarıyla birlikte hesaplar ve
        // yöneticiyse onay kuyruğunu da yükler.
        ChangeNotifierProxyProvider2<
          SessionController,
          ReviewController,
          CatalogController
        >(
          create: (context) => CatalogController(
            store,
            widget.session.user?.id,
            api: api,
            isAdmin: widget.session.user?.isAdmin ?? false,
            reviews: context.read<ReviewController>(),
          ),
          update: (_, session, reviews, previous) =>
              previous != null &&
                  previous.uid == session.user?.id &&
                  previous.isAdmin == (session.user?.isAdmin ?? false) &&
                  identical(previous.reviews, reviews)
              ? previous
              : CatalogController(
                  store,
                  session.user?.id,
                  api: api,
                  isAdmin: session.user?.isAdmin ?? false,
                  reviews: reviews,
                ),
        ),
        // Ekip kararlarını önerenin dolabına ve yorumlarına yansıtır.
        ProxyProvider3<
          CatalogController,
          ShelfController,
          ReviewController,
          DecisionSync
        >(
          lazy: false,
          update: (_, catalog, shelf, reviews, previous) {
            if (previous != null &&
                identical(previous.catalog, catalog) &&
                identical(previous.shelf, shelf) &&
                identical(previous.reviews, reviews)) {
              return previous;
            }
            previous?.dispose();
            return DecisionSync(catalog, shelf, reviews);
          },
          dispose: (_, sync) => sync.dispose(),
        ),
        ChangeNotifierProxyProvider2<
          SessionController,
          ShelfController,
          RoutineController
        >(
          create: (context) => RoutineController(
            store,
            widget.session.user?.id,
            context.read<ShelfController>(),
          ),
          update: (_, session, shelf, previous) =>
              previous != null &&
                  previous.uid == session.user?.id &&
                  identical(previous.shelf, shelf)
              ? previous
              : RoutineController(store, session.user?.id, shelf),
        ),
      ],
      child: MaterialApp.router(
        title: 'SkinSavvy',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: _router,
        locale: const Locale('tr', 'TR'),
        supportedLocales: const [Locale('tr', 'TR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
      ),
    );
  }
}
