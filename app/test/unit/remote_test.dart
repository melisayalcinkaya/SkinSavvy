import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:skinsavvy_app/data/local/local_store.dart';
import 'package:skinsavvy_app/data/models/product.dart';
import 'package:skinsavvy_app/data/models/shelf_item.dart';
import 'package:skinsavvy_app/data/models/user.dart';
import 'package:skinsavvy_app/data/remote/api_client.dart';
import 'package:skinsavvy_app/data/repositories/auth_repository.dart';
import 'package:skinsavvy_app/data/repositories/remote_auth_repository.dart';
import 'package:skinsavvy_app/state/catalog_controller.dart';
import 'package:skinsavvy_app/state/review_controller.dart';

import '../helpers.dart';

/// Gerçek API'nin davranışını taklit eden küçük sahte sunucu.
class FakeServer {
  final requests = <http.Request>[];
  var accessVersion = 1;
  var refreshCalls = 0;
  var refreshAllowed = true;
  bool offline = false;
  final Map<String, Map<String, dynamic>> reviews = {};

  Map<String, dynamic> user({String email = 'ayse@test.dev'}) => {
    'id': 'u1',
    'name': 'Ayşe Yılmaz',
    'email': email,
    'bio': '',
    'avatar': null,
    'role': 'user',
    'skinProfile': {
      'skinType': 'Kuru Cilt',
      'concerns': ['Nemsizlik'],
      'allergens': <String>[],
      'intensity': null,
    },
    'onboarded': true,
    'createdAt': '2026-01-01T00:00:00Z',
  };

  Map<String, dynamic> tokens({String email = 'ayse@test.dev'}) => {
    'accessToken': 'access-$accessVersion',
    'refreshToken': 'refresh-$accessVersion-xxxxxxxxxxxxxxxx',
    'tokenType': 'bearer',
    'expiresIn': 900,
    'user': user(email: email),
  };

  static Map<String, dynamic> product(String id, String status) => {
    'id': id,
    'name': 'Ürün $id',
    'brand': 'Marka',
    'category': 'Serum',
    'imageUrl': '',
    'rating': 4.5,
    'reviewCount': 2,
    'ingredients': ['Aqua', 'Glycerin'],
    'benefits': <String>[],
    'skinTypes': ['Tüm Cilt Tipleri'],
    'description': '',
    'barcode': null,
    'status': status,
    'duplicateOf': status == 'duplicate' ? 'p-onayli' : null,
    'editedByTeam': false,
  };

  http.Response json(Object? body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  bool authorized(http.Request r) =>
      r.headers['Authorization'] == 'Bearer access-$accessVersion';

  Future<http.Response> handle(http.Request r) async {
    requests.add(r);
    if (offline) throw http.ClientException('ağ yok');
    final body = r.body.isEmpty ? null : jsonDecode(r.body);
    final route = '${r.method} ${r.url.path}';
    switch (route) {
      case 'POST /auth/login':
        if (!{'Dogru-sifre-1', 'demo-sifre-2026'}.contains(body['password'])) {
          return json({'detail': 'E-posta ya da şifre hatalı.'}, 401);
        }
        return json(tokens(email: body['email'] as String));
      case 'POST /auth/register':
        return json({
          'detail': [
            {'msg': 'Value error, Şifre en az 8 karakter olmalı.'},
          ],
        }, 422);
      case 'POST /auth/refresh':
        refreshCalls++;
        if (!refreshAllowed) return json({'detail': 'Oturum geçersiz.'}, 401);
        accessVersion++;
        return json(tokens());
      case 'POST /auth/logout':
        return http.Response('', 204);
    }
    if (!authorized(r) && !route.startsWith('GET /products')) {
      return json({'detail': 'Oturum geçersiz ya da süresi dolmuş.'}, 401);
    }
    switch (route) {
      case 'GET /me':
        return json(user());
      case 'PATCH /me':
        return json({...user(), ...body as Map<String, dynamic>});
      case 'DELETE /me':
        return http.Response('', 204);
      case 'GET /products':
        return json({
          'items': [
            product('p-onayli', 'approved'),
            product('p-bekleyen', 'pending'),
          ],
          'total': 2,
        });
      case 'GET /products/mine':
        return json([
          product('p-bekleyen', 'pending'),
          product('p-yinelenen', 'duplicate'),
          product('p-silinen', 'removed'),
        ]);
      case 'GET /admin/submissions':
        return json([product('p-bekleyen', 'pending')]);
      case 'GET /admin/products':
        return json([product('p-kaldirilan', 'delisted')]);
      case 'GET /products/p-eski':
        return json(product('p-eski', 'delisted'));
      case 'DELETE /products/p-bekleyen':
        decisions.add(('p-bekleyen', 'withdraw', null));
        return http.Response('', 204);
      case 'POST /products':
        if (body['name'] == 'Ürün p-onayli') {
          return json({
            'detail': 'Bu ürün zaten katalogda ya da onay bekliyor.',
          }, 409);
        }
        return json({
          ...product('p-yeni', 'pending'),
          'name': body['name'],
        }, 201);
    }
    final decision = RegExp(
      r'^POST /admin/submissions/([^/]+)/(approve|duplicate|remove)$',
    ).firstMatch(route);
    if (decision != null) {
      decisions.add((decision.group(1)!, decision.group(2)!, body));
      return json(product(decision.group(1)!, 'approved'));
    }
    final catalogOp = RegExp(
      r'^(PUT|POST) /admin/products/([^/]+?)(?:/(delist|relist))?$',
    ).firstMatch(route);
    if (catalogOp != null) {
      decisions.add((catalogOp.group(2)!, catalogOp.group(3) ?? 'edit', body));
      return json(product(catalogOp.group(2)!, 'approved'));
    }
    final review = RegExp(
      r'^(PUT|DELETE) /products/([^/]+)/reviews/me$',
    ).firstMatch(route);
    if (review != null) {
      final id = review.group(2)!;
      if (id == 'p-bekleyen') {
        return json({'detail': 'Onaylanmamış ürün.'}, 409);
      }
      if (review.group(1) == 'PUT') {
        reviews[id] = body as Map<String, dynamic>;
        return json({'id': 'r1'});
      }
      reviews.remove(id);
      return http.Response('', 204);
    }
    return json({'detail': 'Bulunamadı.'}, 404);
  }

  /// Ekip kararları: (öneri, karar, gövde).
  final decisions = <(String, String, Object?)>[];

  MockClient get client => MockClient((r) => handle(r));
}

void main() {
  late LocalStore store;
  late FakeServer server;
  late ApiClient api;
  late RemoteAuthRepository auth;

  setUp(() async {
    store = await emptyStore();
    server = FakeServer();
    api = ApiClient('https://api.test', store, client: server.client);
    auth = RemoteAuthRepository(api, store);
  });

  group('API istemcisi ve hesap', () {
    test(
      'giriş token saklar, kullanıcıyı eşler; yanlış şifre mesajı',
      () async {
        final user = await auth.signIn(' ayse@test.dev ', 'Dogru-sifre-1');
        expect(user.id, 'u1');
        expect(user.skinProfile.skinType, 'Kuru Cilt');
        expect(user.isDemo, isFalse);
        expect(api.refreshToken, startsWith('refresh-1'));
        expect(
          jsonDecode(server.requests.first.body)['email'],
          'ayse@test.dev',
        );

        await expectLater(
          auth.signIn('ayse@test.dev', 'yanlis'),
          throwsA(
            isA<AuthException>().having(
              (e) => e.message,
              'message',
              'E-posta ya da şifre hatalı.',
            ),
          ),
        );
      },
    );

    test('doğrulama hatasında sunucunun Türkçe mesajı gösterilir', () async {
      await expectLater(
        auth.signUp('Ayşe', 'a@test.dev', 'kisa'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Şifre en az 8 karakter olmalı.',
          ),
        ),
      );
    });

    test(
      'süresi dolan erişim token\'ı bir kez yenilenir, istek tekrarlanır',
      () async {
        await auth.signIn('ayse@test.dev', 'Dogru-sifre-1');
        server.accessVersion = 5; // sunucu eski token'ı artık kabul etmiyor
        final results = await Future.wait([api.get('/me'), api.get('/me')]);
        expect(results.map((r) => (r as Map)['id']), ['u1', 'u1']);
        // İki istek de 401 aldı ama tek yenileme yapıldı.
        expect(server.refreshCalls, 1);
      },
    );

    test('yenileme reddedilirse oturum temizlenir', () async {
      await auth.signIn('ayse@test.dev', 'Dogru-sifre-1');
      server
        ..accessVersion = 9
        ..refreshAllowed = false;
      await expectLater(api.get('/me'), throwsA(isA<ApiException>()));
      expect(api.hasSession, isFalse);
      expect(await auth.restoreSession(), isNull);
    });

    test(
      'bağlantı hatası durum 0 ile anlaşılır mesaj verir, oturum silinmez',
      () async {
        await auth.signIn('ayse@test.dev', 'Dogru-sifre-1');
        server.offline = true;
        await expectLater(
          api.get('/me'),
          throwsA(isA<ApiException>().having((e) => e.status, 'status', 0)),
        );
        expect(await api.refresh(), isFalse);
        expect(api.hasSession, isTrue);
      },
    );

    test('oturum geri yüklenir; profil kaydı PATCH ile gider', () async {
      await auth.signIn('ayse@test.dev', 'Dogru-sifre-1');
      final fresh = RemoteAuthRepository(
        ApiClient('https://api.test', store, client: server.client),
        store,
      );
      final user = (await fresh.restoreSession())!;
      expect(user.email, 'ayse@test.dev');

      final saved = await fresh.saveUser(
        user.copyWith(
          name: 'Ayşe Kaya',
          skinProfile: const SkinProfile(skinType: 'Hassas Cilt'),
        ),
      );
      expect(saved.name, 'Ayşe Kaya');
      final patch = server.requests.lastWhere((r) => r.method == 'PATCH');
      expect(
        jsonDecode(patch.body).keys,
        unorderedEquals(['name', 'bio', 'avatar', 'onboarded', 'skinProfile']),
      );
      expect(jsonDecode(patch.body)['skinProfile']['skinType'], 'Hassas Cilt');
    });

    test('demo girişi demo verisini bir kez yazar', () async {
      final user = await auth.signInDemo();
      expect(user.isDemo, isTrue);
      expect(store.read('u.u1.shelf'), isA<List>());
    });

    test('çıkış ve hesap silme', () async {
      final user = await auth.signIn('ayse@test.dev', 'Dogru-sifre-1');
      await store.write('u.u1.shelf', ['x']);
      await auth.deleteAccount(user);
      expect(store.read('u.u1.shelf'), isNull);
      expect(api.hasSession, isFalse);

      await auth.signIn('ayse@test.dev', 'Dogru-sifre-1');
      await auth.signOut();
      expect(server.requests.last.url.path, '/auth/logout');
      expect(api.hasSession, isFalse);
    });
  });

  group('sunucu modunda katalog', () {
    setUp(() => auth.signIn('ayse@test.dev', 'Dogru-sifre-1'));

    test('katalog ve önerilerin durumu sunucudan gelir', () async {
      final catalog = CatalogController(store, 'u1', api: api);
      expect(catalog.isLoading, isTrue);
      await catalog.reload();
      expect(catalog.products.map((p) => p.id), ['p-bekleyen', 'p-onayli']);
      // Yinelenen ve silinen öneriler katalogda yok; karar bildirimi için
      // önerilerim listesinde.
      expect(catalog.submissions.map((p) => p.status), [
        ProductStatus.pending,
        ProductStatus.duplicate,
        ProductStatus.removed,
      ]);
      expect(catalog.byId('p-yinelenen')!.duplicateOf, 'p-onayli');
      expect(catalog.unseenDecisions.map((p) => p.id), [
        'p-yinelenen',
        'p-silinen',
      ]);
      expect(catalog.contributionCount, 1);
      catalog.dispose();
    });

    test('ekip kararları doğru uç noktaya gider', () async {
      final catalog = CatalogController(store, 'u1', api: api, isAdmin: true);
      await catalog.reload();
      final p = catalog.reviewQueue.single;
      await catalog.approve(p.id);
      await catalog.approve(
        p.id,
        edited: p.copyWith(
          name: '  Düzeltilmiş <b>Ad</b> ',
          imageUrl: 'data:x',
        ),
      );
      await catalog.markDuplicate(p.id, 'p-onayli');
      await catalog.remove(p.id);
      expect(server.decisions.map((d) => d.$2), [
        'approve',
        'approve',
        'duplicate',
        'remove',
      ]);
      expect(server.decisions[0].$3, isNull);
      final edit = server.decisions[1].$3! as Map;
      expect(edit['name'], isNot(contains('<')));
      expect(edit['imageUrl'], 'data:x');
      expect(edit.keys, containsAll(['brand', 'skinTypes', 'ingredients']));
      expect(server.decisions[2].$3, {'originalId': 'p-onayli'});
      expect(server.decisions[3].$3, isNull);
      // Asıl ürün onaylı olmalı: istek gönderilmeden durdurulur.
      await expectLater(
        catalog.markDuplicate(p.id, 'p-yinelenen'),
        throwsStateError,
      );
      expect(server.decisions, hasLength(4));
      catalog.dispose();
    });

    test('yükleme hatası saklanır', () async {
      server.offline = true;
      final catalog = CatalogController(store, 'u1', api: api);
      await catalog.reload();
      expect(catalog.loadError, contains('bağlanılamadı'));
      expect(catalog.products, isEmpty);
      catalog.dispose();
    });

    test('öneri gönderilir; çakışmada sunucu mesajı', () async {
      final catalog = CatalogController(store, 'u1', api: api);
      await catalog.reload();
      final p = await catalog.submit(
        name: 'Gül Tonik',
        brand: 'Marka',
        category: 'Tonik',
        skinTypes: const ['Tüm Cilt Tipleri'],
        ingredients: const ['Aqua', 'Glycerin'],
        imageUrl: 'data:image/png;base64,iVBORw0KGgo=',
      );
      expect(p.status, ProductStatus.pending);
      expect(catalog.byId('p-yeni')?.name, 'Gül Tonik');
      final post = jsonDecode(
        server.requests.lastWhere((r) => r.method == 'POST').body,
      );
      expect(post['barcode'], isNull);

      await expectLater(
        catalog.submit(
          name: 'Ürün p-onayli',
          brand: 'Marka',
          category: 'Serum',
          skinTypes: const [],
          ingredients: const ['Aqua', 'Glycerin'],
          imageUrl: 'data:image/png;base64,iVBORw0KGgo=',
        ),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 409)),
      );
      catalog.dispose();
    });
  });

  group('sunucu modunda yorumlar', () {
    setUp(() => auth.signIn('ayse@test.dev', 'Dogru-sifre-1'));

    ShelfItem item(String productId) => ShelfItem(
      id: 's-$productId',
      productId: productId,
      name: 'Ürün',
      brand: 'Marka',
      category: 'Serum',
    );

    test('yorum sunucuya gönderilir ve silinir', () async {
      final reviews = ReviewController(store, 'u1', api: api);
      final r = reviews.save(
        item('p-onayli'),
        rating: 4,
        comment: 'Cildime çok iyi geldi.',
      );
      await reviews.sync();
      expect(server.reviews['p-onayli'], {
        'rating': 4,
        'comment': 'Cildime çok iyi geldi.',
      });

      reviews.delete(r.id);
      await reviews.sync();
      expect(server.reviews, isEmpty);
      expect(reviews.pendingSync, isEmpty);
    });

    test('gönderim sürerken silinen yorum sunucuda kalmaz', () async {
      final reviews = ReviewController(store, 'u1', api: api);
      final r = reviews.save(
        item('p-onayli'),
        rating: 2,
        comment: 'Yanlışlıkla yazdım bunu.',
      );
      // PUT yanıtı gelmeden sil.
      reviews.delete(r.id);
      await reviews.sync();
      expect(server.reviews, isEmpty);
      expect(
        server.requests
            .where((q) => q.url.path.endsWith('/reviews/me'))
            .map((q) => q.method),
        ['PUT', 'DELETE'],
      );
      expect(reviews.pendingSync, isEmpty);
    });

    test(
      'çevrimdışı yorum kuyrukta kalır, sonraki açılışta gönderilir',
      () async {
        server.offline = true;
        final reviews = ReviewController(store, 'u1', api: api);
        reviews.save(
          item('p-onayli'),
          rating: 5,
          comment: 'Harika bir nemlendirici.',
        );
        await reviews.sync();
        expect(reviews.pendingSync, {'p-onayli'});

        server.offline = false;
        final reopened = ReviewController(store, 'u1', api: api);
        await reopened.sync();
        expect(server.reviews['p-onayli']?['rating'], 5);
        expect(reopened.pendingSync, isEmpty);
      },
    );

    test('onay bekleyen ürüne yorum cihazda kalır, kuyruğu tıkamaz', () async {
      final reviews = ReviewController(store, 'u1', api: api);
      reviews.save(
        item('p-bekleyen'),
        rating: 3,
        comment: 'Henüz karar veremedim.',
      );
      await reviews.sync();
      expect(reviews.pendingSync, isEmpty);
      expect(reviews.forProduct('p-bekleyen'), isNotNull);
    });
  });

  group('sunucu modunda katalog işlemleri', () {
    setUp(() => auth.signIn('ayse@test.dev', 'Dogru-sifre-1'));

    test(
      'ekip düzenler, kaldırır, geri alır; kaldırılanlar listelenir',
      () async {
        final catalog = CatalogController(store, 'u1', api: api, isAdmin: true);
        await catalog.reload();
        expect(catalog.delisted.single.id, 'p-kaldirilan');
        expect(catalog.byId('p-kaldirilan')?.isDelisted, isTrue);

        final p = catalog.byId('p-onayli')!;
        await catalog.editProduct(p.id, p.copyWith(name: 'Yeni <i>Ad</i>'));
        await catalog.delist('p-onayli');
        await catalog.relist('p-kaldirilan');
        expect(server.decisions.map((d) => (d.$1, d.$2)), [
          ('p-onayli', 'edit'),
          ('p-onayli', 'delist'),
          ('p-kaldirilan', 'relist'),
        ]);
        expect(
          (server.decisions.first.$3! as Map)['name'],
          isNot(contains('<')),
        );
        catalog.dispose();
      },
    );

    test('listede olmayan ürün bir kez sunucudan getirilir', () async {
      final catalog = CatalogController(store, 'u1', api: api);
      await catalog.reload();
      expect(catalog.byId('p-eski'), isNull);
      expect(await catalog.ensureLoaded('p-eski'), isTrue);
      expect(catalog.byId('p-eski')?.isDelisted, isTrue);
      expect(await catalog.ensureLoaded('p-yok'), isFalse);
      expect(catalog.fetchTried('p-yok'), isTrue);
      catalog.dispose();
    });

    test('kullanıcı bekleyen önerisini geri çeker', () async {
      final catalog = CatalogController(store, 'u1', api: api);
      await catalog.reload();
      await catalog.withdraw('p-bekleyen');
      expect(server.decisions.single.$2, 'withdraw');
      expect(catalog.submissions.any((p) => p.id == 'p-bekleyen'), isFalse);
      // Kararı verilmiş öneri için istek gönderilmez.
      await expectLater(catalog.withdraw('p-yinelenen'), throwsStateError);
      expect(server.decisions, hasLength(1));
      catalog.dispose();
    });
  });
}
