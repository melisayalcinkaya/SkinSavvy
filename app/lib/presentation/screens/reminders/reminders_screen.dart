import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/routine.dart';
import '../../../domain/reminders/reminders.dart';
import '../../../state/catalog_controller.dart';
import '../../../state/routine_controller.dart';
import '../../../state/settings_controller.dart';
import '../../../state/shelf_controller.dart';
import '../collections/edit_product_screen.dart';
import '../moderation/moderation_screen.dart';
import '../products/product_detail_screen.dart';
import '../profile/notifications_screen.dart';

/// Dolap, rutin ve bildirim ayarlarından o anki hatırlatmaları üretir ve
/// bunlardan biri değişince widget'ı yeniden çizer.
List<Reminder> watchReminders(BuildContext context, {DateTime? now}) {
  final shelf = context.watch<ShelfController>();
  final routine = context.watch<RoutineController>();
  final settings = context.watch<SettingsController>().settings;
  final catalog = context.watch<CatalogController>();
  final at = now ?? DateTime.now();
  return buildReminders(
    items: shelf.using,
    settings: settings,
    now: at,
    decisions: catalog.unseenDecisions,
    reviewQueue: catalog.reviewQueue.length,
    routine: [
      for (final slot in RoutineSlot.values)
        (
          slot: slot,
          done: routine.doneCount(slot, at),
          total: routine.entriesOn(slot, at).length,
        ),
    ],
  );
}

/// Rutin başlığındaki zil: acil hatırlatma sayısını rozetle gösterir.
class ReminderBell extends StatelessWidget {
  const ReminderBell({super.key});

  @override
  Widget build(BuildContext context) {
    final reminders = watchReminders(context);
    final count = reminders.where((r) => r.urgent).length;
    return Semantics(
      button: true,
      label: reminders.isEmpty
          ? 'Hatırlatmalar'
          : 'Hatırlatmalar, ${reminders.length} yeni',
      child: InkResponse(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RemindersScreen()),
        ),
        radius: 24,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.notifications_none_rounded,
                color: AppColors.textDark,
                size: 24,
              ),
              if (reminders.isNotEmpty)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 16),
                    height: 16,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: count > 0 ? AppColors.accent : AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: ExcludeSemantics(
                      child: Text(
                        '${count > 0 ? count : reminders.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reminders = watchReminders(context);
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Geri',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.textDark,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Hatırlatmalar',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Bildirim ayarları',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    ),
                    icon: const Icon(
                      Icons.tune_rounded,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: reminders.isEmpty
                  ? const _Empty()
                  : ListView.separated(
                      padding: const EdgeInsets.all(14),
                      itemCount: reminders.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _ReminderTile(
                        reminders[i],
                        key: Key(reminders[i].key),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile(this.r, {super.key});

  final Reminder r;

  ({IconData icon, Color fg, Color bg}) get _style => switch (r.kind) {
    ReminderKind.expired => (
      icon: Icons.event_busy_outlined,
      fg: AppColors.accent,
      bg: const Color(0xFFFFEEE8),
    ),
    ReminderKind.expiresSoon => (
      icon: Icons.hourglass_bottom_rounded,
      fg: const Color(0xFFB4651F),
      bg: const Color(0xFFFFF3E3),
    ),
    ReminderKind.submissionRejected => (
      icon: Icons.report_gmailerrorred_outlined,
      fg: AppColors.accent,
      bg: const Color(0xFFFFEEE8),
    ),
    ReminderKind.submissionApproved => (
      icon: Icons.verified_outlined,
      fg: AppColors.primary,
      bg: AppColors.lightGreen,
    ),
    ReminderKind.reviewQueue => (
      icon: Icons.fact_check_outlined,
      fg: AppColors.primary,
      bg: AppColors.lightGreen,
    ),
    ReminderKind.routineDue => (
      icon: r.slot == RoutineSlot.morning
          ? Icons.wb_sunny_outlined
          : Icons.nightlight_outlined,
      fg: AppColors.primary,
      bg: AppColors.lightGreen,
    ),
    ReminderKind.lowStock => (
      icon: Icons.battery_2_bar_rounded,
      fg: AppColors.textGrey,
      bg: AppColors.softGreen,
    ),
  };

  void _open(BuildContext context) {
    if (r.kind == ReminderKind.reviewQueue) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ModerationScreen()),
      );
      return;
    }
    final productId = r.productId;
    if (productId != null) {
      // Karar görüldü: bildirim kalkar, ürün (reddedildiyse gerekçesiyle) açılır.
      context.read<CatalogController>().markDecisionSeen(productId);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(productId: productId),
        ),
      );
      return;
    }
    final id = r.shelfItemId;
    if (id == null) {
      // Rutin hatırlatması: rutin sekmesine dön.
      Navigator.pop(context);
      return;
    }
    final item = context.read<ShelfController>().byId(id);
    if (item == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditProductScreen(product: item)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _style;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _open(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: s.bg, shape: BoxShape.circle),
                child: Icon(s.icon, color: s.fg, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: r.urgent ? s.fg : AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      r.detail,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textGrey,
                        height: 1.45,
                      ),
                    ),
                  ],
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
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            color: AppColors.textLight,
            size: 40,
          ),
          SizedBox(height: 10),
          Text(
            'Şu an hatırlatma yok',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Son kullanma tarihi yaklaşan, azalan ürünler ve bekleyen '
            'rutinler burada görünür.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textGrey,
              height: 1.45,
            ),
          ),
        ],
      ),
    ),
  );
}
