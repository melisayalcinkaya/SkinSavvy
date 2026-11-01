import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/review.dart';
import '../../../data/models/shelf_item.dart';
import '../../../state/review_controller.dart';
import '../../widgets/app_snack.dart';
import '../../widgets/product_image.dart';

/// Dolaptaki bir ürün için yorum yazar ya da mevcut yorumu düzenler.
/// [product] verilirse o ürüne ait önceki yorum varsa otomatik düzenleme
/// moduna geçer; [review] verilirse doğrudan o yorum düzenlenir.
class WriteReviewScreen extends StatefulWidget {
  const WriteReviewScreen({super.key, this.product, this.review})
    : assert(product != null || review != null);

  final ShelfItem? product;
  final Review? review;

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  late int _rating;
  late final TextEditingController _commentCtrl;
  Review? _existing;

  static const int _maxCommentLength = ReviewController.maxLength;
  static const int _minCommentLength = ReviewController.minLength;

  bool get _isEditing => _existing != null;
  String get _name => widget.product?.name ?? widget.review!.productName;
  String get _brand => widget.product?.brand ?? widget.review!.brand;
  String get _imageUrl => widget.product?.imageUrl ?? widget.review!.imageUrl;

  @override
  void initState() {
    super.initState();
    final reviews = context.read<ReviewController>();
    final p = widget.product;
    _existing =
        widget.review ??
        (p == null
            ? null
            : reviews.forShelfItem(p.id) ?? reviews.forProduct(p.productId));
    _rating = _existing?.rating ?? 0;
    _commentCtrl = TextEditingController(text: _existing?.comment ?? '');
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_rating == 0) {
      _showError('Lütfen bir puan verin.');
      return;
    }
    if (_commentCtrl.text.trim().length < _minCommentLength) {
      _showError('Yorumunuz en az $_minCommentLength karakter olmalıdır.');
      return;
    }
    final reviews = context.read<ReviewController>();
    try {
      final existing = _existing;
      if (existing != null) {
        reviews.edit(existing.id, rating: _rating, comment: _commentCtrl.text);
      } else {
        reviews.save(
          widget.product!,
          rating: _rating,
          comment: _commentCtrl.text,
        );
      }
    } on ArgumentError catch (e) {
      _showError('${e.message}');
      return;
    }
    showAppSnack(context, 'Yorumunuz kaydedildi');
    Navigator.pop(context, true);
  }

  void _showError(String msg) => showAppSnack(context, msg, error: true);

  String get _ratingLabel {
    switch (_rating) {
      case 1:
        return '😞 Hiç beğenmedim';
      case 2:
        return '😕 Beğenmedim';
      case 3:
        return '😐 İdare eder';
      case 4:
        return '😊 Güzel';
      case 5:
        return '😍 Harika!';
      default:
        return 'Puan vermek için yıldıza dokunun';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _productCard(),
                  const SizedBox(height: 12),
                  _ratingCard(),
                  const SizedBox(height: 12),
                  _commentCard(),
                  const SizedBox(height: 12),
                  _infoCard(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(4, 10, 16, 10),
    child: Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
        ),
        Expanded(
          child: Text(
            _isEditing ? 'Yorumu Düzenle' : 'Yorum Yaz',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
          ),
        ),
        const SizedBox(width: 48),
      ],
    ),
  );

  Widget _productCard() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
      ],
    ),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ProductImage(
            _imageUrl,
            width: 56,
            height: 56,
            radius: 0,
            category: widget.product?.category ?? '',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _brand,
                style: const TextStyle(fontSize: 11, color: AppColors.primary),
              ),
              const SizedBox(height: 4),
              // sadece kullandıklarım veya bitirdiklerim badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.product?.status == ShelfStatus.using
                      ? '✓ Kullanıyorum'
                      : '✓ Kullandım',
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.primary,
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

  Widget _ratingCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
      ],
    ),
    child: Column(
      children: [
        const Row(
          children: [
            Icon(Icons.star_outline, color: AppColors.primary, size: 17),
            SizedBox(width: 6),
            Text(
              'Puanınız *',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Divider(height: 1, color: AppColors.softGreen),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            return GestureDetector(
              onTap: () => setState(() => _rating = i + 1),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 150),
                  scale: i < _rating ? 1.15 : 1.0,
                  child: Icon(
                    i < _rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: i < _rating ? AppColors.peach : AppColors.softGreen,
                    size: 40,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            _ratingLabel,
            key: ValueKey(_rating),
            style: TextStyle(
              fontSize: 13,
              fontWeight: _rating > 0 ? FontWeight.w500 : FontWeight.w400,
              color: _rating > 0 ? AppColors.textDark : AppColors.textGrey,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _commentCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.chat_bubble_outline, color: AppColors.primary, size: 17),
            SizedBox(width: 6),
            Text(
              'Yorumunuz *',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Divider(height: 1, color: AppColors.softGreen),
        const SizedBox(height: 12),
        TextField(
          controller: _commentCtrl,
          maxLength: _maxCommentLength,
          maxLines: 5,
          inputFormatters: [
            LengthLimitingTextInputFormatter(_maxCommentLength),
          ],
          decoration: InputDecoration(
            hintText:
                'Ürün hakkındaki deneyiminizi paylaşın...\n\nörn: Cildimi nemlendiriyor, kokusunu sevdim.',
            hintStyle: const TextStyle(
              color: AppColors.textLight,
              fontSize: 12,
              height: 1.6,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.softGreen,
                width: 2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.softGreen,
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: true,
            fillColor: AppColors.cream,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'En az $_minCommentLength karakter',
              style: const TextStyle(fontSize: 10, color: AppColors.textGrey),
            ),
            Text(
              '${_commentCtrl.text.length}/$_maxCommentLength',
              style: TextStyle(
                fontSize: 10,
                color: _commentCtrl.text.length >= _maxCommentLength
                    ? AppColors.accent
                    : AppColors.textGrey,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _infoCard() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.lightGreen,
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, color: AppColors.primary, size: 16),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Yorumunuz diğer kullanıcılar tarafından görülebilir. Kişisel bilgi paylaşmaktan kaçının.',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.primary,
              height: 1.5,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildBottomBar() => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
    child: Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.softGreen, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'İptal',
              style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient:
                  (_rating > 0 && _commentCtrl.text.length >= _minCommentLength)
                  ? AppGradients.primary
                  : const LinearGradient(
                      colors: [AppColors.softGreen, AppColors.softGreen],
                    ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: ElevatedButton(
              onPressed:
                  (_rating == 0 ||
                      _commentCtrl.text.trim().length < _minCommentLength)
                  ? null
                  : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isEditing ? Icons.save_outlined : Icons.send_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isEditing ? 'Güncelle' : 'Yorumu Gönder',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
