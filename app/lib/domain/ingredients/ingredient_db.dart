/// Sık karşılaşılan kozmetik içeriklerin (INCI) küçük bilgi tabanı.
///
/// Amaç tıbbi değerlendirme değil, kullanıcıya "bu madde ne işe yarar, profiline
/// göre neye dikkat etmeli" sorusunda yol göstermek. Gözenek tıkama (komedojen)
/// puanları literatürde sık atıf yapılan 0–5 ölçeğinden alınmıştır; bu ölçek
/// saf madde testlerine dayanır ve ürünün tamamındaki etkiyi birebir göstermez.
library;

enum IngredientTag {
  fragrance,
  fragranceAllergen,
  essentialOil,
  dryingAlcohol,
  fattyAlcohol,
  retinoid,
  aha,
  bha,
  pha,
  vitaminC,
  niacinamide,
  humectant,
  ceramide,
  peptide,
  antioxidant,
  soothing,
  uvFilter,
  sulfate,
  paraben,
  lanolin,
  propyleneGlycol,
  silicone,
  emollient,
  benzoylPeroxide,
  azelaicAcid,
  zinc,
  clay,
  preservative,
}

class IngredientInfo {
  const IngredientInfo(
    this.id,
    this.name,
    this.function, {
    this.aliases = const [],
    this.patterns = const [],
    this.tags = const {},
    this.comedogenic = 0,
  });

  final String id;

  /// Kullanıcıya gösterilen ad.
  final String name;

  /// Kısa Türkçe açıklama: "Nem çeker", "Ölü hücreleri arındırır"…
  final String function;

  /// Normalleştirilmiş tam eşleşme adları (küçük harf, parantezsiz).
  final List<String> aliases;

  /// Tam ad tutmadığında denenecek düzenli ifadeler.
  final List<String> patterns;
  final Set<IngredientTag> tags;

  /// 0 (tıkamaz) – 5 (yüksek).
  final int comedogenic;
}

/// Bilgi tabanı. Sıra önemli değildir; arama dizini aşağıda kurulur.
const ingredientDb = <IngredientInfo>[
  // ── Nem ve bariyer ─────────────────────────────────────────
  IngredientInfo(
    'water',
    'Su',
    'Çözücü; formülün temelidir.',
    aliases: ['aqua', 'water', 'eau'],
  ),
  IngredientInfo(
    'glycerin',
    'Gliserin',
    'Nem çeker ve cildi yumuşatır.',
    aliases: ['glycerin', 'glycerine'],
    tags: {IngredientTag.humectant},
  ),
  IngredientInfo(
    'hyaluronic',
    'Hyaluronik asit',
    'Ağırlığının çok katı kadar su tutar; dolgunluk ve nem sağlar.',
    aliases: [
      'sodium hyaluronate',
      'hyaluronic acid',
      'hydrolyzed hyaluronic acid',
      'sodium acetylated hyaluronate',
    ],
    tags: {IngredientTag.humectant},
  ),
  IngredientInfo(
    'panthenol',
    'Panthenol (B5)',
    'Nemlendirir, tahrişi yatıştırır.',
    aliases: ['panthenol', 'd-panthenol', 'dexpanthenol'],
    tags: {IngredientTag.humectant, IngredientTag.soothing},
  ),
  IngredientInfo(
    'ceramide',
    'Seramid',
    'Cilt bariyerinin yapı taşı; nem kaybını azaltır.',
    patterns: [r'^ceramide\b'],
    tags: {IngredientTag.ceramide},
  ),
  IngredientInfo(
    'cholesterol',
    'Kolesterol',
    'Seramidlerle birlikte bariyeri onarır.',
    aliases: ['cholesterol'],
    tags: {IngredientTag.ceramide},
  ),
  IngredientInfo(
    'squalane',
    'Skualan',
    'Hafif, cilde benzeyen bir yağ; nem kaybını azaltır.',
    aliases: ['squalane'],
    tags: {IngredientTag.emollient},
    comedogenic: 1,
  ),
  IngredientInfo(
    'urea',
    'Üre',
    'Nem çeker; kuru ve pürüzlü ciltte yumuşatır.',
    aliases: ['urea'],
    tags: {IngredientTag.humectant},
  ),
  IngredientInfo(
    'allantoin',
    'Allantoin',
    'Yatıştırır, cilt yenilenmesini destekler.',
    aliases: ['allantoin'],
    tags: {IngredientTag.soothing},
  ),
  IngredientInfo(
    'butylene-glycol',
    'Bütilen glikol',
    'Nem çeker, içeriklerin cilde yayılmasına yardım eder.',
    aliases: ['butylene glycol'],
    tags: {IngredientTag.humectant},
  ),
  IngredientInfo(
    'propanediol',
    'Propanediol',
    'Nem çeker, çözücü.',
    aliases: ['propanediol'],
  ),
  IngredientInfo(
    'pentylene-glycol',
    'Pentilen glikol',
    'Nem çeker, koruyucuya destek olur.',
    aliases: ['pentylene glycol'],
  ),
  IngredientInfo(
    'propylene-glycol',
    'Propilen glikol',
    'Nem çeker; bazı kişilerde hassasiyet yapabilir.',
    aliases: ['propylene glycol'],
    tags: {IngredientTag.humectant, IngredientTag.propyleneGlycol},
  ),

  // ── Yağlar, yumuşatıcılar ─────────────────────────────────
  IngredientInfo(
    'shea',
    'Shea yağı',
    'Besler ve yumuşatır.',
    aliases: [
      'butyrospermum parkii butter',
      'butyrospermum parkii (shea) butter',
      'shea butter',
    ],
    tags: {IngredientTag.emollient},
  ),
  IngredientInfo(
    'coconut-oil',
    'Hindistan cevizi yağı',
    'Besleyici yağ; yağlı/akneye eğilimli ciltte gözenek tıkayabilir.',
    aliases: [
      'cocos nucifera oil',
      'coconut oil',
      'cocos nucifera (coconut) oil',
    ],
    tags: {IngredientTag.emollient},
    comedogenic: 4,
  ),
  IngredientInfo(
    'cocoa-butter',
    'Kakao yağı',
    'Yoğun besleyici; gözenek tıkayabilir.',
    aliases: ['theobroma cacao seed butter', 'cocoa butter'],
    tags: {IngredientTag.emollient},
    comedogenic: 4,
  ),
  IngredientInfo(
    'olive-oil',
    'Zeytinyağı',
    'Besleyici yağ.',
    aliases: ['olea europaea fruit oil', 'olive oil'],
    tags: {IngredientTag.emollient},
    comedogenic: 2,
  ),
  IngredientInfo(
    'sunflower-oil',
    'Ayçiçek yağı',
    'Linoleik asitten zengin hafif yağ.',
    aliases: ['helianthus annuus seed oil', 'sunflower seed oil'],
    tags: {IngredientTag.emollient},
  ),
  IngredientInfo(
    'jojoba',
    'Jojoba yağı',
    'Sebuma benzer hafif yağ.',
    aliases: ['simmondsia chinensis seed oil', 'jojoba oil'],
    tags: {IngredientTag.emollient},
    comedogenic: 2,
  ),
  IngredientInfo(
    'wheat-germ',
    'Buğday özü yağı',
    'Besleyici; gözenek tıkama eğilimi yüksek.',
    aliases: ['triticum vulgare germ oil', 'wheat germ oil'],
    tags: {IngredientTag.emollient},
    comedogenic: 5,
  ),
  IngredientInfo(
    'caprylic-triglyceride',
    'Kaprilik/kaprik trigliserit',
    'Hafif yumuşatıcı yağ.',
    aliases: ['caprylic/capric triglyceride', 'caprylic capric triglyceride'],
    tags: {IngredientTag.emollient},
    comedogenic: 1,
  ),
  IngredientInfo(
    'isopropyl-myristate',
    'İzopropil miristat',
    'Dokuyu hafifletir; gözenek tıkama eğilimi yüksektir.',
    aliases: ['isopropyl myristate'],
    tags: {IngredientTag.emollient},
    comedogenic: 5,
  ),
  IngredientInfo(
    'isopropyl-palmitate',
    'İzopropil palmitat',
    'Yumuşatıcı; gözenek tıkayabilir.',
    aliases: ['isopropyl palmitate'],
    tags: {IngredientTag.emollient},
    comedogenic: 4,
  ),
  IngredientInfo(
    'myristyl-myristate',
    'Miristil miristat',
    'Kıvam verici; gözenek tıkama eğilimi yüksek.',
    aliases: ['myristyl myristate'],
    tags: {IngredientTag.emollient},
    comedogenic: 5,
  ),
  IngredientInfo(
    'laureth-4',
    'Laureth-4',
    'Emülgatör; gözenek tıkayabilir.',
    aliases: ['laureth-4'],
    comedogenic: 5,
  ),
  IngredientInfo(
    'mineral-oil',
    'Mineral yağ',
    'Kapatıcı; nem kaybını önler.',
    aliases: ['paraffinum liquidum', 'mineral oil'],
    tags: {IngredientTag.emollient},
  ),
  IngredientInfo(
    'petrolatum',
    'Vazelin',
    'Güçlü kapatıcı; nemi hapseder.',
    aliases: ['petrolatum'],
    tags: {IngredientTag.emollient},
  ),
  IngredientInfo(
    'dimethicone',
    'Dimetikon',
    'Silikon; pürüzsüz his verir, nemi korur.',
    aliases: ['dimethicone', 'cyclopentasiloxane', 'cyclomethicone'],
    tags: {IngredientTag.silicone},
    comedogenic: 1,
  ),
  IngredientInfo(
    'fatty-alcohol',
    'Yağ alkolü',
    'Kıvam verici ve yumuşatıcı; kurutmaz.',
    aliases: [
      'cetearyl alcohol',
      'cetyl alcohol',
      'stearyl alcohol',
      'behenyl alcohol',
    ],
    tags: {IngredientTag.fattyAlcohol, IngredientTag.emollient},
    comedogenic: 2,
  ),
  IngredientInfo(
    'lanolin',
    'Lanolin',
    'Koyun yününden elde edilen besleyici yağ; bazı kişilerde alerji yapar.',
    aliases: ['lanolin', 'lanolin alcohol', 'acetylated lanolin'],
    tags: {IngredientTag.lanolin, IngredientTag.emollient},
    comedogenic: 2,
  ),

  // ── Aktifler ──────────────────────────────────────────────
  IngredientInfo(
    'retinol',
    'Retinol',
    'A vitamini türevi; hücre yenilenmesini hızlandırır, ince çizgi ve lekelerde etkilidir.',
    aliases: [
      'retinol',
      'retinal',
      'retinaldehyde',
      'retinyl palmitate',
      'retinyl retinoate',
      'hydroxypinacolone retinoate',
      'tretinoin',
      'adapalene',
    ],
    tags: {IngredientTag.retinoid},
  ),
  IngredientInfo(
    'glycolic',
    'Glikolik asit (AHA)',
    'Ölü hücreleri arındırır, ışıltı verir.',
    aliases: ['glycolic acid'],
    tags: {IngredientTag.aha},
  ),
  IngredientInfo(
    'lactic',
    'Laktik asit (AHA)',
    'Nazik peeling, aynı zamanda nem çeker.',
    aliases: ['lactic acid'],
    tags: {IngredientTag.aha, IngredientTag.humectant},
  ),
  IngredientInfo(
    'mandelic',
    'Mandelik asit (AHA)',
    'Büyük moleküllü, daha nazik AHA.',
    aliases: ['mandelic acid'],
    tags: {IngredientTag.aha},
  ),
  IngredientInfo(
    'salicylic',
    'Salisilik asit (BHA)',
    'Yağda çözünür; gözeneklerin içini temizler, sivilceye iyi gelir.',
    aliases: ['salicylic acid', 'betaine salicylate'],
    tags: {IngredientTag.bha},
  ),
  IngredientInfo(
    'gluconolactone',
    'Glukonolakton (PHA)',
    'En nazik asit grubu; hassas ciltlere uygundur.',
    aliases: ['gluconolactone', 'lactobionic acid'],
    tags: {IngredientTag.pha},
  ),
  IngredientInfo(
    'ascorbic',
    'C vitamini',
    'Antioksidan; lekeleri açar, ışıltı verir.',
    aliases: [
      'ascorbic acid',
      'l-ascorbic acid',
      'sodium ascorbyl phosphate',
      'magnesium ascorbyl phosphate',
      'ascorbyl glucoside',
      '3-o-ethyl ascorbic acid',
      'ethyl ascorbic acid',
      'tetrahexyldecyl ascorbate',
    ],
    tags: {IngredientTag.vitaminC, IngredientTag.antioxidant},
  ),
  IngredientInfo(
    'niacinamide',
    'Niacinamide (B3)',
    'Sebumu dengeler, gözenek görünümünü ve lekeleri azaltır, bariyeri güçlendirir.',
    aliases: ['niacinamide', 'nicotinamide'],
    tags: {IngredientTag.niacinamide},
  ),
  IngredientInfo(
    'azelaic',
    'Azelaik asit',
    'Sivilce, kızarıklık ve lekelerde etkili.',
    aliases: ['azelaic acid'],
    tags: {IngredientTag.azelaicAcid},
  ),
  IngredientInfo(
    'benzoyl-peroxide',
    'Benzoil peroksit',
    'Sivilce bakterisini azaltır; kurutabilir.',
    aliases: ['benzoyl peroxide'],
    tags: {IngredientTag.benzoylPeroxide},
  ),
  IngredientInfo(
    'zinc-pca',
    'Çinko PCA',
    'Sebumu dengeler.',
    aliases: ['zinc pca', 'zinc gluconate'],
    tags: {IngredientTag.zinc},
  ),
  IngredientInfo(
    'peptide',
    'Peptit',
    'Kolajen üretimini destekleyen sinyal molekülleri.',
    patterns: [r'peptide', r'^palmitoyl '],
    tags: {IngredientTag.peptide},
  ),
  IngredientInfo(
    'ferulic',
    'Ferulik asit',
    'Antioksidan; C ve E vitaminini dengeler.',
    aliases: ['ferulic acid'],
    tags: {IngredientTag.antioxidant},
  ),
  IngredientInfo(
    'tocopherol',
    'E vitamini',
    'Antioksidan, yağları oksidasyondan korur.',
    aliases: ['tocopherol', 'tocopheryl acetate'],
    tags: {IngredientTag.antioxidant},
    comedogenic: 2,
  ),
  IngredientInfo(
    'bisabolol',
    'Bisabolol',
    'Papatyadan elde edilir; yatıştırır.',
    aliases: ['bisabolol'],
    tags: {IngredientTag.soothing},
  ),
  IngredientInfo(
    'centella',
    'Centella asiatica',
    'Yatıştırır, bariyer onarımını destekler.',
    patterns: [r'centella asiatica', r'^madecassoside$', r'^asiaticoside$'],
    tags: {IngredientTag.soothing},
  ),
  IngredientInfo(
    'aloe',
    'Aloe vera',
    'Yatıştırır ve nemlendirir.',
    aliases: ['aloe barbadensis leaf juice', 'aloe barbadensis leaf extract'],
    tags: {IngredientTag.soothing, IngredientTag.humectant},
  ),
  IngredientInfo(
    'kaolin',
    'Kaolin kili',
    'Fazla yağı emer.',
    aliases: ['kaolin'],
    tags: {IngredientTag.clay},
  ),
  IngredientInfo(
    'bentonite',
    'Bentonit kili',
    'Fazla yağı ve kiri emer.',
    aliases: ['bentonite'],
    tags: {IngredientTag.clay},
  ),

  // ── Güneş filtreleri ──────────────────────────────────────
  IngredientInfo(
    'zinc-oxide',
    'Çinko oksit',
    'Mineral güneş filtresi; geniş spektrum.',
    aliases: ['zinc oxide'],
    tags: {IngredientTag.uvFilter},
  ),
  IngredientInfo(
    'titanium-dioxide',
    'Titanyum dioksit',
    'Mineral güneş filtresi.',
    aliases: ['titanium dioxide'],
    tags: {IngredientTag.uvFilter},
  ),
  IngredientInfo(
    'chemical-filter',
    'Kimyasal güneş filtresi',
    'UV ışınlarını emer.',
    aliases: [
      'avobenzone',
      'butyl methoxydibenzoylmethane',
      'octocrylene',
      'homosalate',
      'ethylhexyl methoxycinnamate',
      'octinoxate',
      'bis-ethylhexyloxyphenol methoxyphenyl triazine',
      'ethylhexyl triazone',
      'diethylamino hydroxybenzoyl hexyl benzoate',
    ],
    tags: {IngredientTag.uvFilter},
  ),

  // ── Dikkat gerektirenler ──────────────────────────────────
  IngredientInfo(
    'parfum',
    'Parfüm',
    'Koku verir; hassas ciltlerde en sık tahriş nedenlerinden biridir.',
    aliases: ['parfum', 'fragrance', 'aroma', 'perfume'],
    tags: {IngredientTag.fragrance},
  ),
  IngredientInfo(
    'fragrance-allergen',
    'Koku alerjeni',
    'Parfüm bileşeni; AB mevzuatında etikette belirtilmesi zorunlu alerjenlerden.',
    aliases: [
      'limonene',
      'linalool',
      'citral',
      'geraniol',
      'citronellol',
      'eugenol',
      'coumarin',
      'benzyl alcohol',
      'benzyl salicylate',
      'benzyl benzoate',
      'hexyl cinnamal',
      'cinnamal',
      'farnesol',
      'isoeugenol',
      'alpha-isomethyl ionone',
    ],
    tags: {IngredientTag.fragrance, IngredientTag.fragranceAllergen},
  ),
  IngredientInfo(
    'essential-oil',
    'Uçucu yağ',
    'Doğal koku kaynağı; hassas ciltte tahriş yapabilir.',
    patterns: [
      r'(lavandula|citrus|mentha|eucalyptus|melaleuca|rosmarinus).*oil$',
    ],
    tags: {IngredientTag.essentialOil, IngredientTag.fragrance},
  ),
  IngredientInfo(
    'drying-alcohol',
    'Alkol (kurutucu)',
    'Hızlı kuruma ve hafif doku sağlar; yüksek oranda cildi kurutabilir.',
    aliases: [
      'alcohol',
      'alcohol denat',
      'sd alcohol',
      'ethanol',
      'isopropyl alcohol',
      'denatured alcohol',
    ],
    patterns: [r'^sd alcohol'],
    tags: {IngredientTag.dryingAlcohol},
  ),
  IngredientInfo(
    'sls',
    'Sodyum lauril sülfat',
    'Güçlü köpürtücü; cildi kurutup tahriş edebilir.',
    aliases: [
      'sodium lauryl sulfate',
      'sodium laureth sulfate',
      'ammonium lauryl sulfate',
      'ammonium laureth sulfate',
      'sodium coco-sulfate',
    ],
    tags: {IngredientTag.sulfate},
    comedogenic: 5,
  ),
  IngredientInfo(
    'paraben',
    'Paraben',
    'Koruyucu; bazı kişiler kaçınmayı tercih eder.',
    patterns: [r'paraben$'],
    tags: {IngredientTag.paraben, IngredientTag.preservative},
  ),
  IngredientInfo(
    'phenoxyethanol',
    'Fenoksietanol',
    'Yaygın ve güvenli kabul edilen koruyucu.',
    aliases: ['phenoxyethanol'],
    tags: {IngredientTag.preservative},
  ),
  IngredientInfo(
    'ethylhexylglycerin',
    'Etilheksilgliserin',
    'Koruyucu destekleyici, hafif nemlendirici.',
    aliases: ['ethylhexylglycerin'],
  ),

  // ── Yardımcılar ───────────────────────────────────────────
  IngredientInfo(
    'surfactant-mild',
    'Nazik köpürtücü',
    'Cildi kurutmadan temizler.',
    aliases: [
      'cocamidopropyl betaine',
      'decyl glucoside',
      'coco-glucoside',
      'sodium cocoyl isethionate',
      'polyglyceryl-4 oleate',
    ],
  ),
  IngredientInfo(
    'ph-adjuster',
    'pH düzenleyici',
    'Ürünün asitliğini ayarlar.',
    aliases: [
      'sodium hydroxide',
      'citric acid',
      'potassium hydroxide',
      'tromethamine',
    ],
  ),
  IngredientInfo(
    'thickener',
    'Kıvam verici',
    'Dokuyu ve kıvamı ayarlar.',
    aliases: [
      'carbomer',
      'xanthan gum',
      'tamarindus indica seed gum',
      'hydroxyethylcellulose',
      'sodium chloride',
    ],
  ),
  IngredientInfo(
    'polysorbate',
    'Polisorbat',
    'Emülgatör; yağ ve suyu karıştırır.',
    patterns: [r'^polysorbate'],
  ),
  IngredientInfo(
    'rose-water',
    'Gül suyu',
    'Hafif yatıştırıcı tonik bazı.',
    aliases: ['rosa damascena flower water'],
    tags: {IngredientTag.soothing},
  ),
];

/// "Parfum (Fragrance)." → "parfum"
String normalizeInci(String raw) => raw
    .toLowerCase()
    .replaceAll(RegExp(r'\([^)]*\)'), ' ')
    .replaceAll(RegExp(r'[.*]+$'), '')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

final Map<String, IngredientInfo> _byAlias = {
  for (final info in ingredientDb)
    for (final alias in info.aliases) alias: info,
};

final List<(RegExp, IngredientInfo)> _byPattern = [
  for (final info in ingredientDb)
    for (final p in info.patterns) (RegExp(p), info),
];

/// İçerik adını bilgi tabanında arar. Önce tam ad, sonra parantez içi
/// (ör. "Cocos Nucifera (Coconut) Oil" → "coconut oil"), en son kalıplar.
IngredientInfo? lookupIngredient(String raw) {
  final lower = raw.toLowerCase().replaceAll(RegExp(r'[.*]+$'), '').trim();
  final normalized = normalizeInci(raw);
  final direct = _byAlias[lower] ?? _byAlias[normalized];
  if (direct != null) return direct;
  for (final m in RegExp(r'\(([^)]*)\)').allMatches(lower)) {
    for (final part in m.group(1)!.split(',')) {
      final hit = _byAlias[part.trim()];
      if (hit != null) return hit;
    }
  }
  for (final (re, info) in _byPattern) {
    if (re.hasMatch(normalized)) return info;
  }
  return null;
}
