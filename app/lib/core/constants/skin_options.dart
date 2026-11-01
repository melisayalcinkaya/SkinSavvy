/// Karşılama akışı ve cilt profili ekranının ortak seçenekleri.
///
/// Önceden iki ekranda ayrı ayrı yazılıydı; birinde değişiklik yapılınca
/// diğeri eski kalıyordu. Artık tek kaynak burası.
class SkinOption {
  const SkinOption(this.emoji, this.label, [this.sub]);

  final String emoji;
  final String label;
  final String? sub;
}

const skinTypeOptions = [
  SkinOption('🌸', 'Karma Cilt'),
  SkinOption('💧', 'Kuru Cilt'),
  SkinOption('✨', 'Yağlı Cilt'),
  SkinOption('🌿', 'Normal Cilt'),
  SkinOption('🌷', 'Hassas Cilt'),
];

const concernOptions = [
  SkinOption('🔴', 'Sivilce / Akne'),
  SkinOption('🟤', 'Leke / Renk Eşitsizliği'),
  SkinOption('〰️', 'Kırışıklık / Anti-Aging'),
  SkinOption('🕳️', 'Gözenek'),
  SkinOption('💦', 'Nemsizlik'),
];

const commonAllergens = [
  'Parfüm / Fragrance',
  'Alkol',
  'Retinol',
  'Niacinamide',
  'Salisilik Asit',
  'Lanolin',
  'Sülfat',
  'Paraben',
  'Propilen Glikol',
];

const intensityOptions = [
  SkinOption('🌱', 'Basit (2-3 adım)', 'Temizleyici, nemlendirici, SPF'),
  SkinOption('🌿', 'Orta (4-6 adım)', '+ Serum, tonik'),
  SkinOption('🌳', 'Detaylı (7+ adım)', 'K-beauty tarzı çok adımlı'),
];

const productCategories = [
  'Temizleyici',
  'Tonik',
  'Serum',
  'Nemlendirici',
  'Güneş Kremi',
  'Maske',
  'Peeling',
  'Göz Kremi',
  'Yağ',
  'Diğer',
];

const productSkinTypes = [
  'Tüm Cilt Tipleri',
  'Kuru Cilt',
  'Yağlı Cilt',
  'Karma Cilt',
  'Normal Cilt',
  'Hassas Cilt',
];

/// Kategoriye göre rutin satırında gösterilecek emoji.
String categoryEmoji(String category) => switch (category) {
  'Temizleyici' => '💧',
  'Tonik' => '🫧',
  'Serum' => '✨',
  'Nemlendirici' => '🧴',
  'Güneş Kremi' => '☀️',
  'Maske' => '🎭',
  'Peeling' => '🍋',
  'Göz Kremi' => '👁️',
  'Yağ' => '🌼',
  _ => '🌿',
};
