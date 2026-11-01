import '../../data/models/routine.dart';
import '../../data/models/shelf_item.dart';
import 'ingredient_analyzer.dart';
import 'ingredient_db.dart';

/// Rutinde birlikte kullanılan ürünlerin oluşturduğu riskler.
class RoutineWarning {
  const RoutineWarning(
    this.level,
    this.title,
    this.detail, {
    this.slot,
    this.weekdays = const {},
    this.products = const [],
  });

  final FindingLevel level;
  final String title;
  final String detail;
  final RoutineSlot? slot;

  /// Çakışmanın olduğu günler (1 = Pazartesi). Boşsa günden bağımsız.
  final Set<int> weekdays;
  final List<String> products;
}

/// İçerik listesi girilmemiş ürünlerde addan çıkarılan etiketler.
/// Kelime sınırı kullanılır: "ahududu" AHA sayılmasın.
final _nameHints = <IngredientTag, RegExp>{
  IngredientTag.retinoid: RegExp(r'\b(retinol|retinal)\b'),
  IngredientTag.aha: RegExp(r'\b(aha|glikolik|glycolic)\b'),
  IngredientTag.bha: RegExp(r'\b(bha|salisilik|salicylic)\b'),
  IngredientTag.vitaminC: RegExp(r'\b(c vitamini|vitamin c)\b'),
  IngredientTag.uvFilter: RegExp(r'\bspf\b'),
};

/// Ürünün içerik etiketleri. İçerik listesi yoksa ürün adına bakılır
/// ("Retinol Gece Serumu" gibi).
Set<IngredientTag> productTags(ShelfItem item) {
  final tags = <IngredientTag>{
    for (final raw in item.ingredients) ...?lookupIngredient(raw)?.tags,
  };
  if (item.ingredients.isEmpty) {
    final name = item.name.toLowerCase();
    for (final MapEntry(key: tag, value: pattern) in _nameHints.entries) {
      if (pattern.hasMatch(name)) tags.add(tag);
    }
    if (item.category == 'Güneş Kremi') tags.add(IngredientTag.uvFilter);
  }
  return tags;
}

class RoutineAdvisor {
  const RoutineAdvisor();

  /// [entries] rutin adımları, [lookup] adımın ürününü verir.
  List<RoutineWarning> review(
    List<RoutineEntry> entries,
    ShelfItem? Function(String id) lookup,
  ) {
    final steps = <(RoutineEntry, ShelfItem, Set<IngredientTag>)>[
      for (final e in entries)
        if (lookup(e.shelfItemId) case final item?)
          (e, item, productTags(item)),
    ];
    final warnings = <RoutineWarning>[];

    // Aynı vakitte, aynı günlerde birlikte kullanılan iki ürün.
    void pair(
      Set<IngredientTag> a,
      Set<IngredientTag> b,
      FindingLevel level,
      String title,
      String detail,
    ) {
      for (final slot in RoutineSlot.values) {
        final inSlot = steps.where((s) => s.$1.slot == slot).toList();
        for (var i = 0; i < inSlot.length; i++) {
          for (var j = 0; j < inSlot.length; j++) {
            if (i == j) continue;
            final (ea, ia, ta) = inSlot[i];
            final (eb, ib, tb) = inSlot[j];
            // Aynı çift iki kez raporlanmasın.
            if (identical(a, b) && j < i) continue;
            if (!ta.any(a.contains) || !tb.any(b.contains)) continue;
            final days = ea.weekdays.intersection(eb.weekdays);
            if (days.isEmpty) continue;
            warnings.add(
              RoutineWarning(
                level,
                title,
                detail,
                slot: slot,
                weekdays: days,
                products: [ia.name, ib.name],
              ),
            );
          }
        }
      }
    }

    const retinoid = {IngredientTag.retinoid};
    const acids = {IngredientTag.aha, IngredientTag.bha};
    pair(
      retinoid,
      acids,
      FindingLevel.caution,
      'Retinoid ve asit aynı vakitte',
      'Birlikte kullanıldığında kızarıklık ve soyulma riski artar. Asidi ve retinoidi farklı akşamlara dağıt.',
    );
    pair(
      retinoid,
      {IngredientTag.benzoylPeroxide},
      FindingLevel.caution,
      'Retinoid ve benzoil peroksit',
      'Benzoil peroksit retinolü bozabilir ve tahrişi artırır; farklı vakitlerde kullan.',
    );
    pair(
      acids,
      acids,
      FindingLevel.caution,
      'Birden fazla peeling ürünü',
      'Aynı vakitte iki asitli ürün cildi aşırı soyabilir; birini başka güne al.',
    );
    pair(
      {IngredientTag.vitaminC},
      retinoid,
      FindingLevel.info,
      'C vitamini ve retinoid aynı vakitte',
      'Yaygın öneri C vitaminini sabah, retinoidi akşam kullanmaktır.',
    );

    // Sabah kullanılan retinoid.
    for (final (e, item, tags) in steps) {
      if (e.slot == RoutineSlot.morning &&
          tags.contains(IngredientTag.retinoid)) {
        warnings.add(
          RoutineWarning(
            FindingLevel.caution,
            'Retinoid sabah rutininde',
            'Retinoidler güneş ışığında bozulur ve cildi duyarlı hâle getirir; akşam rutinine taşı.',
            slot: RoutineSlot.morning,
            weekdays: e.weekdays,
            products: [item.name],
          ),
        );
      }
    }

    // Asit/retinoid var ama sabah güneş kremi yok.
    final photosensitizers = steps
        .where((s) => s.$3.any({...retinoid, ...acids}.contains))
        .toList();
    final hasMorningSpf = steps.any(
      (s) =>
          s.$1.slot == RoutineSlot.morning &&
          s.$3.contains(IngredientTag.uvFilter),
    );
    if (photosensitizers.isNotEmpty && !hasMorningSpf) {
      warnings.add(
        RoutineWarning(
          FindingLevel.caution,
          'Sabah güneş kremi eksik',
          'Rutininde cildi güneşe duyarlı hâle getiren ürünler var; sabah rutinine SPF ekle.',
          slot: RoutineSlot.morning,
          products: [for (final s in photosensitizers) s.$2.name],
        ),
      );
    }

    // Akşam güneş kremi gereksiz.
    for (final (e, item, tags) in steps) {
      if (e.slot == RoutineSlot.evening &&
          tags.contains(IngredientTag.uvFilter) &&
          item.category == 'Güneş Kremi') {
        warnings.add(
          RoutineWarning(
            FindingLevel.info,
            'Akşam güneş kremi',
            'Güneş kremi gündüz korur; akşam rutininde gerek yok.',
            slot: RoutineSlot.evening,
            products: [item.name],
          ),
        );
      }
    }

    warnings.sort((a, b) => a.level.index.compareTo(b.level.index));
    return warnings;
  }
}
