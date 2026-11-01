import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/routine.dart';
import '../../../state/routine_controller.dart';
import '../../../state/session_controller.dart';
import '../../../state/settings_controller.dart';
import '../../../state/shelf_controller.dart';
import '../../widgets/app_snack.dart';
import '../../widgets/product_image.dart';
import '../../widgets/routine_warnings_card.dart';
import 'routine_editor_screen.dart';
import 'routine_item_detail_modal.dart';

class RoutineHomeScreen extends StatefulWidget {
  const RoutineHomeScreen({super.key});
  @override
  State<RoutineHomeScreen> createState() => _RoutineHomeScreenState();
}

class _RoutineHomeScreenState extends State<RoutineHomeScreen> {
  late DateTime _selected = dateOnly(DateTime.now());

  static const _tips = [
    'Güneş kremi her gün kullanılmalıdır. UV ışınları bulutlu havalarda da zarar verebilir.',
    'Yeni bir aktif içeriği haftada 2-3 akşamla başlatıp cildin alışmasını bekleyin.',
    'Ürünleri en inceden en kalına doğru sürün: tonik, serum, nemlendirici.',
    'Retinol ve asit içeren ürünleri aynı akşam kullanmak tahrişe yol açabilir.',
    'Nemlendiriciyi cilt hafif nemliyken sürmek emilimi artırır.',
    'Yastık kılıfınızı haftada bir değiştirmek sivilce oluşumunu azaltabilir.',
    'Açılmış ürünlerin raf ömrü sınırlıdır; kapaktaki "12M" simgesine dikkat edin.',
  ];

  void _openEditor(RoutineSlot slot) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RoutineEditorScreen(slot: slot)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final routine = context.watch<RoutineController>();
    final today = dateOnly(DateTime.now());
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: SafeArea(
          child: Column(
            children: [
              _header(today),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  children: [
                    _routineCard(RoutineSlot.morning, routine),
                    _routineCard(RoutineSlot.evening, routine),
                    RoutineWarningsCard(warnings: routine.warnings),
                    _statsRow(routine, today),
                    _tipCard(today),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(DateTime today) {
    final name = context.select<SessionController, String>(
      (s) => s.user?.firstName ?? '',
    );
    final days = List.generate(7, (i) => today.add(Duration(days: i - 3)));
    return Container(
      color: Colors.white.withValues(alpha: 0.95),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? 'Merhaba 👋' : 'Merhaba $name 👋',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selected == today
                        ? 'Bugün cildiniz nasıl?'
                        : formatDateShort(_selected),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
              Image.asset('assets/images/logo.png', width: 42, height: 42),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (final d in days)
                  Semantics(
                    button: true,
                    selected: d == _selected,
                    label: formatDateShort(d),
                    child: GestureDetector(
                      onTap: () => setState(() => _selected = d),
                      child: Column(
                        children: [
                          Text(
                            weekdayLetter[d.weekday - 1],
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textGrey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              gradient: d == _selected
                                  ? AppGradients.primary
                                  : null,
                              color: d == today && d != _selected
                                  ? AppColors.peach
                                  : null,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${d.day}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: d == _selected
                                      ? Colors.white
                                      : d == today
                                      ? AppColors.accent
                                      : AppColors.textDark,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _routineCard(RoutineSlot slot, RoutineController routine) {
    final shelf = context.watch<ShelfController>();
    final settings = context.watch<SettingsController>().settings;
    final isMorning = slot == RoutineSlot.morning;
    final entries = routine.entriesOn(slot, _selected);
    final done = routine.doneCount(slot, _selected);
    final title = isMorning ? 'Sabah Rutini' : 'Akşam Rutini';
    final time = isMorning ? settings.morningTime : settings.eveningTime;
    final isFuture = _selected.isAfter(dateOnly(DateTime.now()));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: isMorning
                      ? AppGradients.morning
                      : AppGradients.evening,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isMorning
                      ? Icons.wb_sunny_outlined
                      : Icons.nightlight_outlined,
                  color: Colors.white,
                  size: 17,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.lightGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 10,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            entries.isEmpty
                                ? time
                                : '$time • $done/${entries.length} tamamlandı',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _openEditor(slot),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.lightGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Düzenle',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (entries.isEmpty)
            _emptySlot(slot, hasAny: routine.entries(slot).isNotEmpty)
          else
            for (final entry in entries)
              if (shelf.byId(entry.shelfItemId) case final item?)
                Builder(
                  builder: (context) {
                    final completed = routine.isDone(entry.id, _selected);
                    return Semantics(
                      button: true,
                      label:
                          '${item.name}, ${completed ? 'tamamlandı' : 'bekliyor'}',
                      child: GestureDetector(
                        onTap: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => RoutineItemDetailModal(
                            entry: entry,
                            item: item,
                            day: _selected,
                          ),
                        ),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: completed ? 0.55 : 1,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 7),
                            padding: const EdgeInsets.all(11),
                            decoration: BoxDecoration(
                              color: AppColors.cream,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (isFuture) {
                                      showAppSnack(
                                        context,
                                        'Gelecek günler işaretlenemez',
                                        error: true,
                                        bottom: 70,
                                      );
                                      return;
                                    }
                                    routine.toggleDone(entry.id, _selected);
                                  },
                                  child: Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: completed
                                          ? AppColors.lightGreen
                                          : Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: completed
                                            ? AppColors.primary
                                            : AppColors.softGreen,
                                        width: 2,
                                      ),
                                    ),
                                    child: completed
                                        ? const Icon(
                                            Icons.check,
                                            color: AppColors.primary,
                                            size: 16,
                                          )
                                        : ClipOval(
                                            child: ProductImage(
                                              item.imageUrl,
                                              category: item.category,
                                              radius: 0,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textDark,
                                          decoration: completed
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                      ),
                                      Text(
                                        '${item.brand} • ${item.category}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.textGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  color: AppColors.textLight,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _emptySlot(RoutineSlot slot, {required bool hasAny}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.cream,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      children: [
        Text(
          hasAny
              ? 'Bu gün için planlanmış adım yok.'
              : 'Bu rutine henüz ürün eklemedin.',
          style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
        ),
        if (!hasAny)
          TextButton.icon(
            onPressed: () => _openEditor(slot),
            icon: const Icon(Icons.add, size: 16, color: AppColors.primary),
            label: const Text(
              'Ürün ekle',
              style: TextStyle(fontSize: 12, color: AppColors.primary),
            ),
          ),
      ],
    ),
  );

  Widget _statsRow(RoutineController routine, DateTime today) {
    final streak = routine.streak(DateTime.now());
    final rate = routine.completionRate(
      today.subtract(const Duration(days: 6)),
      today,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: _statCard(
              Icons.water_drop_outlined,
              AppColors.primary,
              '$streak gün',
              streak > 0
                  ? 'Seri devam ediyor 🔥'
                  : 'Bugün yeni bir seri başlat',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _statCard(
              Icons.auto_awesome_outlined,
              AppColors.peach,
              rate == null ? '-' : '%${(rate * 100).round()}',
              'Son 7 gün tamamlama',
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(IconData icon, Color color, String value, String sub) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
            ),
          ],
        ),
      );

  Widget _tipCard(DateTime today) {
    final dayOfYear = today.difference(DateTime(today.year)).inDays;
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lightbulb_outline,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Günün İpucu',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _tips[dayOfYear % _tips.length],
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
