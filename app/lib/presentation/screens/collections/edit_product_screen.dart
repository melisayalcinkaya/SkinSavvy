// ============================================================
// lib/presentation/screens/collections/edit_product_screen.dart
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
import '../../widgets/date_input.dart';
import '../../widgets/product_image.dart';

class EditProductScreen extends StatefulWidget {
  final ShelfItem product;
  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _openDateCtrl;
  late final TextEditingController _expiryDateCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _noteCtrl;
  late String _usageTime;
  late int _rating;
  late int _remaining;
  late int? _paoMonths;

  // Güvenlik: max karakter limitleri
  static const int _maxNoteLength = 300;
  static const int _maxAmountLength = 20;

  @override
  void initState() {
    super.initState();
    // Mevcut değerleri doldur
    _openDateCtrl = TextEditingController(
      text: formatDateInput(widget.product.openedOn),
    );
    _expiryDateCtrl = TextEditingController(
      text: formatDateInput(widget.product.expiresOn),
    );
    _amountCtrl = TextEditingController(text: widget.product.amount);
    _noteCtrl = TextEditingController(text: widget.product.note);
    _usageTime = widget.product.usage;
    _rating = widget.product.rating;
    _remaining = widget.product.remaining;
    _paoMonths = widget.product.paoMonths;
  }

  @override
  void dispose() {
    _openDateCtrl.dispose();
    _expiryDateCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final opened = parseDateInput(_openDateCtrl.text);
    final expires = parseDateInput(_expiryDateCtrl.text);
    context.read<ShelfController>().update(
      widget.product.copyWith(
        openedOn: opened,
        clearOpenedOn: opened == null,
        expiresOn: expires,
        clearExpiresOn: expires == null,
        paoMonths: _paoMonths,
        clearPaoMonths: _paoMonths == null,
        amount: sanitizeInput(_amountCtrl.text),
        usage: _usageTime,
        remaining: _remaining,
        rating: _rating,
        note: sanitizeInput(_noteCtrl.text),
      ),
    );
    showAppSnack(context, 'Ürün bilgileri güncellendi');
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _productInfoCard(),
                    const SizedBox(height: 12),
                    _datesCard(),
                    const SizedBox(height: 12),
                    _usageCard(),
                    const SizedBox(height: 12),
                    _remainingCard(),
                    const SizedBox(height: 12),
                    _ratingCard(),
                    const SizedBox(height: 12),
                    _noteCard(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              _buildBottomBar(),
            ],
          ),
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
            'Ürünü Düzenle',
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

  // Ürün bilgisi (sadece okuma — değiştirilemez)
  Widget _productInfoCard() => Container(
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
          width: 56,
          height: 56,
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
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.product.category,
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
        // Salt okunur etiketi
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Ürün bilgileri\ndeğiştirilemez',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 8, color: AppColors.textGrey),
          ),
        ),
      ],
    ),
  );

  Widget _datesCard() => _card(
    title: 'Tarihler',
    icon: Icons.calendar_today_outlined,
    child: Column(
      children: [
        _fieldLabel('Açılış Tarihi'),
        TextFormField(
          controller: _openDateCtrl,
          keyboardType: TextInputType.datetime,
          inputFormatters: [DateInputFormatter()],
          decoration: _inputDec('GG/AA/YYYY', Icons.calendar_today_outlined),
          validator: (v) {
            if (v == null || v.isEmpty) return null; // opsiyonel
            if (parseDateInput(v) == null) {
              return 'Geçerli bir tarih giriniz (GG/AA/YYYY)';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        _fieldLabel('Son Kullanma Tarihi (SKT)'),
        TextFormField(
          controller: _expiryDateCtrl,
          keyboardType: TextInputType.datetime,
          inputFormatters: [DateInputFormatter()],
          decoration: _inputDec('GG/AA/YYYY', Icons.event_busy_outlined),
          validator: (v) {
            if (v == null || v.isEmpty) return null;
            final exp = parseDateInput(v);
            if (exp == null) return 'Geçerli bir tarih giriniz (GG/AA/YYYY)';
            // SKT açılış tarihinden önce olamaz
            final open = parseDateInput(_openDateCtrl.text);
            if (open != null && exp.isBefore(open)) {
              return 'SKT, açılış tarihinden önce olamaz.';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        _fieldLabel('Açıldıktan Sonra Kullanım Süresi'),
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final m in const [3, 6, 9, 12, 18, 24])
                ChoiceChip(
                  label: Text('$m ay'),
                  selected: _paoMonths == m,
                  onSelected: (on) =>
                      setState(() => _paoMonths = on ? m : null),
                  selectedColor: AppColors.lightGreen,
                  labelStyle: TextStyle(
                    fontSize: 11,
                    color: _paoMonths == m
                        ? AppColors.primary
                        : AppColors.textGrey,
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _usageCard() => _card(
    title: 'Kullanım Zamanı',
    icon: Icons.access_time_outlined,
    child: Column(
      children: [
        Row(
          children: [
            Expanded(child: _usageBtn('☀️ Sabah', 'Sabah')),
            const SizedBox(width: 8),
            Expanded(child: _usageBtn('🌙 Akşam', 'Akşam')),
            const SizedBox(width: 8),
            Expanded(child: _usageBtn('🌗 Her İkisi', 'Sabah & Akşam')),
          ],
        ),
        const SizedBox(height: 12),
        _fieldLabel('Miktar'),
        TextFormField(
          controller: _amountCtrl,
          maxLength: _maxAmountLength,
          inputFormatters: [LengthLimitingTextInputFormatter(_maxAmountLength)],
          decoration: _inputDec('örn: 30ml, 50g', Icons.inventory_2_outlined),
          validator: (v) {
            if (v != null && v.isNotEmpty && v.trim().length < 2) {
              return 'Geçerli bir miktar giriniz.';
            }
            return null;
          },
        ),
      ],
    ),
  );

  Widget _remainingCard() => _card(
    title: 'Kalan Miktar',
    icon: Icons.water_drop_outlined,
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Kalan: %$_remaining',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _remaining < 20
                    ? const Color(0xFFFFEEE8)
                    : AppColors.lightGreen,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _remaining < 20
                    ? 'Bitmek Üzere'
                    : _remaining > 80
                    ? 'Yeni'
                    : 'Kullanımda',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: _remaining < 20 ? AppColors.accent : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.softGreen,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withValues(alpha: 0.1),
            trackHeight: 6,
          ),
          child: Slider(
            value: _remaining.toDouble(),
            min: 0,
            max: 100,
            divisions: 20,
            onChanged: (v) => setState(() => _remaining = v.round()),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              '0%',
              style: TextStyle(fontSize: 10, color: AppColors.textGrey),
            ),
            Text(
              '50%',
              style: TextStyle(fontSize: 10, color: AppColors.textGrey),
            ),
            Text(
              '100%',
              style: TextStyle(fontSize: 10, color: AppColors.textGrey),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _ratingCard() => _card(
    title: 'Puanım',
    icon: Icons.star_outline,
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            return GestureDetector(
              onTap: () => setState(() => _rating = i + 1),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  i < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: i < _rating ? AppColors.peach : AppColors.softGreen,
                  size: 36,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          _rating == 0
              ? 'Henüz puanlanmadı'
              : _rating == 1
              ? 'Hiç beğenmedim'
              : _rating == 2
              ? 'Beğenmedim'
              : _rating == 3
              ? 'İdare eder'
              : _rating == 4
              ? 'Güzel'
              : 'Harika!',
          style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
        ),
      ],
    ),
  );

  Widget _noteCard() => _card(
    title: 'Notum',
    icon: Icons.notes_outlined,
    child: TextFormField(
      controller: _noteCtrl,
      maxLength: _maxNoteLength,
      maxLines: 3,
      inputFormatters: [LengthLimitingTextInputFormatter(_maxNoteLength)],
      decoration: InputDecoration(
        hintText: 'Bu ürün hakkında notlarınız...',
        hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.softGreen, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.softGreen, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: AppColors.cream,
      ),
      validator: (v) {
        if (v != null && v.isNotEmpty) {
          final sanitized = sanitizeInput(v);
          if (sanitized.isEmpty) return 'Geçersiz karakter içeriyor.';
        }
        return null;
      },
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
              gradient: AppGradients.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check, color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Kaydet',
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

  // Yardımcı widgetlar
  Widget _card({
    required String title,
    required IconData icon,
    required Widget child,
  }) => Container(
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
        Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 17),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(height: 1, color: AppColors.softGreen),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );

  Widget _fieldLabel(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      t,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textGrey,
      ),
    ),
  );

  InputDecoration _inputDec(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 13),
    prefixIcon: Icon(icon, color: AppColors.secondary, size: 20),
    counterText: '',
  );

  Widget _usageBtn(String label, String value) {
    final active = _usageTime == value;
    return GestureDetector(
      onTap: () => setState(() => _usageTime = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: active ? AppGradients.primary : null,
          color: active ? null : AppColors.cream,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? Colors.transparent : AppColors.softGreen,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: active ? Colors.white : AppColors.textGrey,
            ),
          ),
        ),
      ),
    );
  }
}
