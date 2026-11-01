import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import 'product_detail_screen.dart';
import '../shared/add_product_modal.dart';
import 'add_product_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});
  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String query = '';
  String category = 'Tümü';
  final categories = ['Tümü', 'Temizleyici', 'Nemlendirici', 'Serum', 'Güneş'];

  final List<ProductModel> products = [
    ProductModel(
        id: 'p1',
        name: 'Hydrating Cleanser',
        brand: 'CeraVe',
        category: 'Temizleyici',
        imageUrl:
            'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=300',
        price: 299.90,
        rating: 4.8,
        reviewCount: 1240,
        badge: 'Popüler'),
    ProductModel(
        id: 'p2',
        name: 'Vitamin C Serum',
        brand: 'The Ordinary',
        category: 'Serum',
        imageUrl:
            'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?w=300',
        price: 449.90,
        rating: 4.9,
        reviewCount: 2150,
        badge: 'Çok Satan',
        isFavorite: true),
    ProductModel(
        id: 'p3',
        name: 'Moisturizer',
        brand: 'La Roche-Posay',
        category: 'Nemlendirici',
        imageUrl:
            'https://images.unsplash.com/photo-1608248543803-ba4f8c70ae0b?w=300',
        price: 549.90,
        rating: 4.7,
        reviewCount: 890),
    ProductModel(
        id: 'p4',
        name: 'SPF 50+ Sunscreen',
        brand: 'Bioderma',
        category: 'Güneş',
        imageUrl:
            'https://images.unsplash.com/photo-1556228578-8c89e6adf883?w=300',
        price: 389.90,
        rating: 4.9,
        reviewCount: 1580,
        badge: 'Önerilen'),
  ];

  List<ProductModel> get filtered => products.where((p) {
        final matchQ = query.isEmpty ||
            p.name.toLowerCase().contains(query) ||
            p.brand.toLowerCase().contains(query);
        final matchC = category == 'Tümü' || p.category == category;
        return matchQ && matchC;
      }).toList();

  void _showAddModal(ProductModel p) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) =>
            AddProductModal(productName: p.name, productBrand: p.brand));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: SafeArea(
          child: Column(children: [
            _header(),
            Expanded(
              child:
                  ListView(padding: const EdgeInsets.only(top: 12), children: [
                if (query.isEmpty) _recommendBanner(),
                _grid(),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _header() => Container(
        color: Colors.white.withOpacity(0.95),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(children: [
          const Row(children: [
            Expanded(
                child: Text('Ürünler',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDark)))
          ]),
          const SizedBox(height: 10),
          TextField(
            onChanged: (v) => setState(() => query = v.toLowerCase()),
            decoration: const InputDecoration(
                hintText: 'Ürün veya marka ara...',
                prefixIcon: Icon(Icons.search, color: AppColors.textLight)),
          ),
          const SizedBox(height: 10),
          SizedBox(
              height: 32,
              child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final active = category == categories[i];
                    return GestureDetector(
                        onTap: () => setState(() => category = categories[i]),
                        child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                                gradient: active ? AppGradients.primary : null,
                                color: active ? null : Colors.white,
                                borderRadius: BorderRadius.circular(20)),
                            child: Text(categories[i],
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: active
                                        ? Colors.white
                                        : AppColors.textGrey))));
                  })),
        ]),
      );

  Widget _recommendBanner() => Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.lightGreen, width: 1.5)),
        child: Row(children: [
          const Icon(Icons.auto_fix_high, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          const Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Size Özel Öneriler',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDark)),
                Text('Karma cilt + sivilce/leke odaklı seçimler',
                    style: TextStyle(fontSize: 10, color: AppColors.textGrey)),
              ])),
        ]),
      );

  Widget _grid() {
    if (filtered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                  color: AppColors.lightGreen, shape: BoxShape.circle),
              child: const Icon(Icons.search_off_outlined,
                  color: AppColors.primary, size: 32),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ürün bulunamadı',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark),
            ),
            const SizedBox(height: 6),
            const Text(
              'Aradığın ürün sistemde yok olabilir.\nSen eklemek ister misin?',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12, color: AppColors.textGrey, height: 1.5),
            ),
            const SizedBox(height: 20),
            DecoratedBox(
              decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: BorderRadius.circular(14)),
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddProductScreen()),
                ),
                icon: const Icon(Icons.add, color: Colors.white, size: 18),
                label: const Text(
                  'Bu ürünü sisteme ekle',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: filtered.length,
      itemBuilder: (_, i) {
        final p = filtered[i];
        return GestureDetector(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ProductDetailScreen(product: p))),
          child: Container(
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                  flex: 3,
                  child: Stack(children: [
                    ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                        child: Image.network(p.imageUrl,
                            fit: BoxFit.cover, width: double.infinity)),
                    if (p.badge != null)
                      Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                  gradient: AppGradients.badge,
                                  borderRadius: BorderRadius.circular(20)),
                              child: Text(p.badge!,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600)))),
                    Positioned(
                        top: 6,
                        right: 6,
                        child: GestureDetector(
                            onTap: () =>
                                setState(() => p.isFavorite = !p.isFavorite),
                            child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    shape: BoxShape.circle),
                                child: Icon(
                                    p.isFavorite
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    size: 13,
                                    color: p.isFavorite
                                        ? AppColors.primary
                                        : AppColors.textLight)))),
                  ])),
              Expanded(
                  flex: 2,
                  child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(p.brand,
                                style: const TextStyle(
                                    fontSize: 9,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500)),
                            Text(p.name,
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textDark),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            Row(children: [
                              const Icon(Icons.star,
                                  size: 11, color: AppColors.peach),
                              const SizedBox(width: 3),
                              Text('${p.rating}',
                                  style: const TextStyle(
                                      fontSize: 10, color: AppColors.textDark)),
                              const SizedBox(width: 3),
                              Text('(${p.reviewCount})',
                                  style: const TextStyle(
                                      fontSize: 9, color: AppColors.textLight)),
                            ]),
                            Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('₺${p.price}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textDark)),
                                  GestureDetector(
                                      onTap: () => _showAddModal(p),
                                      child: Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                              gradient: AppGradients.primary,
                                              borderRadius:
                                                  BorderRadius.circular(7)),
                                          child: const Icon(Icons.add,
                                              color: Colors.white, size: 14))),
                                ]),
                          ]))),
            ]),
          ),
        );
      },
    );
  }
}
