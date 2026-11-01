import 'json.dart';

enum RoutineSlot { morning, evening }

/// Rutindeki bir adım: dolaptaki bir ürünün hangi vakitte ve haftanın
/// hangi günlerinde kullanılacağı.
class RoutineEntry {
  const RoutineEntry({
    required this.id,
    required this.shelfItemId,
    required this.slot,
    this.weekdays = allDays,
    this.order = 0,
  });

  /// DateTime.weekday: Pazartesi = 1 ... Pazar = 7.
  static const allDays = {1, 2, 3, 4, 5, 6, 7};

  final String id;
  final String shelfItemId;
  final RoutineSlot slot;
  final Set<int> weekdays;
  final int order;

  bool appliesOn(DateTime day) => weekdays.contains(day.weekday);

  RoutineEntry copyWith({Set<int>? weekdays, int? order}) => RoutineEntry(
    id: id,
    shelfItemId: shelfItemId,
    slot: slot,
    weekdays: weekdays ?? this.weekdays,
    order: order ?? this.order,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'shelfItemId': shelfItemId,
    'slot': slot.name,
    'weekdays': weekdays.toList()..sort(),
    'order': order,
  };

  factory RoutineEntry.fromJson(Map<String, dynamic> j) => RoutineEntry(
    id: asString(j['id']) ?? '',
    shelfItemId: asString(j['shelfItemId']) ?? '',
    slot: asEnum(RoutineSlot.values, j['slot'], RoutineSlot.morning),
    weekdays:
        (j['weekdays'] is List
                ? (j['weekdays'] as List).whereType<num>().map((e) => e.toInt())
                : allDays)
            .where((d) => d >= 1 && d <= 7)
            .toSet(),
    order: asInt(j['order']),
  );
}
