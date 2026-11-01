import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/product.dart';
import '../../../data/models/user.dart';
import '../../../data/remote/api_client.dart';
import '../../../domain/ingredients/ingredient_analyzer.dart';
import '../../../state/catalog_controller.dart';
import '../../widgets/analysis_card.dart';
import '../../widgets/app_snack.dart';
import '../../widgets/product_image.dart';

/// Ret gerekçesi için hazır seçenekler; kullanıcı kendi metnini de yazabilir.
const rejectReasons = [
  'İçerik listesi eksik ya da okunamıyor.',
  'Bu ürün katalogda zaten var.',
  'Fotoğraf ürünü göstermiyor.',
  'Kozmetik / cilt bakım ürünü değil.',
  'Ad veya marka hatalı yazılmış.',
];

/// SkinSavvy ekibinin (yönetici) onay kuyruğu.
///
/// Kullanıcıların önerdiği ürünler burada incelenir: onaylanan ürün herkese
/// açılır, reddedilenin gerekçesi önerene bildirim olarak gider.
class ModerationScreen extends StatelessWidget {
  const ModerationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogController>();
    final queue = catalog.reviewQueue;
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(6, 6, 16, 10),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Onay Bekleyen Ürünler',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          queue.isEmpty
                              ? 'Kuyruk boş'
                              : '${queue.length} öneri inceleme bekliyor',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: catalog.reload,
                child: queue.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [_Empty()],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(14),
                        itemCount: queue.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _SubmissionCard(
                          queue[i],
                          key: ValueKey(queue[i].id),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubmissionCard extends StatefulWidget {
  const _SubmissionCard(this.p, {super.key});

  final Product p;

  @override
  State<_SubmissionCard> createState() => _SubmissionCardState();
}

class _SubmissionCardState extends State<_SubmissionCard> {
  bool _busy = false;
  bool _showIngredients = false;

  Future<void> _run(Future<void> Function() action, String done) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) showAppSnack(context, done);
    } on ApiException catch (e) {
      if (mounted) showAppSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject() async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _RejectSheet(),
    );
    if (reason == null || !mounted) return;
    final catalog = context.read<CatalogController>();
    await _run(
      () => catalog.reject(widget.p.id, reason),
      'Öneri reddedildi, gerekçe önerene iletildi',
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    // Profilden bağımsız analiz: yalnızca kaç içeriğin tanındığına bakılır.
    final analysis = const IngredientAnalyzer().analyze(
      p.ingredients,
      const SkinProfile(),
    );
    final created = DateTime.tryParse(p.createdAt ?? '');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProductImage(
                p.imageUrl,
                width: 72,
                height: 72,
                category: p.category,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.brand,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      p.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        'Öneren: ${p.addedBy ?? 'kullanıcı'}',
                        if (created != null) formatDateShort(created.toLocal()),
                      ].join(' · '),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final t in [
                p.category,
                ...p.skinTypes,
                if (p.barcode != null) 'Barkod ${p.barcode}',
              ])
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.lightGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    t,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          if (p.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              p.description,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textGrey,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 8),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() => _showIngredients = !_showIngredients),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    analysis.entries.isEmpty ||
                            analysis.knownCount / analysis.entries.length < 0.5
                        ? Icons.error_outline
                        : Icons.check_circle_outline,
                    size: 15,
                    color:
                        analysis.entries.isEmpty ||
                            analysis.knownCount / analysis.entries.length < 0.5
                        ? AppColors.accent
                        : AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${p.ingredients.length} içerikten ${analysis.knownCount} '
                      'tanesi bilgi tabanında tanındı',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  Icon(
                    _showIngredients ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: AppColors.textLight,
                  ),
                ],
              ),
            ),
          ),
          if (_showIngredients) AnalysisCard(analysis: analysis),
          const SizedBox(height: 12),
          if (_busy)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _reject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      side: const BorderSide(color: AppColors.accent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reddet'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppGradients.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => _run(
                        () => context.read<CatalogController>().approve(p.id),
                        '"${p.name}" onaylandı, artık herkes görebilir',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Onayla'),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _RejectSheet extends StatefulWidget {
  const _RejectSheet();

  @override
  State<_RejectSheet> createState() => _RejectSheetState();
}

class _RejectSheetState extends State<_RejectSheet> {
  String? _choice = rejectReasons.first;
  final _custom = TextEditingController();

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  String? get _reason {
    final text = _custom.text.trim();
    if (_choice == null) return text.length >= 3 ? text : null;
    return text.isEmpty ? _choice : '$_choice $text';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
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
              const Text(
                'Neden reddediyorsun?',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Gerekçe yalnızca ürünü önerene gösterilir; düzeltip yeniden gönderebilir.',
                style: TextStyle(fontSize: 11, color: AppColors.textGrey),
              ),
              const SizedBox(height: 8),
              RadioGroup<String?>(
                groupValue: _choice,
                onChanged: (v) => setState(() => _choice = v),
                child: Column(
                  children: [
                    for (final r in [...rejectReasons, null])
                      RadioListTile<String?>(
                        value: r,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        activeColor: AppColors.primary,
                        title: Text(
                          r ?? 'Başka bir neden (aşağıya yaz)',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              TextField(
                controller: _custom,
                maxLength: 200,
                maxLines: 2,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Not ekle (isteğe bağlı)',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _reason == null
                      ? null
                      : () => Navigator.pop(context, _reason),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Reddet ve bildir'),
                ),
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
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.fromLTRB(32, 80, 32, 32),
    child: Column(
      children: [
        Icon(Icons.inbox_outlined, size: 44, color: AppColors.textLight),
        SizedBox(height: 10),
        Text(
          'İncelenecek öneri yok',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textDark,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Kullanıcılar katalogda bulamadıkları ürünleri önerdiğinde burada görünür.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textGrey,
            height: 1.45,
          ),
        ),
      ],
    ),
  );
}
