import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
          child: Column(children: [
        Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(4, 10, 16, 10),
            child: Row(children: [
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon:
                      const Icon(Icons.arrow_back, color: AppColors.textDark)),
              const Expanded(
                  child: Text('Gizlilik Politikası',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textDark))),
              const SizedBox(width: 48),
            ])),
        Expanded(
            child: ListView(padding: const EdgeInsets.all(16), children: [
          _section('Veri Toplama',
              'SkinSavvy, size daha iyi hizmet sunabilmek için yalnızca gerekli verileri toplar. Bu veriler; isim, e-posta, cilt profili ve ürün bilgilerini kapsar.'),
          _section('Veri Kullanımı',
              'Toplanan veriler yalnızca uygulama içi deneyiminizi kişiselleştirmek için kullanılır. Verileriniz üçüncü taraflarla paylaşılmaz.'),
          _section('Veri Güvenliği',
              'Tüm verileriniz Firebase altyapısında şifreli olarak saklanır. SSL/TLS protokolleri kullanılır.'),
          _section('Hesap Silme',
              'Hesabınızı sildiğinizde tüm verileriniz kalıcı olarak silinir. Bu işlem geri alınamaz.'),
          _section('İletişim',
              'Gizlilik ile ilgili sorularınız için: privacy@skinsavvy.com'),
        ])),
      ])),
    );
  }

  Widget _section(String title, String content) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark)),
          const SizedBox(height: 6),
          Text(content,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textGrey, height: 1.6)),
        ]),
      );
}
