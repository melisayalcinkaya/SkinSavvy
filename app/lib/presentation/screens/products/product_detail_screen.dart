import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/product.dart';
import '../../../data/remote/api_client.dart';
import '../../../state/catalog_controller.dart';
import '../../../state/shelf_controller.dart';
import '../../widgets/analysis_card.dart';
import '../../widgets/app_snack.dart';
import '../../widgets/product_image.dart';
import '../../widgets/server_widgets.dart';
import '../moderation/moderation_edit_screen.dart';
import '../shared/add_product_modal.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogController>();
    final found = catalog.byId(productId);
    // Yinelenen öneri asıl ürünü gösterir; silinen öneri açılmaz.
    final p = found != null && found.isDuplicate
        ? catalog.byId(found.duplicateOf)
        : found;
    if (p == null && catalog.isRemote && !catalog.fetchTried(productId)) {
      // Listede olmayan ürün (ör. dolapta duran, katalogdan kaldırılmış):
      // sunucudan bir kez getirilir.
      catalog.ensureLoaded(productId);
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (p == null || p.isRemoved) {
      return const Scaffold(body: Center(child: Text('Ürün bulunamadı.')));
    }
    final isFav = catalog.isFavorite(p.id);
    final inShelf = context.select<ShelfController, bool>(
      (s) => s.activeForProduct(p.id) != null,
    );
    final mine = catalog.submissions.any((s) => s.id == p.id);
    final teamActions = catalog.isAdmin && (p.isApproved || p.isDelisted);
    final badge = p.isPending
        ? 'Onay bekliyor'
        : p.isDelisted
        ? 'Katalogdan kaldırıldı'
        : p.isNew(DateTime.now())
        ? 'Yeni'
        : null;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
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
                  const Spacer(),
                  IconButton(
                    tooltip: isFav ? 'Favorilerden çıkar' : 'Favorilere ekle',
                    onPressed: () => catalog.toggleFavorite(p.id),
                    icon: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: AppColors.lightGreen,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        size: 16,
                        color: isFav ? AppColors.primary : AppColors.textDark,
                      ),
                    ),
                  ),
                  if (teamActions) _TeamMenu(product: p),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  // Ürün görselleri kare; sabit 220 px yükseklik telefonda
                  // görselin yarısını kırpıyordu. Telefonda yükseklik genişliğe
                  // göre büyür, geniş ekranda görsel kırpılmadan ortalanır.
                  LayoutBuilder(
                    builder: (context, box) {
                      final wide = box.maxWidth > 600;
                      return SizedBox(
                        height: wide
                            ? 360
                            : (box.maxWidth * 0.85).clamp(260, 360),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ProductImage(
                              p.imageUrl,
                              category: p.category,
                              radius: 0,
                              fit: wide ? BoxFit.contain : BoxFit.cover,
                            ),
                            if (badge != null)
                              Positioned(
                                top: 10,
                                left: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: p.isPending || p.isDelisted
                                        ? null
                                        : AppGradients.badge,
                                    color: p.isPending
                                        ? AppColors.secondary
                                        : p.isDelisted
                                        ? AppColors.textGrey
                                        : null,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    badge,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
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
                        const SizedBox(height: 4),
                        Text(
                          p.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            if (p.reviewCount > 0) ...[
                              const Icon(
                                Icons.star,
                                color: AppColors.peach,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${p.rating}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '(${p.reviewCount} değerlendirme)',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textGrey,
                                ),
                              ),
                            ] else
                              const Text(
                                'Henüz değerlendirme yok',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textGrey,
                                ),
                              ),
                          ],
                        ),
                        if (p.addedBy != null || p.approvedDate != null) ...[
                          const SizedBox(height: 6),
                          // Ürünü topluluktan biri ekledi, ekip onayladı.
                          Row(
                            children: [
                              const Icon(
                                Icons.groups_outlined,
                                size: 14,
                                color: AppColors.textLight,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  [
                                    if (p.addedBy != null)
                                      'Ekleyen: ${p.addedBy}',
                                    if (p.approvedDate != null)
                                      'onay: ${formatDateShort(p.approvedDate)}',
                                  ].join(' · '),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textLight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (p.skinTypes.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final t in [p.category, ...p.skinTypes])
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
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
                        ],
                        if (p.description.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            p.description,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textGrey,
                              height: 1.5,
                            ),
                          ),
                        ],
                        if (p.benefits.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _infoCard('Faydaları', p.benefits),
                        ],
                        if (p.isDelisted) ...[
                          const SizedBox(height: 12),
                          _notice(
                            Icons.inventory_2_outlined,
                            inShelf
                                ? 'Bu ürün katalogdan kaldırıldı. Dolabındaki '
                                      'kaydın ve yorumun duruyor; dilediğin '
                                      'zaman kendin çıkarabilirsin.'
                                : 'Bu ürün katalogdan kaldırıldı; artık '
                                      'dolaba eklenemiyor.',
                          ),
                        ],
                        if (p.isPending && mine) ...[
                          const SizedBox(height: 12),
                          _WithdrawButton(product: p),
                        ],
                        const SizedBox(height: 10),
                        AnalysisCard(
                          analysis: analyzeForUser(context, p.ingredients),
                        ),
                        if (!p.isPending) CommunityReviews(productId: p.id),
                        const SizedBox(height: 16),
                        _addButton(context, p, inShelf),
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

  Widget _notice(IconData icon, String text) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.softGreen),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textGrey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textDark,
              height: 1.5,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _addButton(BuildContext context, Product p, bool inShelf) {
    // Katalogdan kaldırılan ürün yeni kullanıcıların dolabına eklenemez.
    if (p.isDelisted && !inShelf) return const SizedBox.shrink();
    if (inShelf) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.lightGreen,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: AppColors.primary, size: 18),
            SizedBox(width: 6),
            Text(
              'Bu ürün dolabında',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppGradients.primary,
          borderRadius: BorderRadius.circular(14),
        ),
        child: ElevatedButton(
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => AddProductModal(product: p),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: Colors.white, size: 18),
              SizedBox(width: 6),
              Text(
                'Ürünlerime Ekle',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard(String title, List<String> items) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
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
        const SizedBox(height: 8),
        ...items.map(
          (t) => Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              children: [
                const Icon(Icons.check, size: 14, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textGrey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

/// Ekibin katalogdaki ürün için işlemleri: düzenle, kaldır / geri al.
class _TeamMenu extends StatelessWidget {
  const _TeamMenu({required this.product});

  final Product product;

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
    String done,
  ) async {
    try {
      await action();
      if (context.mounted) showAppSnack(context, done);
    } on ApiException catch (e) {
      if (context.mounted) showAppSnack(context, e.message, error: true);
    } on StateError catch (e) {
      if (context.mounted) showAppSnack(context, e.message, error: true);
    }
  }

  Future<void> _onSelected(BuildContext context, String action) async {
    final catalog = context.read<CatalogController>();
    final p = product;
    switch (action) {
      case 'edit':
        final edited = await Navigator.push<Product>(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ModerationEditScreen(product: p, catalogProduct: true),
          ),
        );
        if (edited == null || !context.mounted) return;
        await _run(
          context,
          () => catalog.editProduct(p.id, edited),
          'Ürün bilgileri güncellendi',
        );
      case 'delist':
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text(
              'Katalogdan kaldır',
              style: TextStyle(fontSize: 16),
            ),
            content: const Text(
              'Ürün aramada ve katalogda görünmez, yeni kullanıcılar dolabına '
              'ekleyemez. Dolabına eklemiş olanların kaydı ve yorumu durur. '
              'İstediğin zaman geri alabilirsin.',
              style: TextStyle(fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Vazgeç'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: AppColors.accent),
                child: const Text('Kaldır'),
              ),
            ],
          ),
        );
        if (ok != true || !context.mounted) return;
        await _run(
          context,
          () => catalog.delist(p.id),
          '"${p.name}" katalogdan kaldırıldı',
        );
      case 'relist':
        await _run(
          context,
          () => catalog.relist(p.id),
          '"${p.name}" kataloğa geri alındı',
        );
    }
  }

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    tooltip: 'Ekip işlemleri',
    icon: const Icon(Icons.more_vert, color: AppColors.textDark),
    onSelected: (a) => _onSelected(context, a),
    itemBuilder: (_) => [
      const PopupMenuItem(
        value: 'edit',
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.edit_outlined),
          title: Text('Düzenle'),
        ),
      ),
      if (product.isApproved)
        const PopupMenuItem(
          value: 'delist',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.inventory_2_outlined),
            title: Text('Katalogdan kaldır'),
          ),
        )
      else
        const PopupMenuItem(
          value: 'relist',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.undo),
            title: Text('Kataloğa geri al'),
          ),
        ),
    ],
  );
}

/// Kullanıcının, ekip bakmadan önce kendi önerisini geri çekmesi.
class _WithdrawButton extends StatelessWidget {
  const _WithdrawButton({required this.product});

  final Product product;

  Future<void> _withdraw(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Öneriyi geri çek', style: TextStyle(fontSize: 16)),
        content: const Text(
          'Öneri silinir ve dolabından da kalkar. Ekip henüz bakmadığı için '
          'kimse görmemiş olur.',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.accent),
            child: const Text('Geri çek'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final catalog = context.read<CatalogController>();
    final shelf = context.read<ShelfController>();
    try {
      await catalog.withdraw(product.id);
      // Öneriyle birlikte dolaptaki kaydı da kalkar.
      for (final item in shelf.all.where((e) => e.productId == product.id)) {
        shelf.remove(item.id);
      }
      if (!context.mounted) return;
      showAppSnack(context, 'Öneri geri çekildi');
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (context.mounted) showAppSnack(context, e.message, error: true);
    } on StateError catch (e) {
      if (context.mounted) showAppSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      onPressed: () => _withdraw(context),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.accent,
        side: BorderSide(color: AppColors.accent.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: const Icon(Icons.undo, size: 18),
      label: const Text('Öneriyi geri çek'),
    ),
  );
}
