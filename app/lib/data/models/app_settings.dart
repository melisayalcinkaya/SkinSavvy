import 'json.dart';

class AppSettings {
  const AppSettings({
    this.morningEnabled = true,
    this.morningTime = '08:00',
    this.eveningEnabled = true,
    this.eveningTime = '21:00',
    this.productApproval = true,
    this.expiryWarning = true,
    this.expiryWarningDays = 30,
    this.lowStock = true,
  });

  final bool morningEnabled;
  final String morningTime;
  final bool eveningEnabled;
  final String eveningTime;
  final bool productApproval;
  final bool expiryWarning;

  /// Son kullanma tarihinden kaç gün önce uyarılsın.
  final int expiryWarningDays;
  final bool lowStock;

  AppSettings copyWith({
    bool? morningEnabled,
    String? morningTime,
    bool? eveningEnabled,
    String? eveningTime,
    bool? productApproval,
    bool? expiryWarning,
    int? expiryWarningDays,
    bool? lowStock,
  }) => AppSettings(
    morningEnabled: morningEnabled ?? this.morningEnabled,
    morningTime: morningTime ?? this.morningTime,
    eveningEnabled: eveningEnabled ?? this.eveningEnabled,
    eveningTime: eveningTime ?? this.eveningTime,
    productApproval: productApproval ?? this.productApproval,
    expiryWarning: expiryWarning ?? this.expiryWarning,
    expiryWarningDays: expiryWarningDays ?? this.expiryWarningDays,
    lowStock: lowStock ?? this.lowStock,
  );

  Map<String, dynamic> toJson() => {
    'morningEnabled': morningEnabled,
    'morningTime': morningTime,
    'eveningEnabled': eveningEnabled,
    'eveningTime': eveningTime,
    'productApproval': productApproval,
    'expiryWarning': expiryWarning,
    'expiryWarningDays': expiryWarningDays,
    'lowStock': lowStock,
  };

  factory AppSettings.fromJson(Map<String, dynamic> j) {
    const d = AppSettings();
    return AppSettings(
      morningEnabled: asBool(j['morningEnabled'], d.morningEnabled),
      morningTime: asString(j['morningTime']) ?? d.morningTime,
      eveningEnabled: asBool(j['eveningEnabled'], d.eveningEnabled),
      eveningTime: asString(j['eveningTime']) ?? d.eveningTime,
      productApproval: asBool(j['productApproval'], d.productApproval),
      expiryWarning: asBool(j['expiryWarning'], d.expiryWarning),
      expiryWarningDays: asInt(j['expiryWarningDays'], d.expiryWarningDays),
      lowStock: asBool(j['lowStock'], d.lowStock),
    );
  }
}
