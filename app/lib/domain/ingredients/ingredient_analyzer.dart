import '../../core/utils/text_utils.dart';
import '../../data/models/user.dart';
import 'ingredient_db.dart';

enum FindingLevel {
  /// Profilde kaçınılacak olarak işaretlenmiş madde var.
  avoid,

  /// Profile göre dikkat edilmesi gereken bir durum.
  caution,

  /// Bilgi amaçlı not.
  info,

  /// Endişelere/cilt tipine iyi gelen içerik.
  positive,
}

class Finding {
  const Finding(
    this.level,
    this.title,
    this.detail, [
    this.ingredients = const [],
  ]);

  final FindingLevel level;
  final String title;
  final String detail;
  final List<String> ingredients;
}

enum Verdict { unsuitable, caution, suitable, neutral }

/// Bir içerik satırının analizi.
class IngredientEntry {
  const IngredientEntry(
    this.raw,
    this.position,
    this.info, {
    this.flagged = false,
  });

  final String raw;

  /// INCI listesinde sırası (0'dan). Liste derişime göre sıralandığı için
  /// ilk sıralardaki maddeler üründe daha yüksek orandadır.
  final int position;
  final IngredientInfo? info;

  /// Profildeki bir alerjene denk geliyor mu?
  final bool flagged;

  bool get isKnown => info != null;
}

class IngredientAnalysis {
  const IngredientAnalysis(this.entries, this.findings);

  final List<IngredientEntry> entries;
  final List<Finding> findings;

  Iterable<Finding> get warnings => findings.where(
    (f) => f.level == FindingLevel.avoid || f.level == FindingLevel.caution,
  );

  Iterable<Finding> get positives =>
      findings.where((f) => f.level == FindingLevel.positive);

  int get knownCount => entries.where((e) => e.isKnown).length;

  bool get hasAvoid => findings.any((f) => f.level == FindingLevel.avoid);

  Verdict get verdict {
    if (entries.isEmpty) return Verdict.neutral;
    if (hasAvoid) return Verdict.unsuitable;
    if (findings.any((f) => f.level == FindingLevel.caution)) {
      return Verdict.caution;
    }
    if (positives.isNotEmpty) return Verdict.suitable;
    return Verdict.neutral;
  }

  /// Öneri sıralaması için basit puan: uyumlu içerikler artı, uyarılar eksi.
  int get score =>
      positives.length * 2 -
      findings.where((f) => f.level == FindingLevel.caution).length * 2 -
      (hasAvoid ? 100 : 0);
}

/// Profildeki alerjen etiketlerinin içerik etiketlerine karşılığı.
const allergenTags = <String, Set<IngredientTag>>{
  'Parfüm / Fragrance': {IngredientTag.fragrance},
  'Alkol': {IngredientTag.dryingAlcohol},
  'Retinol': {IngredientTag.retinoid},
  'Niacinamide': {IngredientTag.niacinamide},
  'Salisilik Asit': {IngredientTag.bha},
  'Lanolin': {IngredientTag.lanolin},
  'Sülfat': {IngredientTag.sulfate},
  'Paraben': {IngredientTag.paraben},
  'Propilen Glikol': {IngredientTag.propyleneGlycol},
};

/// Cilt endişelerine iyi gelen içerik grupları.
const concernHelpers = <String, Set<IngredientTag>>{
  'Sivilce / Akne': {
    IngredientTag.bha,
    IngredientTag.niacinamide,
    IngredientTag.zinc,
    IngredientTag.azelaicAcid,
    IngredientTag.benzoylPeroxide,
    IngredientTag.retinoid,
  },
  'Leke / Renk Eşitsizliği': {
    IngredientTag.vitaminC,
    IngredientTag.niacinamide,
    IngredientTag.aha,
    IngredientTag.azelaicAcid,
    IngredientTag.retinoid,
  },
  'Kırışıklık / Anti-Aging': {
    IngredientTag.retinoid,
    IngredientTag.peptide,
    IngredientTag.vitaminC,
    IngredientTag.antioxidant,
  },
  'Gözenek': {IngredientTag.bha, IngredientTag.niacinamide, IngredientTag.clay},
  'Nemsizlik': {IngredientTag.humectant, IngredientTag.ceramide},
};

/// Komedojen puanı bu değer ve üstündeyse "gözenek tıkayabilir" uyarısı.
const comedogenicThreshold = 3;

/// İlk kaç içerik "yüksek oranda" sayılır (kaba bir yaklaşım: INCI listesi
/// %1'in üzerindeki maddeleri derişime göre sıralar).
const highConcentrationPositions = 5;

class IngredientAnalyzer {
  const IngredientAnalyzer();

  IngredientAnalysis analyze(List<String> ingredients, SkinProfile profile) {
    final customAllergens = profile.allergens
        .where((a) => !allergenTags.containsKey(a))
        .map(searchKey)
        .where((a) => a.length >= 2)
        .toList();
    final avoidTags = {for (final a in profile.allergens) ...?allergenTags[a]};

    bool hitsAllergen(String raw, IngredientInfo? info) =>
        (info != null && info.tags.any(avoidTags.contains)) ||
        customAllergens.any((a) => searchKey(raw).contains(a));

    final entries = <IngredientEntry>[];
    for (var i = 0; i < ingredients.length; i++) {
      final info = lookupIngredient(ingredients[i]);
      entries.add(
        IngredientEntry(
          ingredients[i],
          i,
          info,
          flagged: hitsAllergen(ingredients[i], info),
        ),
      );
    }
    if (entries.isEmpty) return const IngredientAnalysis([], []);

    List<String> withTag(IngredientTag tag, {int? before}) => [
      for (final e in entries)
        if (e.info?.tags.contains(tag) ?? false)
          if (before == null || e.position < before) e.raw,
    ];

    final skin = profile.skinType;
    final sensitive = skin == 'Hassas Cilt';
    final dry = skin == 'Kuru Cilt';
    final oily = skin == 'Yağlı Cilt' || skin == 'Karma Cilt';
    final acneProne =
        profile.concerns.contains('Sivilce / Akne') ||
        profile.concerns.contains('Gözenek');
    final findings = <Finding>[];

    // 1) Profilde kaçınılacak olarak işaretlenen maddeler.
    for (final allergen in profile.allergens) {
      final tags = allergenTags[allergen];
      final hits = tags == null
          ? [
              for (final e in entries)
                if (searchKey(e.raw).contains(searchKey(allergen))) e.raw,
            ]
          : [
              for (final e in entries)
                if (e.info?.tags.any(tags.contains) ?? false) e.raw,
            ];
      if (hits.isNotEmpty) {
        findings.add(
          Finding(
            FindingLevel.avoid,
            '${allergen.split(' / ').first} içeriyor',
            'Cilt profilinde kaçınılacak olarak işaretlediğin bir madde bu üründe var.',
            hits,
          ),
        );
      }
    }

    // 2) Profile göre dikkat.
    if (!avoidTags.contains(IngredientTag.fragrance)) {
      final scent = withTag(IngredientTag.fragrance);
      if (scent.isNotEmpty && sensitive) {
        findings.add(
          Finding(
            FindingLevel.caution,
            'Parfüm / koku bileşeni',
            'Koku bileşenleri hassas ciltlerde en sık tahriş nedenlerindendir.',
            scent,
          ),
        );
      } else if (scent.isNotEmpty) {
        findings.add(
          Finding(
            FindingLevel.info,
            'Parfüm / koku bileşeni',
            'Ürün koku bileşeni içeriyor; kızarıklık olursa kullanımı bırak.',
            scent,
          ),
        );
      }
    }
    if (!avoidTags.contains(IngredientTag.dryingAlcohol)) {
      final alcohol = withTag(
        IngredientTag.dryingAlcohol,
        before: highConcentrationPositions,
      );
      if (alcohol.isNotEmpty && (dry || sensitive)) {
        findings.add(
          Finding(
            FindingLevel.caution,
            'Yüksek oranda alkol',
            'Listenin başlarında kurutucu alkol var; kuru ya da hassas ciltte gerginlik yapabilir.',
            alcohol,
          ),
        );
      }
    }
    final pore = [
      for (final e in entries)
        if ((e.info?.comedogenic ?? 0) >= comedogenicThreshold) e.raw,
    ];
    if (pore.isNotEmpty && (acneProne || oily)) {
      findings.add(
        Finding(
          FindingLevel.caution,
          'Gözenek tıkayabilir',
          'Komedojen puanı yüksek içerik var; sivilceye ya da yağlanmaya eğilimli ciltte dikkatli kullan.',
          pore,
        ),
      );
    }
    final actives = [
      ...withTag(IngredientTag.retinoid),
      ...withTag(IngredientTag.aha),
      ...withTag(IngredientTag.bha),
    ];
    if (actives.isNotEmpty && sensitive) {
      findings.add(
        Finding(
          FindingLevel.caution,
          'Güçlü aktif içerik',
          'Hassas ciltte haftada 2-3 kullanımla başlayıp cildin alışmasını bekle.',
          actives,
        ),
      );
    }
    final sulfates = withTag(IngredientTag.sulfate);
    if (sulfates.isNotEmpty &&
        (dry || sensitive) &&
        !avoidTags.contains(IngredientTag.sulfate)) {
      findings.add(
        Finding(
          FindingLevel.caution,
          'Sert köpürtücü (sülfat)',
          'Sülfatlar kuru ve hassas ciltte bariyeri zayıflatabilir.',
          sulfates,
        ),
      );
    }
    if (actives.isNotEmpty && withTag(IngredientTag.uvFilter).isEmpty) {
      findings.add(
        const Finding(
          FindingLevel.info,
          'Güneş hassasiyeti',
          'Retinoid ve asitler cildi güneşe duyarlı hâle getirir; gündüz mutlaka SPF kullan.',
        ),
      );
    }

    // 3) İyi gelenler.
    for (final concern in profile.concerns) {
      final tags = concernHelpers[concern];
      if (tags == null) continue;
      final helpers = [
        for (final e in entries)
          if (e.info?.tags.any(tags.contains) ?? false) e.info!.name,
      ];
      if (helpers.isNotEmpty) {
        findings.add(
          Finding(
            FindingLevel.positive,
            '${concern.split(' / ').first} için iyi',
            '${helpers.toSet().join(', ')} bu endişede destekleyici içeriklerdendir.',
            helpers.toSet().toList(),
          ),
        );
      }
    }
    if (dry) {
      final barrier = [
        ...withTag(IngredientTag.ceramide),
        ...withTag(IngredientTag.humectant),
      ];
      if (barrier.isNotEmpty) {
        findings.add(
          Finding(
            FindingLevel.positive,
            'Kuru cilde uygun',
            'Nem ve bariyer destekleyen içerikler var.',
            barrier,
          ),
        );
      }
    }
    if (sensitive) {
      final calm = withTag(IngredientTag.soothing);
      if (calm.isNotEmpty) {
        findings.add(
          Finding(
            FindingLevel.positive,
            'Yatıştırıcı içerik',
            'Hassas cildi rahatlatan içerikler var.',
            calm,
          ),
        );
      }
    }

    return IngredientAnalysis(entries, findings);
  }
}
