import 'package:flutter_test/flutter_test.dart';
import 'package:skinsavvy_app/data/demo/demo_catalog.dart';
import 'package:skinsavvy_app/data/models/routine.dart';
import 'package:skinsavvy_app/data/models/shelf_item.dart';
import 'package:skinsavvy_app/data/models/user.dart';
import 'package:skinsavvy_app/domain/ingredients/ingredient_analyzer.dart';
import 'package:skinsavvy_app/domain/ingredients/ingredient_db.dart';
import 'package:skinsavvy_app/domain/ingredients/routine_advisor.dart';

const analyzer = IngredientAnalyzer();

Iterable<String> titles(IngredientAnalysis a, FindingLevel level) =>
    a.findings.where((f) => f.level == level).map((f) => f.title);

ShelfItem item(
  String id,
  String name,
  List<String> ingredients, {
  String category = 'Serum',
}) => ShelfItem(
  id: id,
  name: name,
  brand: 'Demo',
  category: category,
  ingredients: ingredients,
);

void main() {
  group('içerik eşleştirme', () {
    test('INCI yazım farklarını tanır', () {
      expect(lookupIngredient('Aqua')?.id, 'water');
      expect(lookupIngredient('Glycerin.')?.id, 'glycerin');
      expect(lookupIngredient('SODIUM HYALURONATE')?.id, 'hyaluronic');
      expect(lookupIngredient('Parfum (Fragrance)')?.id, 'parfum');
      expect(
        lookupIngredient('Cocos Nucifera (Coconut) Oil')?.id,
        'coconut-oil',
      );
      expect(lookupIngredient('Ceramide NP')?.id, 'ceramide');
      expect(lookupIngredient('Methylparaben')?.id, 'paraben');
      expect(
        lookupIngredient('Lavandula Angustifolia Oil')?.id,
        'essential-oil',
      );
    });

    test('bilinmeyen içerik null döner, uydurma eşleşme yapmaz', () {
      expect(lookupIngredient('Xylitylglucoside'), isNull);
      expect(lookupIngredient(''), isNull);
    });

    test('yağ alkolü kurutucu alkol sayılmaz', () {
      final cetyl = lookupIngredient('Cetearyl Alcohol')!;
      expect(cetyl.tags, contains(IngredientTag.fattyAlcohol));
      expect(cetyl.tags, isNot(contains(IngredientTag.dryingAlcohol)));
    });
  });

  group('profile göre analiz', () {
    test('profildeki alerjen ürünü "uygun değil" yapar', () {
      final a = analyzer.analyze([
        'Aqua',
        'Glycerin',
        'Parfum',
        'Linalool',
      ], const SkinProfile(allergens: {'Parfüm / Fragrance'}));
      expect(a.verdict, Verdict.unsuitable);
      final avoid = a.findings.firstWhere((f) => f.level == FindingLevel.avoid);
      expect(avoid.ingredients, ['Parfum', 'Linalool']);
      expect(a.entries.where((e) => e.flagged).length, 2);
    });

    test('elle yazılan alerjen de yakalanır (Türkçe harf duyarsız)', () {
      final a = analyzer.analyze([
        'Aqua',
        'Propolis Extract',
        'Glycerin',
      ], const SkinProfile(allergens: {'propolis'}));
      expect(a.hasAvoid, isTrue);
    });

    test('hassas ciltte parfüm uyarı, normal ciltte bilgi notudur', () {
      const ing = ['Aqua', 'Glycerin', 'Parfum'];
      final sensitive = analyzer.analyze(
        ing,
        const SkinProfile(skinType: 'Hassas Cilt'),
      );
      final normal = analyzer.analyze(
        ing,
        const SkinProfile(skinType: 'Normal Cilt'),
      );
      expect(sensitive.verdict, Verdict.caution);
      expect(
        titles(normal, FindingLevel.info),
        contains('Parfüm / koku bileşeni'),
      );
      expect(normal.warnings, isEmpty);
    });

    test('alkol yalnızca listenin başındaysa uyarır', () {
      const profile = SkinProfile(skinType: 'Kuru Cilt');
      final high = analyzer.analyze([
        'Alcohol Denat.',
        'Aqua',
        'Glycerin',
      ], profile);
      final low = analyzer.analyze([
        'Aqua',
        'Glycerin',
        'Niacinamide',
        'Panthenol',
        'Allantoin',
        'Alcohol',
      ], profile);
      expect(
        titles(high, FindingLevel.caution),
        contains('Yüksek oranda alkol'),
      );
      expect(
        titles(low, FindingLevel.caution),
        isNot(contains('Yüksek oranda alkol')),
      );
    });

    test('akneye eğilimli ciltte komedojen içerik uyarısı', () {
      final a = analyzer.analyze([
        'Aqua',
        'Isopropyl Myristate',
        'Glycerin',
      ], const SkinProfile(concerns: {'Sivilce / Akne'}));
      expect(titles(a, FindingLevel.caution), contains('Gözenek tıkayabilir'));
      final dry = analyzer.analyze([
        'Aqua',
        'Isopropyl Myristate',
        'Glycerin',
      ], const SkinProfile(skinType: 'Kuru Cilt'));
      expect(
        titles(dry, FindingLevel.caution),
        isNot(contains('Gözenek tıkayabilir')),
      );
    });

    test('endişeye iyi gelen içerikler olumlu bulgu olur', () {
      final a = analyzer.analyze([
        'Aqua',
        'Niacinamide',
        'Zinc PCA',
      ], const SkinProfile(concerns: {'Sivilce / Akne', 'Gözenek'}));
      expect(a.verdict, Verdict.suitable);
      expect(titles(a, FindingLevel.positive), contains('Sivilce için iyi'));
      expect(a.score, greaterThan(0));
    });

    test('güneş filtresi olmayan asitli üründe SPF notu', () {
      final a = analyzer.analyze([
        'Aqua',
        'Glycolic Acid',
        'Glycerin',
      ], const SkinProfile());
      expect(titles(a, FindingLevel.info), contains('Güneş hassasiyeti'));
    });

    test('boş içerik listesi nötr sonuç verir', () {
      final a = analyzer.analyze(const [], const SkinProfile());
      expect(a.verdict, Verdict.neutral);
      expect(a.findings, isEmpty);
    });

    test('demo kataloğundaki her ürünün içeriklerinin çoğu tanınır', () {
      for (final p in demoCatalog) {
        final a = analyzer.analyze(p.ingredients, const SkinProfile());
        expect(
          a.knownCount / a.entries.length,
          greaterThanOrEqualTo(0.6),
          reason:
              '${p.name}: ${a.entries.where((e) => !e.isKnown).map((e) => e.raw)}',
        );
      }
    });
  });

  group('rutin danışmanı', () {
    final retinol = item('ret', 'Retinol Serum', [
      'Aqua',
      'Retinol',
      'Squalane',
    ]);
    final bha = item('bha', 'BHA Tonik', ['Aqua', 'Salicylic Acid']);
    final aha = item('aha', 'AHA Tonik', ['Aqua', 'Glycolic Acid']);
    final vitC = item('c', 'C Serum', ['Aqua', 'Ascorbic Acid']);
    final spf = item('spf', 'SPF 50', [
      'Aqua',
      'Zinc Oxide',
    ], category: 'Güneş Kremi');
    final byId = {
      for (final i in [retinol, bha, aha, vitC, spf]) i.id: i,
    };

    List<RoutineWarning> review(List<RoutineEntry> entries) =>
        const RoutineAdvisor().review(entries, (id) => byId[id]);

    RoutineEntry entry(String id, RoutineSlot slot, [Set<int>? days]) =>
        RoutineEntry(
          id: 'e-$id-${slot.name}',
          shelfItemId: id,
          slot: slot,
          weekdays: days ?? RoutineEntry.allDays,
        );

    test('aynı akşam retinoid + asit: yalnızca ortak günler raporlanır', () {
      final w = review([
        entry('ret', RoutineSlot.evening),
        entry('bha', RoutineSlot.evening, {1, 3, 5}),
        entry('spf', RoutineSlot.morning),
      ]);
      final clash = w.singleWhere(
        (x) => x.title == 'Retinoid ve asit aynı vakitte',
      );
      expect(clash.weekdays, {1, 3, 5});
      expect(clash.products, ['Retinol Serum', 'BHA Tonik']);
      expect(clash.level, FindingLevel.caution);
    });

    test('farklı günlere dağıtılınca uyarı kalkar', () {
      final w = review([
        entry('ret', RoutineSlot.evening, {2, 4, 6}),
        entry('bha', RoutineSlot.evening, {1, 3, 5}),
        entry('spf', RoutineSlot.morning),
      ]);
      expect(w, isEmpty);
    });

    test('iki asit aynı vakitte tek uyarı üretir', () {
      final w = review([
        entry('bha', RoutineSlot.evening),
        entry('aha', RoutineSlot.evening),
        entry('spf', RoutineSlot.morning),
      ]);
      expect(w.where((x) => x.title == 'Birden fazla peeling ürünü').length, 1);
    });

    test('sabah retinoid ve eksik SPF uyarılır', () {
      final w = review([entry('ret', RoutineSlot.morning)]);
      expect(
        w.map((x) => x.title),
        containsAll(['Retinoid sabah rutininde', 'Sabah güneş kremi eksik']),
      );
    });

    test('akşam güneş kremi bilgi notu, uyarılar önce sıralanır', () {
      final w = review([
        entry('spf', RoutineSlot.evening),
        entry('ret', RoutineSlot.morning),
      ]);
      expect(w.last.title, 'Akşam güneş kremi');
      expect(w.first.level, FindingLevel.caution);
    });

    test('içerik listesi olmayan üründe ada bakılır', () {
      final named = item('n', 'Retinol Gece Kremi', const []);
      expect(productTags(named), contains(IngredientTag.retinoid));
    });

    test('dolapta olmayan ürünün adımı yok sayılır', () {
      expect(review([entry('silinmis', RoutineSlot.evening)]), isEmpty);
    });
  });
}
