import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/image_utils.dart';
import 'product_image.dart';

/// Galeriden ürün fotoğrafı seçer ve küçültülmüş data URL'e çevirir.
/// Vazgeçilirse null döner; sorun olursa [onError] çağrılır.
///
/// Görsel cihazda küçültülür (en çok 800 px); hem depolama hem yükleme boyutu
/// düşer. Dosya imzası kontrol edilir: yalnızca JPEG ve PNG kabul edilir.
Future<String?> pickProductPhoto(void Function(String message) onError) async {
  try {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );
    if (picked == null) return null;
    final image = toImageDataUrl(
      await picked.readAsBytes(),
      maxKb: maxProductImageKb,
    );
    if (image.error != null) {
      onError(image.error!);
      return null;
    }
    return image.url;
  } on PlatformException {
    onError('Galeriye erişilemedi. İzinleri kontrol edin.');
    return null;
  }
}

/// Fotoğraf seçme kutusu: seçilmişse önizleme, değilse "Fotoğraf Seç".
class ProductPhotoBox extends StatelessWidget {
  const ProductPhotoBox({
    super.key,
    required this.image,
    required this.onTap,
    this.height = 200,
  });

  final String? image;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    final img = image;
    return Semantics(
      button: true,
      label: img == null ? 'Fotoğraf seç' : 'Fotoğrafı değiştir',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.softGreen, width: 2),
          ),
          child: img != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    ProductImage(img, radius: 14),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Değiştir',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: AppColors.lightGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_outlined,
                        color: AppColors.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Fotoğraf Seç',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Ürünün ön yüzü net görünsün',
                      style: TextStyle(fontSize: 11, color: AppColors.textGrey),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
