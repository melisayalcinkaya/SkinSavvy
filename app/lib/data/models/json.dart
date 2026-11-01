// JSON'dan güvenli okuma yardımcıları. Bozuk ya da eski sürüm verisi
// uygulamayı çökertmesin diye tip uyuşmazlığında varsayılan döner.

String? asString(Object? v) => v is String ? v : null;

int asInt(Object? v, [int fallback = 0]) => v is num ? v.toInt() : fallback;

double? asDouble(Object? v) => v is num ? v.toDouble() : null;

bool asBool(Object? v, [bool fallback = false]) => v is bool ? v : fallback;

List<String> asStringList(Object? v) =>
    v is List ? v.whereType<String>().toList() : const [];

DateTime? asDate(Object? v) => v is String ? DateTime.tryParse(v) : null;

Map<String, dynamic> asMap(Object? v) =>
    v is Map ? v.map((k, value) => MapEntry('$k', value)) : <String, dynamic>{};

T asEnum<T extends Enum>(List<T> values, Object? v, T fallback) =>
    values.firstWhere((e) => e.name == v, orElse: () => fallback);
