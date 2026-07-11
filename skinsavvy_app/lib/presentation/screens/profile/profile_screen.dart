import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../reviews/write_review_screen.dart';
import '../reviews/my_reviews_screen.dart';
import 'edit_profile_screen.dart';
import 'edit_skin_profile_screen.dart';
import 'notifications_screen.dart';
import 'theme_screen.dart';
import 'language_screen.dart';
import 'share_finished_screen.dart';
import 'privacy_screen.dart';
import 'help_screen.dart';
import '../auth/login_screen.dart';
class ProfileScreen extends StatelessWidget {
  void _showLogoutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Çıkış Yap',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark)),
      content: const Text('Hesabınızdan çıkış yapmak istediğinizden emin misiniz?',
        style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
          child: const Text('İptal', style: TextStyle(color: AppColors.textGrey))),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            // Gerçek uygulamada: FirebaseAuth.instance.signOut();
            Navigator.pushAndRemoveUntil(context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false);
          },
          child: const Text('Çıkış Yap',
            style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
}
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: SafeArea(
          child: ListView(children: [
            _header(),
            Padding(padding: const EdgeInsets.all(14), child: Column(children: [
              _statsCard(),
              const SizedBox(height: 10),
              _skinProfileCard(context),
              const SizedBox(height: 10),
              _reviewsCard(context),
              const SizedBox(height: 10),
              _menuCard(context),
            ])),
          ]),
        ),
      ),
    );
  }

  Widget _header() => Container(
    width: double.infinity, color: Colors.white, padding: const EdgeInsets.all(20),
    child: Column(children: [
      ClipOval(
        child: Image.asset(
          'assets/images/logo.png',
          width: 64,
          height: 64,
          fit: BoxFit.cover,
        ),
      ),
      const SizedBox(height: 10),
      const Text('Melis Yalçınkaya', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textDark)),
      const SizedBox(height: 3),
      const Text('melis@email.com', style: TextStyle(fontSize: 11, color: AppColors.textGrey)),
      const SizedBox(height: 14),
      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _statBadge('12', 'Ürün'), _divider(), _statBadge('3', 'Rutin'), _divider(), _statBadge('85%', 'Tamamlama'), _divider(), _statBadge('7', 'Gün Seri'),
      ]),
    ]),
  );

  Widget _divider() => Container(width: 0.5, height: 30, color: AppColors.softGreen);
  Widget _statBadge(String v, String l) => Column(children: [
    Text(v, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: AppColors.primary)),
    Text(l, style: const TextStyle(fontSize: 9, color: AppColors.textGrey)),
  ]);

  Widget _statsCard() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: const [Icon(Icons.bar_chart, color: AppColors.primary, size: 17), SizedBox(width: 6),
        Text('İstatistiklerim', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark))]),
      const SizedBox(height: 10),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [
        Text('Bu ay rutin tamamlama', style: TextStyle(fontSize: 10, color: AppColors.textGrey)),
        Text('78%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.textDark)),
      ]),
      const SizedBox(height: 4),
      ClipRRect(borderRadius: BorderRadius.circular(3), child: const LinearProgressIndicator(value: 0.78, minHeight: 6, backgroundColor: AppColors.softGreen, valueColor: AlwaysStoppedAnimation(AppColors.primary))),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _miniBox('24', 'Toplam Kullanım', AppColors.primary)),
        const SizedBox(width: 8),
        Expanded(child: _miniBox('3', 'Bitmek Üzere', AppColors.accent)),
      ]),
    ]),
  );

  Widget _miniBox(String v, String l, Color c) => Container(
    padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(12)),
    child: Column(children: [Text(v, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: c)), Text(l, style: const TextStyle(fontSize: 9, color: AppColors.textGrey))]),
  );

Widget _skinProfileCard(BuildContext context) => Container(
  padding: const EdgeInsets.all(14),
  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      const Icon(Icons.water_drop_outlined, color: AppColors.primary, size: 17),
      const SizedBox(width: 6),
      const Expanded(child: Text('Cilt Profilim',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark))),
      GestureDetector(
        onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const EditSkinProfileScreen())),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: AppColors.lightGreen, shape: BoxShape.circle),
          child: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 14),
        ),
      ),
    ]),
    const SizedBox(height: 10),
    Wrap(spacing: 6, runSpacing: 6, children: [
      _tag('Karma Cilt', false),
      _tag('Sivilce', false),
      _tag('Leke', false),
      _tag('⚠️ Retinol Alerjisi', true),
    ]),
  ]),
);

  Widget _tag(String t, bool warn) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: warn ? const Color(0xFFFFEEE8) : AppColors.lightGreen, borderRadius: BorderRadius.circular(20)),
    child: Text(t, style: TextStyle(fontSize: 10, color: warn ? AppColors.accent : AppColors.primary, fontWeight: FontWeight.w500)));

  Widget _reviewsCard(BuildContext context) => GestureDetector(
    onTap: () => Navigator.push(context,
      MaterialPageRoute(builder: (_) => const MyReviewsScreen())),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(children: const [
        Icon(Icons.chat_bubble_outline, color: AppColors.primary, size: 17),
        SizedBox(width: 6),
        Expanded(child: Text('Yorumlarım (8)',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark))),
        Icon(Icons.chevron_right, color: AppColors.textLight, size: 18),
      ]),
    ),
  );

  Widget _menuCard(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        _menuItem(
          Icons.person_outline,
          'Profil Düzenle',
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const EditProfileScreen())),
        ),
        _menuItem(Icons.palette_outlined, 'Tema', trailing: 'Açık', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ThemeScreen()))),
        _menuItem(Icons.language_outlined, 'Dil', trailing: 'Türkçe', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageScreen()))),
        _menuItem(Icons.notifications_outlined, 'Bildirimler', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
        _menuItem(Icons.share_outlined, 'Bitirdiklerimi Paylaş', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShareFinishedScreen()))),
        _menuItem(Icons.shield_outlined, 'Gizlilik', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyScreen()))),
        _menuItem(Icons.help_outline, 'Yardım', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpScreen()))),
        _menuItem(Icons.logout, 'Çıkış Yap', isDestructive: true, isLast: true, onTap: () => _showLogoutDialog(context)),]),
    );

Widget _menuItem(IconData icon, String label, 
      {String? trailing, 
      bool isDestructive = false,
      bool isLast = false, 
      VoidCallback? onTap}) => // onTap parametresi eklendi
    InkWell(
    onTap: onTap,   
    splashColor: AppColors.lightGreen,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.softGreen, width: 0.5))),
      child: Row(children: [
        Icon(icon, size: 17, color: isDestructive ? AppColors.accent : AppColors.primary),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: TextStyle(fontSize: 12.5, color: isDestructive ? AppColors.accent : AppColors.textDark))),
        if (trailing != null) Text(trailing, style: const TextStyle(fontSize: 11, color: AppColors.textGrey))
        else if (!isDestructive) const Icon(Icons.chevron_right, color: AppColors.textLight, size: 15),
      ]),
    ),
  );
}