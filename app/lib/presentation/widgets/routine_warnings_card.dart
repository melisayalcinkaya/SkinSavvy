import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/routine.dart';
import '../../domain/ingredients/ingredient_analyzer.dart';
import '../../domain/ingredients/routine_advisor.dart';

/// "Pzt, Çar, Cum" / "Her gün"
String weekdaysLabel(Set<int> days) {
  if (days.isEmpty || days.length == 7) return 'Her gün';
  final sorted = days.toList()..sort();
  return sorted.map((d) => weekdayShort[d - 1]).join(', ');
}

/// Rutindeki ürün çakışmalarını listeleyen kart. Uyarı yoksa hiçbir şey çizmez.
class RoutineWarningsCard extends StatelessWidget {
  const RoutineWarningsCard({
    super.key,
    required this.warnings,
    this.margin = const EdgeInsets.fromLTRB(14, 0, 14, 12),
  });

  final List<RoutineWarning> warnings;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    if (warnings.isEmpty) return const SizedBox.shrink();
    final serious = warnings.any((w) => w.level == FindingLevel.caution);
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: serious ? const Color(0xFFFFF3E3) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: serious ? const Color(0xFFF6D3A8) : AppColors.softGreen,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                serious ? Icons.warning_amber_rounded : Icons.info_outline,
                size: 17,
                color: serious ? const Color(0xFFB4651F) : AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                serious ? 'Rutin uyarıları' : 'Rutin notları',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          for (final w in warnings) _WarningRow(w),
        ],
      ),
    );
  }
}

class _WarningRow extends StatelessWidget {
  const _WarningRow(this.w);

  final RoutineWarning w;

  @override
  Widget build(BuildContext context) {
    final where = [
      if (w.slot != null) w.slot == RoutineSlot.morning ? 'Sabah' : 'Akşam',
      if (w.weekdays.isNotEmpty) weekdaysLabel(w.weekdays),
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            w.title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: w.level == FindingLevel.caution
                  ? const Color(0xFFB4651F)
                  : AppColors.textDark,
            ),
          ),
          if (where.isNotEmpty || w.products.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              [
                where,
                w.products.join(' + '),
              ].where((s) => s.isNotEmpty).join(' — '),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textGrey,
              ),
            ),
          ],
          const SizedBox(height: 2),
          Text(
            w.detail,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textGrey,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
