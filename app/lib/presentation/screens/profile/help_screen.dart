import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  final List<Map<String, String>> _faqs = const [
    {'q': 'Ürün nasıl eklerim?', 'a': 'Ürünler sekmesinde arama yapın. Bulamazsanız "Bu ürünü sisteme ekle" butonuna tıklayın.'},
    {'q': 'Rutin nasıl oluştururum?', 'a': 'Rutin sekmesinde "Düzenle" butonuna tıklayın. Kategoriden ürün seçip gün noktalarına dokunarak ekleyin.'},
    {'q': 'Ürünü nasıl bitiririm?', 'a': 'Koleksiyonlarım → Ürünlerim sekmesinde ürün kartının ⋮ menüsünden "Ürünü Bitir" seçeneğini kullanın.'},
    {'q': 'Yorum nasıl yazarım?', 'a': 'Koleksiyonlarım → Kullandıklarım veya Bitirdiklerim sekmesindeki ürün kartından "Yorum Yaz" butonuna tıklayın.'},
    {'q': 'Eklediğim ürün neden görünmüyor?', 'a': 'Eklediğiniz ürün ekibimiz tarafından incelendikten sonra sisteme eklenir. Bu süreçte yalnızca sizin listenizde görünür.'},
    {'q': 'Şifremi unuttum, ne yapmalıyım?', 'a': 'Giriş ekranındaki "Şifremi unuttum" linkine tıklayın. E-posta adresinize sıfırlama bağlantısı gönderilecektir.'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(child: Column(children: [
        Container(color: Colors.white, padding: const EdgeInsets.fromLTRB(4, 10, 16, 10),
          child: Row(children: [
            IconButton(onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: AppColors.textDark)),
            const Expanded(child: Text('Yardım & SSS', textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textDark))),
            const SizedBox(width: 48),
          ])),
        Expanded(child: ListView(padding: const EdgeInsets.all(16), children: [
          Container(
            padding: const EdgeInsets.all(14), margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: AppColors.lightGreen, borderRadius: BorderRadius.circular(16)),
            child: const Row(children: [
              Icon(Icons.support_agent, color: AppColors.primary, size: 18), SizedBox(width: 8),
              Expanded(child: Text('Yardıma ihtiyacınız mı var? support@skinsavvy.com',
                style: TextStyle(fontSize: 11, color: AppColors.primary))),
            ]),
          ),
          ..._faqs.map((f) => _faqTile(f['q']!, f['a']!)),
        ])),
      ])),
    );
  }

  Widget _faqTile(String q, String a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        leading: Container(width: 28, height: 28,
          decoration: BoxDecoration(color: AppColors.lightGreen, shape: BoxShape.circle),
          child: const Icon(Icons.help_outline, color: AppColors.primary, size: 15)),
        title: Text(q, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark)),
        iconColor: AppColors.primary,
        collapsedIconColor: AppColors.textLight,
        children: [Text(a, style: const TextStyle(fontSize: 12, color: AppColors.textGrey, height: 1.6))],
      ),
    );
  }
}