import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(4, 10, 16, 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.textDark,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Gizlilik Politikası',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _section(
                    'Hangi veriler tutulur?',
                    'Ad, e-posta, cilt profili (cilt tipi, endişeler, hassasiyetler), ürün dolabınız, rutinleriniz ve yorumlarınız. Konum, rehber ya da reklam kimliği toplanmaz.',
                  ),
                  _section(
                    'Nerede saklanır?',
                    'Cihaz modunda tüm veriler yalnızca bu cihazda (web sürümünde tarayıcınızın depolama alanında) tutulur ve hiçbir sunucuya gönderilmez. Tarayıcı verilerini temizlerseniz bu bilgiler de silinir.',
                  ),
                  _section(
                    'Şifreler',
                    'Şifreniz hiçbir zaman düz metin olarak saklanmaz; her hesap için rastgele bir tuzla PBKDF2-SHA256 özeti alınır.',
                  ),
                  _section(
                    'Veri Kullanımı',
                    'Veriler yalnızca rutin takibi, hatırlatmalar ve içerik analizini size göre kişiselleştirmek için kullanılır; üçüncü taraflarla paylaşılmaz.',
                  ),
                  _section(
                    'Hesap Silme',
                    'Profil Düzenle > Hesabı Sil ile hesabınız ve ona ait tüm veriler kalıcı olarak silinir. Bu işlem geri alınamaz.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, String content) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          content,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textGrey,
            height: 1.6,
          ),
        ),
      ],
    ),
  );
}
