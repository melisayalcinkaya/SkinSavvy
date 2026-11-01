import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/routine.dart';
import '../../../data/models/user.dart';
import '../../../state/catalog_controller.dart';
import '../../../state/review_controller.dart';
import '../../../state/routine_controller.dart';
import '../../../state/session_controller.dart';
import '../../../state/shelf_controller.dart';
import '../../widgets/user_avatar.dart';
import '../moderation/moderation_screen.dart';
import '../reviews/my_reviews_screen.dart';
import 'edit_profile_screen.dart';
import 'edit_skin_profile_screen.dart';
import 'help_screen.dart';
import 'language_screen.dart';
import 'notifications_screen.dart';
import 'privacy_screen.dart';
import 'share_finished_screen.dart';
import 'theme_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Çıkış Yap',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        content: const Text(
          'Hesabınızdan çıkış yapmak istediğinizden emin misiniz?',
          style: TextStyle(fontSize: 13, color: AppColors.textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'İptal',
              style: TextStyle(color: AppColors.textGrey),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // Yönlendirici oturumun kapandığını görüp giriş ekranına götürür.
              context.read<SessionController>().signOut();
            },
            child: const Text(
              'Çıkış Yap',
              style: TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionController>().user;
    if (user == null) return const SizedBox.shrink();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: SafeArea(
          child: ListView(
            children: [
              _header(context, user),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    _statsCard(context),
                    const SizedBox(height: 10),
                    _skinProfileCard(context, user.skinProfile),
                    const SizedBox(height: 10),
                    _reviewsCard(context),
                    const SizedBox(height: 10),
                    _menuCard(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, AppUser user) {
    final shelf = context.watch<ShelfController>();
    final routine = context.watch<RoutineController>();
    final today = dateOnly(DateTime.now());
    final rate = routine.completionRate(
      today.subtract(const Duration(days: 29)),
      today,
    );
    final steps =
        routine.entries(RoutineSlot.morning).length +
        routine.entries(RoutineSlot.evening).length;
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          UserAvatar(user: user),
          const SizedBox(height: 10),
          Text(
            user.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            user.email,
            style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
          ),
          if (user.isDemo) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.lightGreen,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Demo hesabı',
                style: TextStyle(fontSize: 10, color: AppColors.primary),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statBadge('${shelf.using.length}', 'Kullanımda'),
              _divider(),
              _statBadge('$steps', 'Rutin Adımı'),
              _divider(),
              _statBadge(
                rate == null ? '-' : '%${(rate * 100).round()}',
                'Tamamlama',
              ),
              _divider(),
              _statBadge('${routine.streak(DateTime.now())}', 'Gün Seri'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      Container(width: 0.5, height: 30, color: AppColors.softGreen);

  Widget _statBadge(String v, String l) => Column(
    children: [
      Text(
        v,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w500,
          color: AppColors.primary,
        ),
      ),
      Text(l, style: const TextStyle(fontSize: 10, color: AppColors.textGrey)),
    ],
  );

  Widget _statsCard(BuildContext context) {
    final routine = context.watch<RoutineController>();
    final shelf = context.watch<ShelfController>();
    final added = context.select<CatalogController, int>(
      (c) => c.contributionCount,
    );
    final reviewCount = context.select<ReviewController, int>((r) => r.count);
    final today = dateOnly(DateTime.now());
    final monthRate = routine.completionRate(
      DateTime(today.year, today.month),
      today,
    );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart, color: AppColors.primary, size: 17),
              SizedBox(width: 6),
              Text(
                'İstatistiklerim',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Bu ay rutin tamamlama',
                style: TextStyle(fontSize: 11, color: AppColors.textGrey),
              ),
              Text(
                monthRate == null ? '-' : '%${(monthRate * 100).round()}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: monthRate ?? 0,
              minHeight: 6,
              backgroundColor: AppColors.softGreen,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 12),
          // Katkı: önerip kataloğa kazandırdıkları, kullandıkları (bitenler
          // dahil) ve yazdığı yorumlar.
          Row(
            children: [
              Expanded(
                child: _miniBox('$added', 'Eklediğim', AppColors.primary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _miniBox(
                  '${shelf.owned.length}',
                  'Kullandığım',
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _miniBox(
                  '$reviewCount',
                  'Yorumlarım',
                  AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _miniBox(
                  '${routine.totalCompletions}',
                  'Tamamlanan Adım',
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _miniBox(
                  '${shelf.runningLowCount}',
                  'Bitmek Üzere',
                  AppColors.accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniBox(String v, String l, Color c) => Container(
    padding: const EdgeInsets.all(9),
    decoration: BoxDecoration(
      color: AppColors.cream,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        Text(
          v,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: c),
        ),
        Text(
          l,
          style: const TextStyle(fontSize: 10, color: AppColors.textGrey),
        ),
      ],
    ),
  );

  Widget _skinProfileCard(BuildContext context, SkinProfile profile) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.water_drop_outlined,
                  color: AppColors.primary,
                  size: 17,
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Cilt Profilim',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Cilt profilini düzenle',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EditSkinProfileScreen(),
                    ),
                  ),
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.lightGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      color: AppColors.primary,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (profile.skinType != null) _tag(profile.skinType!, false),
                for (final c in profile.concerns)
                  _tag(c.split(' / ').first, false),
                for (final a in profile.allergens)
                  _tag('⚠️ ${a.split(' / ').first} hassasiyeti', true),
                if (profile.skinType == null) _tag('Henüz doldurulmadı', false),
              ],
            ),
          ],
        ),
      );

  Widget _tag(String t, bool warn) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: warn ? const Color(0xFFFFEEE8) : AppColors.lightGreen,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      t,
      style: TextStyle(
        fontSize: 11,
        color: warn ? AppColors.accent : AppColors.primary,
        fontWeight: FontWeight.w500,
      ),
    ),
  );

  Widget _reviewsCard(BuildContext context) {
    final count = context.select<ReviewController, int>((r) => r.count);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MyReviewsScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.chat_bubble_outline,
              color: AppColors.primary,
              size: 17,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Yorumlarım ($count)',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textLight,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuCard(BuildContext context) {
    void open(Widget screen) =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    // Yalnızca ekip (yönetici) görür; sayı onay bekleyen öneri sayısıdır.
    final queue = context.select<CatalogController, int?>(
      (c) => c.isAdmin ? c.reviewQueue.length : null,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          if (queue != null)
            _menuItem(
              Icons.fact_check_outlined,
              'Onay Bekleyen Ürünler',
              trailing: '$queue',
              onTap: () => open(const ModerationScreen()),
            ),
          _menuItem(
            Icons.person_outline,
            'Profil Düzenle',
            onTap: () => open(const EditProfileScreen()),
          ),
          _menuItem(
            Icons.palette_outlined,
            'Tema',
            trailing: 'Açık',
            onTap: () => open(const ThemeScreen()),
          ),
          _menuItem(
            Icons.language_outlined,
            'Dil',
            trailing: 'Türkçe',
            onTap: () => open(const LanguageScreen()),
          ),
          _menuItem(
            Icons.notifications_outlined,
            'Bildirimler',
            onTap: () => open(const NotificationsScreen()),
          ),
          _menuItem(
            Icons.share_outlined,
            'Bitirdiklerimi Paylaş',
            onTap: () => open(const ShareFinishedScreen()),
          ),
          _menuItem(
            Icons.shield_outlined,
            'Gizlilik',
            onTap: () => open(const PrivacyScreen()),
          ),
          _menuItem(
            Icons.help_outline,
            'Yardım',
            onTap: () => open(const HelpScreen()),
          ),
          _menuItem(
            Icons.logout,
            'Çıkış Yap',
            isDestructive: true,
            isLast: true,
            onTap: () => _showLogoutDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _menuItem(
    IconData icon,
    String label, {
    String? trailing,
    bool isDestructive = false,
    bool isLast = false,
    VoidCallback? onTap,
  }) => InkWell(
    onTap: onTap,
    splashColor: AppColors.lightGreen,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.softGreen, width: 0.5),
              ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 17,
            color: isDestructive ? AppColors.accent : AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDestructive ? AppColors.accent : AppColors.textDark,
              ),
            ),
          ),
          if (trailing != null)
            Text(
              trailing,
              style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
            )
          else if (!isDestructive)
            const Icon(
              Icons.chevron_right,
              color: AppColors.textLight,
              size: 15,
            ),
        ],
      ),
    ),
  );
}
