import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../main_navigation.dart';
import 'add_product_screen.dart';

class PendingApprovalScreen extends StatelessWidget {
  final String productName;
  final String brandName;

  const PendingApprovalScreen({
    super.key,
    required this.productName,
    required this.brandName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animasyonlu ikon
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 24, offset: const Offset(0, 8))],
                  ),
                  child: const Center(child: Text('🕐', style: TextStyle(fontSize: 48))),
                ),
                const SizedBox(height: 24),
                const Text('İncelemeye Gönderildi!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                const SizedBox(height: 10),
                Text(
                  '"$productName" ($brandName) ürünü inceleme için gönderildi.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: AppColors.textGrey, height: 1.5),
                ),
                const SizedBox(height: 32),
                // Durum kartı
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                  child: Column(children: [
                    _statusRow('✅', 'Ürün listenize eklendi', true),
                    const SizedBox(height: 12),
                    _statusRow('🔍', 'Ekibimiz ürünü inceliyor', false),
                    const SizedBox(height: 12),
                    _statusRow('🌍', 'Onaylanınca herkese açılır', false),
                  ]),
                ),
                const SizedBox(height: 20),
                // Bilgi kutusu
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.lightGreen, borderRadius: BorderRadius.circular(16)),
                  child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.info_outline, color: AppColors.primary, size: 16),
                    SizedBox(width: 8),
                    Expanded(child: Text(
                      'Onaylandığında bildirim alacaksınız. Bu süreçte ürün yalnızca sizin dolabınızda "Beklemede" olarak görünür.',
                      style: TextStyle(fontSize: 11, color: AppColors.primary, height: 1.5),
                    )),
                  ]),
                ),
                const SizedBox(height: 32),
                // Ana sayfaya dön
                SizedBox(width: double.infinity, child: DecoratedBox(
                  decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(14)),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const MainNavigation()),
                      (route) => false,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text('Koleksiyonuma  Git', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                )),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: OutlinedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductScreen())),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.softGreen, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Başka Ürün Ekle', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark)),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusRow(String emoji, String text, bool isDone) => Row(children: [
    Text(emoji, style: const TextStyle(fontSize: 18)),
    const SizedBox(width: 12),
    Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: isDone ? AppColors.textDark : AppColors.textGrey,
      fontWeight: isDone ? FontWeight.w500 : FontWeight.w400))),
    if (isDone) const Icon(Icons.check_circle, color: AppColors.primary, size: 16),
  ]);
}