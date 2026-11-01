import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/product.dart';
import '../../../state/catalog_controller.dart';
import '../../../state/shelf_controller.dart';
import '../../widgets/analysis_card.dart';
import '../../widgets/product_image.dart';
import '../../widgets/server_widgets.dart';
import '../shared/add_product_modal.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogController>();
    final p = catalog.byId(productId);
    if (p == null) {
      return const Scaffold(body: Center(child: Text('Ürün bulunamadı.')));
    }
    final isFav = catalog.isFavorite(p.id);
    final inShelf = context.select<ShelfController, bool>(
      (s) => s.activeForProduct(p.id) != null,
    );
    final badge = p.isPending
        ? 'Onay bekliyor'
        : p.isRejected
        ? 'Onaylanmadı'
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
                                    gradient: p.isPending
                                        ? null
                                        : AppGradients.badge,
                                    color: p.isPending
                                        ? AppColors.secondary
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
                        if (p.isRejected) ...[
                          const SizedBox(height: 10),
                          RejectedNotice(product: p),
                        ],
                        const SizedBox(height: 10),
                        AnalysisCard(
                          analysis: analyzeForUser(context, p.ingredients),
                        ),
                        if (!p.isPending && !p.isRejected)
                          CommunityReviews(productId: p.id),
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

  Widget _addButton(BuildContext context, Product p, bool inShelf) {
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
