import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/text_utils.dart';
import '../../../data/models/product.dart';
import '../../../data/models/user.dart';
import '../../../state/catalog_controller.dart';
import '../../../state/session_controller.dart';
import '../../widgets/product_image.dart';
import '../shared/add_product_modal.dart';
import 'add_product_screen.dart';
import 'product_detail_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});
  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String query = '';
  String category = 'Tümü';
  bool onlySuitable = false;

  /// Profildeki cilt tipine uygun mu? Ürün cilt tipi belirtmemişse uygun sayılır.
  static bool suits(Product p, SkinProfile profile) =>
      profile.skinType == null ||
      p.skinTypes.isEmpty ||
      p.skinTypes.contains('Tüm Cilt Tipleri') ||
      p.skinTypes.contains(profile.skinType);

  void _showAddModal(Product p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddProductModal(product: p),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogController>();
    final profile = context.select<SessionController, SkinProfile>(
      (s) => s.user?.skinProfile ?? const SkinProfile(),
    );
    final categories = [
      'Tümü',
      ...{for (final p in catalog.products) p.category},
    ];
    var results = catalog.search(query: query, category: category);
    if (onlySuitable) {
      results = results.where((p) => suits(p, profile)).toList();
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: SafeArea(
          child: Column(
            children: [
              _header(categories),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(top: 12, bottom: 16),
                  children: [
                    if (query.isEmpty && profile.skinType != null)
                      _recommendBanner(profile),
                    _grid(results, catalog),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(List<String> categories) => Container(
    color: Colors.white.withValues(alpha: 0.95),
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
    child: Column(
      children: [
        const Row(
          children: [
            Expanded(
              child: Text(
                'Ürünler',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          onChanged: (v) => setState(() => query = v),
          decoration: const InputDecoration(
            hintText: 'Ürün veya marka ara...',
            prefixIcon: Icon(Icons.search, color: AppColors.textLight),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 32,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final active = category == categories[i];
              return GestureDetector(
                onTap: () => setState(() => category = categories[i]),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    gradient: active ? AppGradients.primary : null,
                    color: active ? null : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    categories[i],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: active ? Colors.white : AppColors.textGrey,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );

  Widget _recommendBanner(SkinProfile profile) {
    final focus = profile.concerns
        .map((c) => c.split(' / ').first.toLowerCase())
        .join(', ');
    final subtitle = [
      profile.skinType!.toLowerCase(),
      if (focus.isNotEmpty) '$focus odaklı',
    ].join(' • ');
    return GestureDetector(
      onTap: () => setState(() => onlySuitable = !onlySuitable),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: onlySuitable ? AppColors.lightGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: onlySuitable ? AppColors.primary : AppColors.lightGreen,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.auto_fix_high, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Size Özel Öneriler',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    onlySuitable
                        ? 'Yalnızca cilt tipinize uygun ürünler gösteriliyor'
                        : 'Cilt tipiniz: $subtitle',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: onlySuitable,
              activeThumbColor: AppColors.primary,
              onChanged: (v) => setState(() => onlySuitable = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: AppColors.lightGreen,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.search_off_outlined,
            color: AppColors.primary,
            size: 32,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Ürün bulunamadı',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Aradığın ürün sistemde yok olabilir.\nSen eklemek ister misin?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textGrey,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppGradients.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddProductScreen(initialName: query),
              ),
            ),
            icon: const Icon(Icons.add, color: Colors.white, size: 18),
            label: const Text(
              'Bu ürünü sisteme ekle',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _grid(List<Product> items, CatalogController catalog) {
    if (items.isEmpty) return _emptyState();
    return LayoutBuilder(
      builder: (context, constraints) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          // Geniş ekranda (tablet/web) daha çok sütun.
          crossAxisCount: (constraints.maxWidth / 190).floor().clamp(2, 5),
          childAspectRatio: 0.72,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: items.length,
        itemBuilder: (_, i) => _card(items[i], catalog),
      ),
    );
  }

  Widget _card(Product p, CatalogController catalog) {
    final fav = catalog.isFavorite(p.id);
    final badge = p.isPending ? 'Onay bekliyor' : p.badge;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: p.id)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ProductImage(
                      p.imageUrl,
                      category: p.category,
                      radius: 0,
                    ),
                  ),
                  if (badge != null)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          gradient: p.isPending ? null : AppGradients.badge,
                          color: p.isPending ? AppColors.secondary : null,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: IconButton(
                      tooltip: fav ? 'Favorilerden çıkar' : 'Favorilere ekle',
                      onPressed: () => catalog.toggleFavorite(p.id),
                      icon: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          fav ? Icons.favorite : Icons.favorite_border,
                          size: 14,
                          color: fav ? AppColors.primary : AppColors.textLight,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      p.brand,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      p.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (p.reviewCount > 0)
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 11,
                            color: AppColors.peach,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${p.rating}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '(${p.reviewCount})',
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formatPrice(p.price),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textDark,
                          ),
                        ),
                        Semantics(
                          button: true,
                          label: 'Dolabıma ekle',
                          child: GestureDetector(
                            onTap: () => _showAddModal(p),
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                gradient: AppGradients.primary,
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
