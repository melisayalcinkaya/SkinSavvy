/// Serbest metin girdilerini temizler.
///
/// Flutter `Text` bileşeni HTML yorumlamadığı için uygulama içinde XSS riski
/// yoktur; asıl koruma veriyi gösteren tarafta (ör. web paneli) çıktıyı
/// kaçırmaktır. Burada yalnızca etiketleri ve açılı parantezleri atıp
/// baştaki/sondaki boşlukları kırpıyoruz. Kesme işareti gibi meşru
/// karakterler korunur ("Paula's Choice").
String sanitizeInput(String input) => input
    .replaceAll(RegExp(r'<[^>]*>'), '')
    .replaceAll(RegExp('[<>]'), '')
    .trim();

final _emailPattern = RegExp(
  r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
);

bool isValidEmail(String value) => _emailPattern.hasMatch(value.trim());

/// Türkçe büyük/küçük harf ve aksan farklarını yok sayan arama anahtarı.
String searchKey(String value) => value
    .replaceAll('İ', 'i')
    .replaceAll('I', 'ı')
    .toLowerCase()
    .replaceAll('ı', 'i')
    .replaceAll('ğ', 'g')
    .replaceAll('ü', 'u')
    .replaceAll('ş', 's')
    .replaceAll('ö', 'o')
    .replaceAll('ç', 'c')
    .trim();

/// 299.9 → "₺299,90"
String formatPrice(double? value) =>
    value == null ? '' : '₺${value.toStringAsFixed(2).replaceAll('.', ',')}';
