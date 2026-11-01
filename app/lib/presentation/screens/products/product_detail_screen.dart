import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../shared/add_product_modal.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;
  const ProductDetailScreen({super.key, required this.product});
  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late bool isFav = widget.product.isFavorite;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
              child: Row(children: [
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back,
                        color: AppColors.textDark)),
                const Spacer(),
                GestureDetector(
                    onTap: () => setState(() => isFav = !isFav),
                    child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                            color: AppColors.lightGreen,
                            shape: BoxShape.circle),
                        child: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            size: 16,
                            color: isFav
                                ? AppColors.primary
                                : AppColors.textDark))),
              ])),
          Expanded(
            child: ListView(children: [
              SizedBox(
                  height: 190,
                  child: Stack(fit: StackFit.expand, children: [
                    Image.network(p.imageUrl, fit: BoxFit.cover),
                    Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                                gradient: AppGradients.badge,
                                borderRadius: BorderRadius.circular(20)),
                            child: const Text('Çok Satan',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600)))),
                  ])),
              Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.brand,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text(p.name,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textDark)),
                        const SizedBox(height: 10),
                        Row(children: [
                          const Icon(Icons.star,
                              color: AppColors.peach, size: 16),
                          const SizedBox(width: 4),
                          Text('${p.rating}',
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w500)),
                          const SizedBox(width: 6),
                          Text('(${p.reviewCount} değerlendirme)',
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.textGrey)),
                        ]),
                        const SizedBox(height: 14),
                        _infoCard('Faydaları', [
                          'Cilt tonunu eşitler',
                          'Koyu lekeleri azaltır',
                          'Anti-aging etkisi',
                        ]),
                        const SizedBox(height: 10),
                        Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(13),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16)),
                            child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('İçerik',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textDark)),
                                  SizedBox(height: 6),
                                  Text(
                                      'Aqua, L-Ascorbic Acid, Propanediol, Hyaluronic Acid, Ferulic Acid...',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textGrey,
                                          height: 1.6)),
                                ])),
                        const SizedBox(height: 16),
                        SizedBox(
                            width: double.infinity,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                  gradient: AppGradients.primary,
                                  borderRadius: BorderRadius.circular(14)),
                              child: ElevatedButton(
                                onPressed: () => showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (_) => AddProductModal(
                                        productName: p.name,
                                        productBrand: p.brand)),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14)),
                                child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.add,
                                          color: Colors.white, size: 18),
                                      SizedBox(width: 6),
                                      Text('Ürünlerime Ekle',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13)),
                                    ]),
                              ),
                            )),
                      ])),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _infoCard(String title, List<String> items) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark)),
          const SizedBox(height: 8),
          ...items.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(children: [
                const Icon(Icons.check, size: 14, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(t,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textGrey))),
              ]))),
        ]),
      );
}
