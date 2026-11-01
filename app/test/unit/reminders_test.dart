import 'package:flutter_test/flutter_test.dart';
import 'package:skinsavvy_app/data/models/app_settings.dart';
import 'package:skinsavvy_app/data/models/routine.dart';
import 'package:skinsavvy_app/data/models/shelf_item.dart';
import 'package:skinsavvy_app/domain/reminders/reminders.dart';

final today = DateTime(2026, 3, 10, 9, 30);

ShelfItem item(
  String id, {
  DateTime? openedOn,
  int? paoMonths,
  DateTime? expiresOn,
  int remaining = 100,
  ShelfStatus status = ShelfStatus.using,
}) => ShelfItem(
  id: id,
  name: 'Ürün $id',
  brand: 'Demo',
  category: 'Serum',
  openedOn: openedOn,
  paoMonths: paoMonths,
  expiresOn: expiresOn,
  remaining: remaining,
  status: status,
);

List<Reminder> run(
  List<ShelfItem> items, {
  AppSettings settings = const AppSettings(),
  DateTime? now,
  List<SlotProgress> routine = const [],
}) => buildReminders(
  items: items,
  settings: settings,
  now: now ?? today,
  routine: routine,
);

void main() {
  group('geçerli son kullanma sınırı', () {
    test('PAO, SKT\'den önce dolarsa PAO esas alınır', () {
      final info = expiryInfo(
        item(
          'a',
          openedOn: DateTime(2026, 1, 1),
          paoMonths: 6,
          expiresOn: DateTime(2028, 1, 1),
        ),
      )!;
      expect(info.date, DateTime(2026, 7, 1));
      expect(info.fromPao, isTrue);
    });

    test('SKT daha yakınsa SKT esas alınır', () {
      final info = expiryInfo(
        item(
          'a',
          openedOn: DateTime(2026, 1, 1),
          paoMonths: 12,
          expiresOn: DateTime(2026, 5, 1),
        ),
      )!;
      expect(info.date, DateTime(2026, 5, 1));
      expect(info.fromPao, isFalse);
    });

    test('açılmamış üründe yalnızca SKT; hiçbiri yoksa null', () {
      expect(
        expiryInfo(
          item('a', paoMonths: 6, expiresOn: DateTime(2026, 9, 1)),
        )!.fromPao,
        isFalse,
      );
      expect(expiryInfo(item('b')), isNull);
    });

    test('ay sonu taşması: 31 Ağustos + 6 ay = 28 Şubat', () {
      final info = expiryInfo(
        item('a', openedOn: DateTime(2025, 8, 31), paoMonths: 6),
      )!;
      expect(info.date, DateTime(2026, 2, 28));
    });
  });

  group('ürün hatırlatmaları', () {
    test('süresi dolan, yaklaşan ve uzak ürünler', () {
      final r = run([
        item('dolmus', expiresOn: DateTime(2026, 3, 1)),
        item('yakin', expiresOn: DateTime(2026, 3, 20)),
        item('bugun', expiresOn: DateTime(2026, 3, 10)),
        item('uzak', expiresOn: DateTime(2026, 12, 1)),
      ]);
      expect(r.map((x) => x.key), [
        'expired:dolmus',
        'expiresSoon:bugun',
        'expiresSoon:yakin',
      ]);
      expect(r[0].daysLeft, -9);
      expect(r[1].title, 'Ürün bugun bugün son gün');
      expect(r[2].title, 'Ürün yakin: 10 gün kaldı');
      expect(r.every((x) => x.urgent), isTrue);
    });

    test('uyarı gün sayısı ayardan gelir', () {
      final items = [item('a', expiresOn: DateTime(2026, 3, 25))];
      expect(
        run(items, settings: const AppSettings(expiryWarningDays: 7)),
        isEmpty,
      );
      expect(
        run(items, settings: const AppSettings(expiryWarningDays: 15)),
        hasLength(1),
      );
    });

    test('ayar kapalıysa son kullanma ve azalma hatırlatılmaz', () {
      final items = [item('a', expiresOn: DateTime(2026, 3, 1), remaining: 5)];
      expect(
        run(
          items,
          settings: const AppSettings(expiryWarning: false, lowStock: false),
        ),
        isEmpty,
      );
    });

    test('bitmek üzere olan ürün acil sayılmaz, sonda listelenir', () {
      final r = run([
        item('az', remaining: 10),
        item('dolmus', expiresOn: DateTime(2026, 3, 1)),
      ]);
      expect(r.last.kind, ReminderKind.lowStock);
      expect(r.last.urgent, isFalse);
      expect(r.last.detail, contains('%10'));
    });

    test('istek listesi ve bitmiş ürünler yok sayılır', () {
      expect(
        run([
          item(
            'w',
            expiresOn: DateTime(2026, 3, 1),
            status: ShelfStatus.wishlist,
          ),
          item('f', remaining: 0, status: ShelfStatus.finished),
        ]),
        isEmpty,
      );
    });
  });

  group('rutin hatırlatmaları', () {
    const pending = (slot: RoutineSlot.morning, done: 1, total: 3);

    test('saati geçmiş ve tamamlanmamış rutin hatırlatılır', () {
      final r = run(const [], routine: [pending]);
      expect(r.single.kind, ReminderKind.routineDue);
      expect(r.single.detail, contains('2 adım'));
    });

    test('saati gelmeden ya da tamamlanınca hatırlatılmaz', () {
      expect(
        run(const [], now: DateTime(2026, 3, 10, 7, 59), routine: [pending]),
        isEmpty,
      );
      expect(
        run(
          const [],
          routine: [(slot: RoutineSlot.morning, done: 3, total: 3)],
        ),
        isEmpty,
      );
    });

    test('sabah rutini öğleden sonra hatırlatılmaz, akşam saatinde akşam', () {
      final evening = DateTime(2026, 3, 10, 21, 15);
      final r = run(
        const [],
        now: evening,
        routine: [pending, (slot: RoutineSlot.evening, done: 0, total: 2)],
      );
      expect(r.single.slot, RoutineSlot.evening);
    });

    test('rutin hatırlatması kapatılabilir', () {
      expect(
        run(
          const [],
          settings: const AppSettings(morningEnabled: false),
          routine: [pending],
        ),
        isEmpty,
      );
    });
  });
}
