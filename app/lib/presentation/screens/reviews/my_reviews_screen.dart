import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import 'write_review_screen.dart';

class ReviewModel {
  final String id;
  final String productName;
  final String productBrand;
  final String productImageUrl;
  final int rating;
  final String comment;
  final String date;
  final bool canEdit; // sadece kendi yorumlarını düzenleyebilir

  const ReviewModel({
    required this.id,
    required this.productName,
    required this.productBrand,
    required this.productImageUrl,
    required this.rating,
    required this.comment,
    required this.date,
    this.canEdit = true,
  });
}

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});
  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  bool _isLoading = false;

  // Demo verisi — gerçekte Firebase'den çekilir
  final List<ReviewModel> _reviews = [
    ReviewModel(
      id: 'r1',
      productName: 'Hydrating Cleanser',
      productBrand: 'CeraVe',
      productImageUrl: 'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=200',
      rating: 5,
      comment: 'Cildi kurutmuyor, çok seviyorum! Sabah ve akşam kullanıyorum, fark çok belirgin.',
      date: '15 Oca 2024',
    ),
    ReviewModel(
      id: 'r2',
      productName: 'Vitamin C Serum',
      productBrand: 'The Ordinary',
      productImageUrl: 'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?w=200',
      rating: 4,
      comment: 'Lekeler için gerçekten işe yarıyor. Kokusu biraz sert ama alışıyorsunuz.',
      date: '20 Şub 2024',
    ),
    ReviewModel(
      id: 'r3',
      productName: 'Hyaluronic Acid',
      productBrand: 'The Ordinary',
      productImageUrl: 'https://images.unsplash.com/photo-1590439471364-192aa70c9999?w=200',
      rating: 5,
      comment: 'Nemlendirme etkisi inanılmaz. Kesinlikle tekrar alacağım.',
      date: '5 Mar 2024',
    ),
  ];

  Future<void> _deleteReview(String reviewId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Yorumu Sil', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark)),
        content: const Text('Bu yorumu silmek istediğinizden emin misiniz?',
          style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal', style: TextStyle(color: AppColors.textGrey))),
          TextButton(onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600))),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      // Gerçek uygulamada:
      // await FirebaseFirestore.instance.collection('reviews').doc(reviewId).delete();
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(() => _reviews.removeWhere((r) => r.id == reviewId));
      _showSuccess('Yorum silindi.');
    } catch (e) {
      _showError('Silme sırasında hata oluştu.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: AppColors.accent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
    ));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle, color: Colors.white, size: 16), const SizedBox(width: 8), Text(msg),
      ]),
      backgroundColor: AppColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          if (_isLoading) const LinearProgressIndicator(color: AppColors.primary, backgroundColor: AppColors.softGreen),
          Expanded(
            child: _reviews.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _reviews.length,
                  itemBuilder: (_, i) => _reviewCard(_reviews[i]),
                ),
          ),
        ]),
      ),
    );
  }

  Widget _buildHeader() => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(4, 10, 16, 10),
    child: Row(children: [
      IconButton(onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back, color: AppColors.textDark)),
      Expanded(child: Text(
        'Yorumlarım (${_reviews.length})',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textDark),
      )),
      const SizedBox(width: 48),
    ]),
  );

  Widget _reviewCard(ReviewModel r) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Ürün bilgisi
      Row(children: [
        ClipRRect(borderRadius: BorderRadius.circular(10),
          child: Image.network(r.productImageUrl, width: 44, height: 44, fit: BoxFit.cover)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(r.productName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textDark)),
          Text(r.productBrand, style: const TextStyle(fontSize: 10, color: AppColors.primary)),
        ])),
        // Üç nokta menüsü
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppColors.textLight, size: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          onSelected: (value) async {
            if (value == 'edit') {
              // Düzenleme için ürün bilgisi lazım — demo MyProduct oluşturuyoruz
              final demoProduct = MyProduct(
                name: r.productName, brand: r.productBrand, imageUrl: r.productImageUrl,
                category: '', status: 'Kullanımda', remaining: 100,
                openDate: '', expiryDate: '', amount: '', usage: '', rating: r.rating, note: '',
              );
              final updated = await Navigator.push(context, MaterialPageRoute(
                builder: (_) => WriteReviewScreen(
                  product: demoProduct, isEditing: true,
                  existingReviewId: r.id, existingComment: r.comment, existingRating: r.rating,
                ),
              ));
              if (updated == true && mounted) setState(() {});
            } else if (value == 'delete') {
              await _deleteReview(r.id);
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Row(children: [
              Icon(Icons.edit_outlined, color: AppColors.primary, size: 16),
              SizedBox(width: 8), Text('Düzenle', style: TextStyle(fontSize: 13)),
            ])),
            const PopupMenuItem(value: 'delete', child: Row(children: [
              Icon(Icons.delete_outline, color: AppColors.accent, size: 16),
              SizedBox(width: 8), Text('Sil', style: TextStyle(fontSize: 13, color: AppColors.accent)),
            ])),
          ],
        ),
      ]),
      const SizedBox(height: 10),
      const Divider(height: 1, color: AppColors.softGreen),
      const SizedBox(height: 10),
      // Yıldız puanı + tarih
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: List.generate(5, (i) => Icon(
          i < r.rating ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 16, color: i < r.rating ? AppColors.peach : AppColors.softGreen,
        ))),
        Text(r.date, style: const TextStyle(fontSize: 10, color: AppColors.textGrey)),
      ]),
      const SizedBox(height: 8),
      // Yorum metni
      Text(r.comment, style: const TextStyle(fontSize: 12, color: AppColors.textDark, height: 1.5)),
    ]),
  );

  Widget _buildEmptyState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 72, height: 72, decoration: BoxDecoration(color: AppColors.lightGreen, shape: BoxShape.circle),
          child: const Icon(Icons.chat_bubble_outline, color: AppColors.primary, size: 32)),
        const SizedBox(height: 16),
        const Text('Henüz yorum yapmadınız', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textDark)),
        const SizedBox(height: 6),
        const Text('Kullandığınız veya bitirdiğiniz ürünler için yorum yapabilirsiniz.',
          textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.textGrey, height: 1.5)),
      ]),
    ),
  );
}