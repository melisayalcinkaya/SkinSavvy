import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/text_utils.dart';
import '../../../data/models/product.dart';
import '../../../data/models/user.dart';
import '../../../data/remote/api_client.dart';
import '../../../domain/ingredients/ingredient_analyzer.dart';
import '../../../state/catalog_controller.dart';
import '../../widgets/analysis_card.dart';
import '../../widgets/app_snack.dart';
import '../../widgets/product_image.dart';
import 'moderation_edit_screen.dart';

/// SkinSavvy ekibinin (yönetici) onay kuyruğu.
///
/// Kullanıcıların önerdiği ürünler burada incelenir. Reddetme yoktur; ekip
/// her öneri için şu kararlardan birini verir ve önerene bildirim gider:
///
/// - **Onayla** ya da **Düzenle ve onayla**: eksik/hatalı bilgiyi ekip
///   düzeltir, ürün herkese açılır;
/// - **Yinelenen**: ürün katalogda zaten var; öneri asıl ürüne bağlanır;
/// - **Sil**: spam/sahte öneri katalogdan ve önerenin dolabından kalkar.
class ModerationScreen extends StatelessWidget {
  const ModerationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogController>();
    final queue = catalog.reviewQueue;
    final delisted = catalog.delisted;
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
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(14),
                  children: [
                    if (queue.isEmpty) const _Empty(),
                    for (final p in queue) ...[
                      _SubmissionCard(p, key: ValueKey(p.id)),
                      const SizedBox(height: 12),
                    ],
                    // Katalogdan kaldırılan ürünler aramada görünmez; ekip
                    // geri almak için buradan ulaşır.
                    if (delisted.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Katalogdan kaldırılanlar (${delisted.length})',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final p in delisted) _DelistedTile(p),
                    ],
                  ],
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
    } on StateError catch (e) {
      if (mounted) showAppSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editAndApprove() async {
    final edited = await Navigator.push<Product>(
      context,
      MaterialPageRoute(
        builder: (_) => ModerationEditScreen(product: widget.p),
      ),
    );
    if (edited == null || !mounted) return;
    final catalog = context.read<CatalogController>();
    await _run(
      () => catalog.approve(widget.p.id, edited: edited),
      '"${edited.name}" düzeltilip onaylandı',
    );
  }

  Future<void> _markDuplicate([Product? suggested]) async {
    final original =
        suggested ??
        await showModalBottomSheet<Product>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _DuplicatePicker(submission: widget.p),
        );
    if (original == null || !mounted) return;
    final ok = await _confirm(
      title: 'Yinelenen olarak işaretle',
      body:
          'Öneri "${original.brand} ${original.name}" ürününe bağlanacak. '
          'Önerenin dolabındaki kayıt tarihleri ve notlarıyla birlikte asıl '
          'ürüne taşınır.',
      action: 'Asıl ürüne bağla',
    );
    if (!ok || !mounted) return;
    final catalog = context.read<CatalogController>();
    await _run(
      () => catalog.markDuplicate(widget.p.id, original.id),
      'Öneri "${original.name}" ürününe bağlandı',
    );
  }

  Future<void> _remove() async {
    final ok = await _confirm(
      title: 'Spam/sahte olarak sil',
      body:
          'Öneri katalogdan ve önerenin dolabından kaldırılır; önerene '
          'bildirim gider. Bu işlem geri alınamaz.',
      action: 'Sil',
      destructive: true,
    );
    if (!ok || !mounted) return;
    final catalog = context.read<CatalogController>();
    await _run(() => catalog.remove(widget.p.id), 'Öneri silindi');
  }

  Future<bool> _confirm({
    required String title,
    required String body,
    required String action,
    bool destructive = false,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title, style: const TextStyle(fontSize: 16)),
          content: Text(body, style: const TextStyle(fontSize: 13)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Vazgeç'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(
                foregroundColor: destructive
                    ? AppColors.accent
                    : AppColors.primary,
              ),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    // Profilden bağımsız analiz: yalnızca kaç içeriğin tanındığına bakılır.
    final analysis = const IngredientAnalyzer().analyze(
      p.ingredients,
      const SkinProfile(),
    );
    final created = DateTime.tryParse(p.createdAt ?? '');
    final similar = similarProducts(context.watch<CatalogController>(), p);
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
                width: 88,
                height: 88,
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
          if (similar.isNotEmpty) ...[
            const SizedBox(height: 8),
            _SimilarHint(
              product: similar.first,
              onLink: _busy ? null : () => _markDuplicate(similar.first),
            ),
          ],
          const SizedBox(height: 12),
          if (_busy)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
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
                const SizedBox(height: 8),
                Row(
                  children: [
                    _secondary('Düzenle', Icons.edit_outlined, _editAndApprove),
                    const SizedBox(width: 6),
                    _secondary('Yinelenen', Icons.link_rounded, _markDuplicate),
                    const SizedBox(width: 6),
                    _secondary(
                      'Sil',
                      Icons.delete_outline_rounded,
                      _remove,
                      color: AppColors.accent,
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _secondary(
    String label,
    IconData icon,
    VoidCallback onPressed, {
    Color color = AppColors.primary,
  }) => Expanded(
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.6)),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    ),
  );
}

/// Katalogda öneriye benzeyen onaylı ürünler (aynı marka, adı birbirini
/// içeren ya da aynı barkod), en olası önce. Ekibe yinelenen öneriyi
/// yakalamada ipucu verir; karar yine ekibindir.
List<Product> similarProducts(CatalogController catalog, Product p) {
  final name = searchKey(p.name);
  final brand = searchKey(p.brand);
  final scored = <(int, Product)>[];
  for (final c in catalog.products) {
    if (!c.isApproved || c.id == p.id) continue;
    var score = 0;
    if (p.barcode != null && c.barcode == p.barcode) score += 4;
    if (searchKey(c.brand) == brand) score += 2;
    final other = searchKey(c.name);
    if (other == name) {
      score += 3;
    } else if (other.contains(name) || name.contains(other)) {
      score += 1;
    }
    if (score >= 3) scored.add((score, c));
  }
  scored.sort((a, b) => b.$1.compareTo(a.$1));
  return [for (final (_, c) in scored) c];
}

class _SimilarHint extends StatelessWidget {
  const _SimilarHint({required this.product, required this.onLink});

  final Product product;
  final VoidCallback? onLink;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF3E3),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Icon(Icons.info_outline, size: 15, color: Color(0xFFB4651F)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Katalogda benzer ürün var: ${product.brand} ${product.name}',
            style: const TextStyle(fontSize: 11, color: AppColors.textDark),
          ),
        ),
        TextButton(onPressed: onLink, child: const Text('Bağla')),
      ],
    ),
  );
}

/// Yinelenen öneri için asıl ürünü seçtirir (aranabilir onaylı ürün listesi).
class _DuplicatePicker extends StatefulWidget {
  const _DuplicatePicker({required this.submission});

  final Product submission;

  @override
  State<_DuplicatePicker> createState() => _DuplicatePickerState();
}

class _DuplicatePickerState extends State<_DuplicatePicker> {
  late final _query = TextEditingController(text: widget.submission.brand);

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogController>();
    final similar = similarProducts(catalog, widget.submission);
    final found = [
      ...similar,
      for (final c in catalog.search(query: _query.text))
        if (c.isApproved && !similar.any((s) => s.id == c.id)) c,
    ];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
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
                'Asıl ürünü seç',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '"${widget.submission.name}" önerisi seçtiğin ürüne bağlanacak.',
                style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _query,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Ürün adı, marka ya da barkod',
                  prefixIcon: Icon(Icons.search, size: 20),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 6),
              Flexible(
                child: found.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Eşleşen onaylı ürün yok.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textGrey,
                          ),
                        ),
                      )
                    : ListView(
                        shrinkWrap: true,
                        children: [
                          for (final c in found)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: ProductImage(
                                c.imageUrl,
                                width: 40,
                                height: 40,
                                category: c.category,
                              ),
                              title: Text(
                                c.name,
                                style: const TextStyle(fontSize: 13),
                              ),
                              subtitle: Text(
                                [
                                  c.brand,
                                  if (similar.any((s) => s.id == c.id))
                                    'benzer',
                                ].join(' · '),
                                style: const TextStyle(fontSize: 11),
                              ),
                              onTap: () => Navigator.pop(context, c),
                            ),
                        ],
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

class _DelistedTile extends StatelessWidget {
  const _DelistedTile(this.p);

  final Product p;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        ProductImage(p.imageUrl, width: 40, height: 40, category: p.category),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
              Text(
                p.brand,
                style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () async {
            try {
              await context.read<CatalogController>().relist(p.id);
              if (context.mounted) {
                showAppSnack(context, '"${p.name}" kataloğa geri alındı');
              }
            } on ApiException catch (e) {
              if (context.mounted) {
                showAppSnack(context, e.message, error: true);
              }
            } on StateError catch (e) {
              if (context.mounted) {
                showAppSnack(context, e.message, error: true);
              }
            }
          },
          child: const Text('Geri al'),
        ),
      ],
    ),
  );
}
