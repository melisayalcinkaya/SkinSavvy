import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';

class WriteReviewScreen extends StatefulWidget {
  final MyProduct product;
  final bool isEditing;          // düzenleme modu
  final String? existingReviewId;
  final String? existingComment;
  final int existingRating;

  const WriteReviewScreen({
    super.key,
    required this.product,
    this.isEditing = false,
    this.existingReviewId,
    this.existingComment,
    this.existingRating = 0,
  });

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  late int _rating;
  late final TextEditingController _commentCtrl;
  bool _isLoading = false;

  static const int _maxCommentLength = 500;
  static const int _minCommentLength = 10;

  @override
  void initState() {
    super.initState();
    _rating = widget.existingRating;
    _commentCtrl = TextEditingController(text: widget.existingComment ?? '');
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  String _sanitize(String input) {
    return input
        .replaceAll(RegExp(r'<[^>]*>'), '') // HTML tag temizle
        .replaceAll(RegExp('[<>"\']'), '') // tehlikeli karakterler
        .trim();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      _showError('Lütfen bir puan verin.');
      return;
    }
    final comment = _sanitize(_commentCtrl.text);
    if (comment.length < _minCommentLength) {
      _showError('Yorumunuz en az $_minCommentLength karakter olmalıdır.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Gerçek uygulamada Firebase:
      // if (widget.isEditing && widget.existingReviewId != null) {
      //   await FirebaseFirestore.instance
      //     .collection('reviews')
      //     .doc(widget.existingReviewId)
      //     .update({
      //       'rating': _rating,
      //       'comment': comment,
      //       'updatedAt': FieldValue.serverTimestamp(),
      //     });
      // } else {
      //   await FirebaseFirestore.instance.collection('reviews').add({
      //     'userId': currentUser.uid,
      //     'productId': widget.product.id,
      //     'rating': _rating,
      //     'comment': comment,
      //     'createdAt': FieldValue.serverTimestamp(),
      //   });
      // }

      await Future.delayed(const Duration(milliseconds: 600));

      if (!mounted) return;
      _showSuccessAndPop();
    } catch (e) {
      _showError('Yorum gönderilirken hata oluştu.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.accent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
    ));
  }

  void _showSuccessAndPop() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: const [
        Icon(Icons.check_circle, color: Colors.white, size: 16),
        SizedBox(width: 8),
        Text('Yorumunuz kaydedildi'),
      ]),
      backgroundColor: AppColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
    ));
    Navigator.pop(context, true);
  }

  String get _ratingLabel {
    switch (_rating) {
      case 1: return '😞 Hiç beğenmedim';
      case 2: return '😕 Beğenmedim';
      case 3: return '😐 İdare eder';
      case 4: return '😊 Güzel';
      case 5: return '😍 Harika!';
      default: return 'Puan vermek için yıldıza dokunun';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(children: [
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
        ]),
      ),
    );
  }

  Widget _buildHeader() => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(4, 10, 16, 10),
    child: Row(children: [
      IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
      ),
      Expanded(child: Text(
        widget.isEditing ? 'Yorumu Düzenle' : 'Yorum Yaz',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textDark),
      )),
      const SizedBox(width: 48),
    ]),
  );

  Widget _productCard() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
    child: Row(children: [
      ClipRRect(borderRadius: BorderRadius.circular(12),
        child: Image.network(widget.product.imageUrl, width: 56, height: 56, fit: BoxFit.cover)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.product.name,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textDark)),
        const SizedBox(height: 2),
        Text(widget.product.brand, style: const TextStyle(fontSize: 11, color: AppColors.primary)),
        const SizedBox(height: 4),
        // sadece kullandıklarım veya bitirdiklerim badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: widget.product.status == 'Kullanımda' ? AppColors.lightGreen : const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            widget.product.status == 'Kullanımda' ? '✓ Kullanıyorum' : '✓ Kullandım',
            style: const TextStyle(fontSize: 9, color: AppColors.primary, fontWeight: FontWeight.w500),
          ),
        ),
      ])),
    ]),
  );

  Widget _ratingCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
    child: Column(children: [
      const Row(children: [
        Icon(Icons.star_outline, color: AppColors.primary, size: 17),
        SizedBox(width: 6),
        Text('Puanınız *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark)),
      ]),
      const SizedBox(height: 6),
      const Divider(height: 1, color: AppColors.softGreen),
      const SizedBox(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) {
        return GestureDetector(
          onTap: () => setState(() => _rating = i + 1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 150),
              scale: i < _rating ? 1.15 : 1.0,
              child: Icon(
                i < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                color: i < _rating ? AppColors.peach : AppColors.softGreen,
                size: 40,
              ),
            ),
          ),
        );
      })),
      const SizedBox(height: 10),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Text(_ratingLabel,
          key: ValueKey(_rating),
          style: TextStyle(
            fontSize: 13,
            fontWeight: _rating > 0 ? FontWeight.w500 : FontWeight.w400,
            color: _rating > 0 ? AppColors.textDark : AppColors.textGrey,
          )),
      ),
    ]),
  );

  Widget _commentCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [
        Icon(Icons.chat_bubble_outline, color: AppColors.primary, size: 17),
        SizedBox(width: 6),
        Text('Yorumunuz *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark)),
      ]),
      const SizedBox(height: 6),
      const Divider(height: 1, color: AppColors.softGreen),
      const SizedBox(height: 12),
      TextField(
        controller: _commentCtrl,
        maxLength: _maxCommentLength,
        maxLines: 5,
        inputFormatters: [LengthLimitingTextInputFormatter(_maxCommentLength)],
        decoration: InputDecoration(
          hintText: 'Ürün hakkındaki deneyiminizi paylaşın...\n\nörn: Cildimi nemlendiriyor, kokusunu sevdim.',
          hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 12, height: 1.6),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.softGreen, width: 2)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.softGreen, width: 2)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 2)),
          filled: true, fillColor: AppColors.cream,
        ),
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 6),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('En az $_minCommentLength karakter',
          style: const TextStyle(fontSize: 10, color: AppColors.textGrey)),
        Text('${_commentCtrl.text.length}/$_maxCommentLength',
          style: TextStyle(fontSize: 10,
            color: _commentCtrl.text.length >= _maxCommentLength ? AppColors.accent : AppColors.textGrey)),
      ]),
    ]),
  );

  Widget _infoCard() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.lightGreen, borderRadius: BorderRadius.circular(16)),
    child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(Icons.info_outline, color: AppColors.primary, size: 16),
      SizedBox(width: 8),
      Expanded(child: Text(
        'Yorumunuz diğer kullanıcılar tarafından görülebilir. Kişisel bilgi paylaşmaktan kaçının.',
        style: TextStyle(fontSize: 11, color: AppColors.primary, height: 1.5),
      )),
    ]),
  );

  Widget _buildBottomBar() => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
    child: Row(children: [
      Expanded(child: OutlinedButton(
        onPressed: () => Navigator.pop(context),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.softGreen, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: const Text('İptal', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w500)),
      )),
      const SizedBox(width: 12),
      Expanded(flex: 2, child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: (_rating > 0 && _commentCtrl.text.length >= _minCommentLength)
            ? AppGradients.primary
            : const LinearGradient(colors: [AppColors.softGreen, AppColors.softGreen]),
          borderRadius: BorderRadius.circular(14),
        ),
        child: ElevatedButton(
          onPressed: (_isLoading || _rating == 0 || _commentCtrl.text.length < _minCommentLength)
            ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: _isLoading
            ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(widget.isEditing ? Icons.save_outlined : Icons.send_outlined,
                  color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(widget.isEditing ? 'Güncelle' : 'Yorumu Gönder',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
              ]),
        ),
      )),
    ]),
  );
}