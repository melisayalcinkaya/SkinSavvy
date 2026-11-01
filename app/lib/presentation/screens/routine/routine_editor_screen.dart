import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/skin_options.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/routine.dart';
import '../../../state/routine_controller.dart';
import '../../../state/shelf_controller.dart';
import '../../widgets/routine_warnings_card.dart';

/// Bir vaktin (sabah/akşam) rutinini düzenler: her ürün için haftanın hangi
/// günlerinde kullanılacağı. Değişiklikler anında kaydedilir.
class RoutineEditorScreen extends StatefulWidget {
  const RoutineEditorScreen({super.key, required this.slot});

  final RoutineSlot slot;

  @override
  State<RoutineEditorScreen> createState() => _RoutineEditorScreenState();
}

class _RoutineEditorScreenState extends State<RoutineEditorScreen> {
  String activeCat = 'Tümü';

  @override
  Widget build(BuildContext context) {
    final shelf = context.watch<ShelfController>();
    final routine = context.watch<RoutineController>();
    final using = shelf.using;
    final categories = [
      'Tümü',
      ...{for (final p in using) p.category},
    ];
    if (!categories.contains(activeCat)) activeCat = 'Tümü';
    final filtered = activeCat == 'Tümü'
        ? using
        : using.where((p) => p.category == activeCat).toList();
    final isMorning = widget.slot == RoutineSlot.morning;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
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
                  Expanded(
                    child: Text(
                      isMorning ? 'Sabah Rutini' : 'Akşam Rutini',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppGradients.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Tamam',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              color: AppColors.lightGreen,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.touch_app_outlined,
                    size: 13,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Ürünü o gün kullanmak için günün kutucuğuna dokun',
                      style: TextStyle(fontSize: 11, color: AppColors.textGrey),
                    ),
                  ),
                ],
              ),
            ),
            RoutineWarningsCard(
              warnings: routine.warningsFor(widget.slot),
              margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            ),
            Expanded(
              child: using.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'Dolabında kullandığın ürün yok.\nÖnce Ürünler sekmesinden ürün ekle.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textGrey,
                            height: 1.5,
                          ),
                        ),
                      ),
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          width: 84,
                          color: AppColors.cream,
                          child: ListView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 8,
                            ),
                            children: [
                              for (final c in categories)
                                GestureDetector(
                                  onTap: () => setState(() => activeCat = c),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 4),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 9,
                                      horizontal: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: activeCat == c
                                          ? Colors.white
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(14),
                                      border: activeCat == c
                                          ? Border.all(
                                              color: AppColors.softGreen,
                                            )
                                          : null,
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          width: 34,
                                          height: 34,
                                          decoration: BoxDecoration(
                                            gradient: activeCat == c
                                                ? AppGradients.primary
                                                : null,
                                            color: activeCat == c
                                                ? null
                                                : AppColors.softGreen,
                                            borderRadius: BorderRadius.circular(
                                              11,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              c == 'Tümü'
                                                  ? '🌿'
                                                  : categoryEmoji(c),
                                              style: const TextStyle(
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          c,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w500,
                                            color: activeCat == c
                                                ? AppColors.primary
                                                : AppColors.textGrey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.all(10),
                            children: [
                              for (final p in filtered)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 7),
                                  padding: const EdgeInsets.all(9),
                                  decoration: BoxDecoration(
                                    color: AppColors.cream,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            9,
                                          ),
                                          border: Border.all(
                                            color: AppColors.softGreen,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            categoryEmoji(p.category),
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 9),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              p.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: AppColors.textDark,
                                              ),
                                            ),
                                            Text(
                                              p.brand,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: AppColors.textGrey,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Wrap(
                                              spacing: 3,
                                              runSpacing: 3,
                                              children: [
                                                for (
                                                  var day = 1;
                                                  day <= 7;
                                                  day++
                                                )
                                                  _dayBox(
                                                    day,
                                                    on:
                                                        routine
                                                            .entryFor(
                                                              p.id,
                                                              widget.slot,
                                                            )
                                                            ?.weekdays
                                                            .contains(day) ??
                                                        false,
                                                    onTap: () =>
                                                        routine.toggleWeekday(
                                                          p.id,
                                                          widget.slot,
                                                          day,
                                                        ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dayBox(int day, {required bool on, required VoidCallback onTap}) =>
      Semantics(
        button: true,
        toggled: on,
        label: weekdayShort[day - 1],
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              gradient: on ? AppGradients.primary : null,
              color: on ? null : AppColors.softGreen,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                weekdayLetter[day - 1],
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: on ? Colors.white : AppColors.textLight,
                ),
              ),
            ),
          ),
        ),
      );
}
