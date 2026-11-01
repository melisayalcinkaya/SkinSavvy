import '../core/utils/date_utils.dart';
import '../core/utils/ids.dart';
import '../data/local/keys.dart';
import '../data/models/json.dart';
import '../data/models/routine.dart';
import '../data/models/shelf_item.dart';
import 'shelf_controller.dart';
import 'user_store.dart';

/// Sabah/akşam rutinleri ve günlük tamamlama kaydı.
///
/// Dolabı dinler: bir ürün bitirilir ya da silinirse rutindeki adımı da
/// kendiliğinden kalkar.
class RoutineController extends UserStore {
  RoutineController(super.store, super.uid, this.shelf) {
    _entries = readList(
      StoreKeys.routine,
    ).map(RoutineEntry.fromJson).where((e) => e.id.isNotEmpty).toList();
    final raw = asMap(readValue(StoreKeys.completions));
    _done = {for (final e in raw.entries) e.key: asStringList(e.value).toSet()};
    shelf.addListener(_pruneMissingProducts);
    _pruneMissingProducts();
  }

  final ShelfController shelf;
  List<RoutineEntry> _entries = [];
  Map<String, Set<String>> _done = {};

  /// Kayıt şişmesin diye bu kadar günden eski tamamlama bilgisi silinir.
  static const historyDays = 120;

  List<RoutineEntry> entries(RoutineSlot slot) =>
      _entries.where((e) => e.slot == slot).toList()
        ..sort((a, b) => a.order.compareTo(b.order));

  /// O gün uygulanacak adımlar (haftanın gününe göre).
  List<RoutineEntry> entriesOn(RoutineSlot slot, DateTime day) =>
      entries(slot).where((e) => e.appliesOn(day)).toList();

  List<RoutineEntry> scheduledOn(DateTime day) =>
      _entries.where((e) => e.appliesOn(day)).toList();

  RoutineEntry? entryFor(String shelfItemId, RoutineSlot slot) {
    for (final e in _entries) {
      if (e.shelfItemId == shelfItemId && e.slot == slot) return e;
    }
    return null;
  }

  bool isDone(String entryId, DateTime day) =>
      _done[dateKey(day)]?.contains(entryId) ?? false;

  int doneCount(RoutineSlot slot, DateTime day) =>
      entriesOn(slot, day).where((e) => isDone(e.id, day)).length;

  void toggleDone(String entryId, DateTime day) {
    final key = dateKey(day);
    final set = {...?_done[key]};
    set.contains(entryId) ? set.remove(entryId) : set.add(entryId);
    _done = {..._done, key: set};
    _save();
  }

  /// Ürünü rutine ekler. Zaten ekliyse günlerini "her gün" yapar.
  RoutineEntry addProduct(
    String shelfItemId,
    RoutineSlot slot, {
    Set<int>? weekdays,
  }) {
    final existing = entryFor(shelfItemId, slot);
    if (existing != null) {
      final updated = existing.copyWith(
        weekdays: weekdays ?? RoutineEntry.allDays,
      );
      _replace(updated);
      return updated;
    }
    final entry = RoutineEntry(
      id: newId('r'),
      shelfItemId: shelfItemId,
      slot: slot,
      weekdays: weekdays ?? RoutineEntry.allDays,
      order: entries(slot).length,
    );
    _entries = [..._entries, entry];
    _save();
    return entry;
  }

  /// Rutin düzenleyicideki gün kutucuğu.
  void toggleWeekday(String shelfItemId, RoutineSlot slot, int weekday) {
    final existing = entryFor(shelfItemId, slot);
    if (existing == null) {
      addProduct(shelfItemId, slot, weekdays: {weekday});
      return;
    }
    final days = {...existing.weekdays};
    days.contains(weekday) ? days.remove(weekday) : days.add(weekday);
    days.isEmpty
        ? removeEntry(existing.id)
        : _replace(existing.copyWith(weekdays: days));
  }

  void removeEntry(String id) {
    _entries = _entries.where((e) => e.id != id).toList();
    _save();
  }

  /// Planlanan her adımı tamamlanmış art arda gün sayısı. Bugün henüz
  /// bitmediyse seri bozulmuş sayılmaz; dünden geriye sayılır.
  int streak(DateTime now) {
    var day = dateOnly(now);
    if (!_isComplete(day)) day = day.subtract(const Duration(days: 1));
    var count = 0;
    for (var i = 0; i < historyDays; i++) {
      final scheduled = scheduledOn(day);
      if (scheduled.isEmpty) {
        day = day.subtract(const Duration(days: 1));
        continue; // Planı olmayan gün seriyi bozmaz.
      }
      if (!_isComplete(day)) break;
      count++;
      day = day.subtract(const Duration(days: 1));
    }
    return count;
  }

  /// [from]–[to] (dahil) aralığında yapılan adımların planlananlara oranı.
  /// Plan yoksa null.
  double? completionRate(DateTime from, DateTime to) {
    var planned = 0;
    var done = 0;
    for (
      var d = dateOnly(from);
      !d.isAfter(dateOnly(to));
      d = d.add(const Duration(days: 1))
    ) {
      final scheduled = scheduledOn(d);
      planned += scheduled.length;
      done += scheduled.where((e) => isDone(e.id, d)).length;
    }
    return planned == 0 ? null : done / planned;
  }

  /// Toplam işaretlenen adım sayısı ("toplam kullanım").
  int get totalCompletions => _done.values.fold(0, (sum, s) => sum + s.length);

  bool _isComplete(DateTime day) {
    final scheduled = scheduledOn(day);
    return scheduled.isNotEmpty && scheduled.every((e) => isDone(e.id, day));
  }

  void _replace(RoutineEntry entry) {
    _entries = [for (final e in _entries) e.id == entry.id ? entry : e];
    _save();
  }

  void _pruneMissingProducts() {
    final before = _entries.length;
    _entries = _entries
        .where((e) => shelf.byId(e.shelfItemId)?.status == ShelfStatus.using)
        .toList();
    if (_entries.length != before) _save();
  }

  void _save() {
    final cutoff = dateKey(
      DateTime.now().subtract(const Duration(days: historyDays)),
    );
    _done.removeWhere(
      (key, value) => value.isEmpty || key.compareTo(cutoff) < 0,
    );
    writeValue(StoreKeys.routine, _entries.map((e) => e.toJson()).toList());
    writeValue(StoreKeys.completions, {
      for (final e in _done.entries) e.key: e.value.toList(),
    });
    notifyListeners();
  }

  @override
  void dispose() {
    shelf.removeListener(_pruneMissingProducts);
    super.dispose();
  }
}
