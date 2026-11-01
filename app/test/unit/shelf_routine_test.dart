import 'package:flutter_test/flutter_test.dart';
import 'package:skinsavvy_app/core/utils/date_utils.dart';
import 'package:skinsavvy_app/data/demo/demo_catalog.dart';
import 'package:skinsavvy_app/data/local/local_store.dart';
import 'package:skinsavvy_app/data/models/routine.dart';
import 'package:skinsavvy_app/data/models/shelf_item.dart';
import 'package:skinsavvy_app/state/review_controller.dart';
import 'package:skinsavvy_app/state/routine_controller.dart';
import 'package:skinsavvy_app/state/shelf_controller.dart';

import '../helpers.dart';

void main() {
  late LocalStore store;
  late ShelfController shelf;
  late RoutineController routine;

  setUp(() async {
    store = await emptyStore();
    shelf = ShelfController(store, 'u1');
    routine = RoutineController(store, 'u1', shelf);
  });

  tearDown(() {
    routine.dispose();
    shelf.dispose();
  });

  test('dolap ve rutin kalıcıdır (yeni örnek aynı veriyi okur)', () {
    final item = shelf.addProduct(demoCatalog.first);
    routine.addProduct(item.id, RoutineSlot.morning);

    final shelf2 = ShelfController(store, 'u1');
    final routine2 = RoutineController(store, 'u1', shelf2);
    expect(shelf2.using.single.name, demoCatalog.first.name);
    expect(routine2.entries(RoutineSlot.morning).single.shelfItemId, item.id);
  });

  test('kullanıcılar birbirinin verisini görmez', () {
    shelf.addProduct(demoCatalog.first);
    expect(ShelfController(store, 'u2').all, isEmpty);
    expect(ShelfController(store, null).all, isEmpty);
  });

  test('ürün bitirilince rutinden de kalkar', () {
    final item = shelf.addProduct(demoCatalog.first);
    routine.addProduct(item.id, RoutineSlot.morning);
    routine.addProduct(item.id, RoutineSlot.evening);

    shelf.finish(item.id, wouldRebuy: true, rating: 5, note: 'Harika');

    expect(shelf.finished.single.wouldRebuy, isTrue);
    expect(shelf.finished.single.remaining, 0);
    expect(routine.entries(RoutineSlot.morning), isEmpty);
    expect(routine.entries(RoutineSlot.evening), isEmpty);
  });

  test('aynı ürün aynı vakte iki kez eklenmez', () {
    final item = shelf.addProduct(demoCatalog.first);
    routine.addProduct(item.id, RoutineSlot.morning, weekdays: {1});
    routine.addProduct(item.id, RoutineSlot.morning);
    final entries = routine.entries(RoutineSlot.morning);
    expect(entries, hasLength(1));
    expect(entries.single.weekdays, RoutineEntry.allDays);
  });

  test('son gün kaldırılınca rutin adımı silinir', () {
    final item = shelf.addProduct(demoCatalog.first);
    routine.toggleWeekday(item.id, RoutineSlot.evening, 3);
    expect(routine.entryFor(item.id, RoutineSlot.evening)!.weekdays, {3});
    routine.toggleWeekday(item.id, RoutineSlot.evening, 3);
    expect(routine.entryFor(item.id, RoutineSlot.evening), isNull);
  });

  test(
    'alınacaklardan kullanmaya başlamak aynı kaydı günceller, bitmişten yeni kayıt açar',
    () {
      final wish = shelf.addProduct(
        demoCatalog[1],
        status: ShelfStatus.wishlist,
      );
      final started = shelf.startUsing(wish.id, usage: 'Sabah');
      expect(started.id, wish.id);
      expect(started.status, ShelfStatus.using);

      shelf.finish(wish.id, wouldRebuy: true);
      final again = shelf.startUsing(wish.id);
      expect(again.id, isNot(wish.id));
      expect(shelf.finished, hasLength(1));
      expect(shelf.using.single.id, again.id);
    },
  );

  group('seri ve tamamlama oranı', () {
    late RoutineEntry entry;
    final today = dateOnly(DateTime.now());
    DateTime ago(int d) => today.subtract(Duration(days: d));

    setUp(() {
      final item = shelf.addProduct(demoCatalog.first);
      entry = routine.addProduct(item.id, RoutineSlot.morning);
    });

    test('bugün henüz yapılmadıysa seri dünden sayılır', () {
      routine.toggleDone(entry.id, ago(1));
      routine.toggleDone(entry.id, ago(2));
      expect(routine.streak(DateTime.now()), 2);

      routine.toggleDone(entry.id, today);
      expect(routine.streak(DateTime.now()), 3);
    });

    test('atlanan gün seriyi bozar', () {
      routine.toggleDone(entry.id, ago(1));
      routine.toggleDone(entry.id, ago(3));
      expect(routine.streak(DateTime.now()), 1);
    });

    test('planı olmayan gün seriyi bozmaz', () {
      routine.toggleWeekday(
        shelf.using.single.id,
        RoutineSlot.morning,
        ago(2).weekday, // o günü plandan çıkar
      );
      routine.toggleDone(entry.id, ago(1));
      routine.toggleDone(entry.id, ago(3));
      expect(routine.streak(DateTime.now()), 2);
    });

    test('tamamlama oranı yapılan / planlanan', () {
      routine.toggleDone(entry.id, ago(1));
      expect(routine.completionRate(ago(3), ago(0)), closeTo(0.25, 1e-9));
    });
  });

  test('aynı ürüne ikinci yorum yenisini oluşturmaz, günceller', () {
    final reviews = ReviewController(store, 'u1');
    final item = shelf.addProduct(demoCatalog.first);
    reviews.save(item, rating: 4, comment: 'Gayet güzel bir temizleyici.');
    reviews.save(item, rating: 5, comment: 'Kullandıkça daha çok sevdim!');
    expect(reviews.count, 1);
    expect(reviews.all.single.rating, 5);
    expect(
      () => reviews.save(item, rating: 5, comment: 'kısa'),
      throwsArgumentError,
    );
  });
}
