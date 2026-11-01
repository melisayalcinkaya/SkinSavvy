// ============================================================
// lib/presentation/screens/collections/finish_product_screen.dart
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/text_utils.dart';
import '../../../data/models/shelf_item.dart';
import '../../../state/shelf_controller.dart';
import '../../widgets/app_snack.dart';
import '../../widgets/product_image.dart';

class FinishProductScreen extends StatefulWidget {
  final ShelfItem product;
  const FinishProductScreen({super.key, required this.product});

  @override
  State<FinishProductScreen> createState() => _FinishProductScreenState();
}

class _FinishProductScreenState extends State<FinishProductScreen> {
  bool? _wouldRebuy;
  final _noteCtrl = TextEditingController();
  late int _rating = widget.product.rating;

  static const int _maxNoteLength = 300;

  void _finish() {
    if (_wouldRebuy == null) {
      _showError('Lütfen tekrar alır mısınız seçeneğini belirtin.');
      return;
    }
    // Ürün "bitirdiklerim"e taşınır; rutin denetleyicisi dolabı dinlediği
    // için ürünün rutin adımları da kendiliğinden kalkar.
    context.read<ShelfController>().finish(
      widget.product.id,
      wouldRebuy: _wouldRebuy!,
      rating: _rating,
      note: sanitizeInput(_noteCtrl.text),
    );
    _showSuccessDialog();
  }

  void _showError(String msg) => showAppSnack(context, msg, error: true);

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ürün Bitirildi!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '"${widget.product.name}" bitirdiklerim listesine taşındı.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textGrey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppGradients.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // dialog kapat
                      Navigator.pop(
                        context,
                        'finished',
                      ); // ekranı kapat + sinyal
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: const Text(
                      'Tamam',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
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
                  _rebuyCard(),
                  const SizedBox(height: 12),
                  _ratingCard(),
                  const SizedBox(height: 12),
                  _noteCard(),
                  const SizedBox(height: 12),
                  _warningCard(),
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
        const Expanded(
          child: Text(
            'Ürünü Bitir',
            textAlign: TextAlign.center,
            style: TextStyle(
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
        ProductImage(
          widget.product.imageUrl,
          width: 60,
          height: 60,
          radius: 12,
          category: widget.product.category,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.product.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.product.brand,
                style: const TextStyle(fontSize: 11, color: AppColors.primary),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 11,
                    color: AppColors.textLight,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Açıldı: ${formatDateShort(widget.product.openedOn)}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Bitiş rozeti
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFEEE8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            children: [
              Text('🏁', style: TextStyle(fontSize: 18)),
              Text(
                'Bitti',
                style: TextStyle(
                  fontSize: 9,
                  color: AppColors.accent,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _rebuyCard() => Container(
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
            Icon(Icons.help_outline, color: AppColors.primary, size: 17),
            SizedBox(width: 6),
            Text(
              'Tekrar alır mısınız?',
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
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _rebuyBtn(
                emoji: '✅',
                label: 'Tekrar Alırım',
                value: true,
                activeColor: AppColors.primary,
                activeBg: AppColors.lightGreen,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _rebuyBtn(
                emoji: '❌',
                label: 'Tekrar Almam',
                value: false,
                activeColor: AppColors.accent,
                activeBg: const Color(0xFFFFEEE8),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _rebuyBtn({
    required String emoji,
    required String label,
    required bool value,
    required Color activeColor,
    required Color activeBg,
  }) {
    final selected = _wouldRebuy == value;
    return GestureDetector(
      onTap: () => setState(() => _wouldRebuy = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? activeBg : AppColors.cream,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? activeColor : AppColors.softGreen,
            width: selected ? 2 : 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: selected ? activeColor : AppColors.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.star_outline, color: AppColors.primary, size: 17),
            SizedBox(width: 6),
            Text(
              'Son puanınız',
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
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            return GestureDetector(
              onTap: () => setState(() => _rating = i + 1),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  i < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: i < _rating ? AppColors.peach : AppColors.softGreen,
                  size: 38,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            _rating == 0
                ? 'Puan vermek ister misiniz?'
                : _rating == 1
                ? '😞 Hiç beğenmedim'
                : _rating == 2
                ? '😕 Beğenmedim'
                : _rating == 3
                ? '😐 İdare eder'
                : _rating == 4
                ? '😊 Güzeldi'
                : '😍 Harikaydı!',
            style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
          ),
        ),
      ],
    ),
  );

  Widget _noteCard() => Container(
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
            Icon(Icons.notes_outlined, color: AppColors.primary, size: 17),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                'Notunuz (Opsiyonel)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Divider(height: 1, color: AppColors.softGreen),
        const SizedBox(height: 12),
        TextFormField(
          controller: _noteCtrl,
          maxLength: _maxNoteLength,
          maxLines: 3,
          inputFormatters: [LengthLimitingTextInputFormatter(_maxNoteLength)],
          decoration: InputDecoration(
            hintText:
                'Bu ürün hakkında düşünceleriniz...\nörn: Cildimi kuruttu, tekrar almayacağım.',
            hintStyle: const TextStyle(
              color: AppColors.textLight,
              fontSize: 12,
              height: 1.5,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.softGreen,
                width: 2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.softGreen,
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: true,
            fillColor: AppColors.cream,
          ),
        ),
      ],
    ),
  );

  Widget _warningCard() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF3E0),
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, color: AppColors.accent, size: 16),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Bu işlem geri alınamaz. Ürün "Bitirdiklerim" listesine taşınacak ve aktif listenizden kaldırılacaktır.',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.accent,
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
              gradient: _wouldRebuy != null
                  ? AppGradients.primary
                  : const LinearGradient(
                      colors: [AppColors.softGreen, AppColors.softGreen],
                    ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: ElevatedButton(
              onPressed: _wouldRebuy == null ? null : _finish,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.white,
                    size: 18,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Ürünü Bitir',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
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
