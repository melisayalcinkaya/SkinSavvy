import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/user.dart';
import '../../domain/ingredients/ingredient_analyzer.dart';
import '../../domain/ingredients/ingredient_db.dart';
import '../../state/session_controller.dart';

const _warnBg = Color(0xFFFFEEE8);

/// Oturumdaki kullanıcının cilt profiline göre içerik analizi.
IngredientAnalysis analyzeForUser(
  BuildContext context,
  List<String> ingredients,
) {
  final profile = context.select<SessionController, SkinProfile>(
    (s) => s.user?.skinProfile ?? const SkinProfile(),
  );
  return const IngredientAnalyzer().analyze(ingredients, profile);
}

({String label, Color fg, Color bg, IconData icon}) verdictStyle(Verdict v) =>
    switch (v) {
      Verdict.unsuitable => (
        label: 'Profiline uygun değil',
        fg: AppColors.accent,
        bg: _warnBg,
        icon: Icons.block,
      ),
      Verdict.caution => (
        label: 'Dikkatli kullan',
        fg: const Color(0xFFB4651F),
        bg: const Color(0xFFFFF3E3),
        icon: Icons.error_outline,
      ),
      Verdict.suitable => (
        label: 'Profiline uygun',
        fg: AppColors.primary,
        bg: AppColors.lightGreen,
        icon: Icons.verified_outlined,
      ),
      Verdict.neutral => (
        label: 'Belirgin bir uyarı yok',
        fg: AppColors.textGrey,
        bg: AppColors.cream,
        icon: Icons.info_outline,
      ),
    };

/// Küçük sonuç rozeti (ürün kartları için).
class VerdictBadge extends StatelessWidget {
  const VerdictBadge(this.verdict, {super.key, this.compact = false});

  final Verdict verdict;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final s = verdictStyle(verdict);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: s.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(s.icon, size: compact ? 11 : 13, color: s.fg),
          const SizedBox(width: 4),
          Text(
            s.label,
            style: TextStyle(
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w600,
              color: s.fg,
            ),
          ),
        ],
      ),
    );
  }
}

class AnalysisCard extends StatelessWidget {
  const AnalysisCard({
    super.key,
    required this.analysis,
    this.showIngredients = true,
  });

  final IngredientAnalysis analysis;
  final bool showIngredients;

  @override
  Widget build(BuildContext context) {
    final a = analysis;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.science_outlined,
                color: AppColors.primary,
                size: 17,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'İçerik Analizi',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              VerdictBadge(a.verdict),
            ],
          ),
          if (a.entries.isEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'İçerik listesi girilmemiş; analiz yapılamadı.',
              style: TextStyle(fontSize: 12, color: AppColors.textGrey),
            ),
          ] else ...[
            const SizedBox(height: 4),
            Text(
              '${a.entries.length} içerikten ${a.knownCount} tanesi tanındı',
              style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
            ),
            for (final f in [
              ...a.warnings,
              ...a.findings.where((f) => f.level == FindingLevel.info),
              ...a.positives,
            ])
              _FindingRow(f),
            if (showIngredients) ...[
              const SizedBox(height: 12),
              const Text(
                'İçerikler (ayrıntı için dokun)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [for (final e in a.entries) _IngredientChip(e)],
              ),
            ],
          ],
          const SizedBox(height: 10),
          const Text(
            'Bilgilendirme amaçlıdır, tıbbi tavsiye değildir. Ciddi bir cilt sorununda dermatoloğa danış.',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textLight,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _FindingRow extends StatelessWidget {
  const _FindingRow(this.f);

  final Finding f;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (f.level) {
      FindingLevel.avoid => (Icons.block, AppColors.accent),
      FindingLevel.caution => (Icons.error_outline, const Color(0xFFB4651F)),
      FindingLevel.info => (Icons.info_outline, AppColors.secondary),
      FindingLevel.positive => (Icons.check_circle_outline, AppColors.primary),
    };
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  f.title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  f.detail,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textGrey,
                    height: 1.4,
                  ),
                ),
                if (f.ingredients.isNotEmpty &&
                    f.level != FindingLevel.positive)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      f.ingredients.join(', '),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w500,
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
}

const _tagLabels = <IngredientTag, String>{
  IngredientTag.fragrance: 'Koku',
  IngredientTag.fragranceAllergen: 'Koku alerjeni',
  IngredientTag.essentialOil: 'Uçucu yağ',
  IngredientTag.dryingAlcohol: 'Kurutucu alkol',
  IngredientTag.fattyAlcohol: 'Yağ alkolü',
  IngredientTag.retinoid: 'Retinoid',
  IngredientTag.aha: 'AHA',
  IngredientTag.bha: 'BHA',
  IngredientTag.pha: 'PHA',
  IngredientTag.vitaminC: 'C vitamini',
  IngredientTag.niacinamide: 'Niacinamide',
  IngredientTag.humectant: 'Nemlendirici',
  IngredientTag.ceramide: 'Bariyer',
  IngredientTag.peptide: 'Peptit',
  IngredientTag.antioxidant: 'Antioksidan',
  IngredientTag.soothing: 'Yatıştırıcı',
  IngredientTag.uvFilter: 'UV filtresi',
  IngredientTag.sulfate: 'Sülfat',
  IngredientTag.paraben: 'Paraben',
  IngredientTag.lanolin: 'Lanolin',
  IngredientTag.propyleneGlycol: 'Propilen glikol',
  IngredientTag.silicone: 'Silikon',
  IngredientTag.emollient: 'Yumuşatıcı',
  IngredientTag.benzoylPeroxide: 'Benzoil peroksit',
  IngredientTag.azelaicAcid: 'Azelaik asit',
  IngredientTag.zinc: 'Çinko',
  IngredientTag.clay: 'Kil',
  IngredientTag.preservative: 'Koruyucu',
};

class _IngredientChip extends StatelessWidget {
  const _IngredientChip(this.e);

  final IngredientEntry e;

  @override
  Widget build(BuildContext context) {
    final pore = (e.info?.comedogenic ?? 0) >= comedogenicThreshold;
    final (bg, fg) = e.flagged
        ? (_warnBg, AppColors.accent)
        : pore
        ? (const Color(0xFFFFF3E3), const Color(0xFFB4651F))
        : e.isKnown
        ? (AppColors.lightGreen, AppColors.primary)
        : (AppColors.cream, AppColors.textGrey);
    return Semantics(
      button: true,
      label: '${e.raw}${e.flagged ? ', profiline göre kaçınılacak' : ''}',
      child: GestureDetector(
        onTap: () => _showDetail(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            e.flagged ? '⚠ ${e.raw}' : e.raw,
            style: TextStyle(
              fontSize: 11,
              color: fg,
              fontWeight: e.flagged ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final info = e.info;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.softGreen,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                e.raw,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              if (info != null &&
                  info.name.toLowerCase() != e.raw.toLowerCase())
                Text(
                  info.name,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                  ),
                ),
              const SizedBox(height: 10),
              Text(
                info?.function ?? 'Bu içerik bilgi tabanımızda henüz yok.',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textDark,
                  height: 1.5,
                ),
              ),
              if (info != null && info.tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final t in info.tags)
                      if (_tagLabels[t] case final label?)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.cream,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textGrey,
                            ),
                          ),
                        ),
                  ],
                ),
              ],
              if ((info?.comedogenic ?? 0) > 0) ...[
                const SizedBox(height: 10),
                Text(
                  'Gözenek tıkama puanı: ${info!.comedogenic}/5',
                  style: TextStyle(
                    fontSize: 12,
                    color: info.comedogenic >= comedogenicThreshold
                        ? const Color(0xFFB4651F)
                        : AppColors.textGrey,
                  ),
                ),
              ],
              if (e.flagged) ...[
                const SizedBox(height: 10),
                const Text(
                  'Cilt profilinde kaçınılacak olarak işaretlediğin gruba giriyor.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
