import 'dart:convert';

/// Ürün görseli ve profil fotoğrafı için üst sınırlar. Sunucudaki sınırlarla
/// aynı (backend/app/config.py: max_image_bytes ve yarısı).
const maxProductImageKb = 500;
const maxAvatarKb = 250;

/// Dosyanın gerçek türü, uzantıya değil ilk baytlara (imza) bakılarak.
/// "foto.png" adıyla yüklenen bir betik uzantı kontrolünü geçer, imzayı geçemez.
String? imageMime(List<int> b) {
  if (b.length > 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF) {
    return 'jpeg';
  }
  if (b.length > 8 &&
      b[0] == 0x89 &&
      b[1] == 0x50 &&
      b[2] == 0x4E &&
      b[3] == 0x47 &&
      b[4] == 0x0D &&
      b[5] == 0x0A &&
      b[6] == 0x1A &&
      b[7] == 0x0A) {
    return 'png';
  }
  return null;
}

/// Seçilen görseli data URL'e çevirir; uygun değilse hata mesajı döner.
({String? url, String? error}) toImageDataUrl(
  List<int> bytes, {
  required int maxKb,
}) {
  final mime = imageMime(bytes);
  if (mime == null) {
    return (url: null, error: 'Yalnızca JPG ve PNG fotoğraflar kabul edilir.');
  }
  if (bytes.length > maxKb * 1024) {
    return (
      url: null,
      error: 'Fotoğraf en fazla $maxKb KB olabilir; daha küçük bir görsel seç.',
    );
  }
  return (url: 'data:image/$mime;base64,${base64Encode(bytes)}', error: null);
}
