// ============================================================
// lib/presentation/screens/collections/edit_product_screen.dart
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';

class EditProductScreen extends StatefulWidget {
  final MyProduct product;
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
  bool _isLoading = false;

  // Güvenlik: max karakter limitleri
  static const int _maxNoteLength = 300;
  static const int _maxAmountLength = 20;

  @override
  void initState() {
    super.initState();
    // Mevcut değerleri doldur
    _openDateCtrl = TextEditingController(text: widget.product.openDate);
    _expiryDateCtrl = TextEditingController(text: widget.product.expiryDate);
    _amountCtrl = TextEditingController(text: widget.product.amount);
    _noteCtrl = TextEditingController(text: widget.product.note);
    _usageTime = widget.product.usage;
    _rating = widget.product.rating;
    _remaining = widget.product.remaining;
  }

  @override
  void dispose() {
    _openDateCtrl.dispose();
    _expiryDateCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  // Güvenlik: input sanitizer
  String _sanitize(String input) {
    return input
        .replaceAll(RegExp(r'<[^>]*>'), '') // HTML tag temizle
        .replaceAll(RegExp('[<>"\']'), '') // tehlikeli karakterler
        .trim();
  }

  // Tarih format doğrulama (GG/AA/YYYY)
  bool _isValidDate(String date) {
    final regex = RegExp(r'^\d{2}/\d{2}/\d{4}$');
    if (!regex.hasMatch(date)) return false;
    final parts = date.split('/');
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return false;
    if (day < 1 || day > 31) return false;
    if (month < 1 || month > 12) return false;
    if (year < 2000 || year > 2100) return false;
    return true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Gerçek uygulamada Firebase güncelleme:
      // await FirebaseFirestore.instance
      //   .collection('user_products')
      //   .doc(widget.product.id)
      //   .update({
      //     'openDate': _sanitize(_openDateCtrl.text),
      //     'expiryDate': _sanitize(_expiryDateCtrl.text),
      //     'amount': _sanitize(_amountCtrl.text),
      //     'usage': _usageTime,
      //     'remaining': _remaining,
      //     'rating': _rating,
      //     'note': _sanitize(_noteCtrl.text),
      //     'updatedAt': FieldValue.serverTimestamp(),
      //   });

      await Future.delayed(const Duration(milliseconds: 600));

      if (!mounted) return;
      _showSuccess('Ürün bilgileri güncellendi');
      Navigator.pop(context, true); // true: güncellendi sinyali
    } catch (e) {
      _showError('Güncelleme sırasında bir hata oluştu.');
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

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle, color: Colors.white, size: 16),
        const SizedBox(width: 8),
        Text(msg),
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
        child: Form(
          key: _formKey,
          child: Column(children: [
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
          ]),
        ),
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
          const Expanded(
              child: Text('Ürünü Düzenle',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark))),
          const SizedBox(width: 48),
        ]),
      );

  // Ürün bilgisi (sadece okuma — değiştirilemez)
  Widget _productInfoCard() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
            ]),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(widget.product.imageUrl,
                width: 56, height: 56, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(widget.product.name,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDark)),
                const SizedBox(height: 2),
                Text(widget.product.brand,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.primary)),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: AppColors.lightGreen,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(widget.product.category,
                      style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500)),
                ),
              ])),
          // Salt okunur etiketi
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: AppColors.cream, borderRadius: BorderRadius.circular(8)),
            child: const Text('Ürün bilgileri\ndeğiştirilemez',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 8, color: AppColors.textGrey)),
          ),
        ]),
      );

  Widget _datesCard() => _card(
        title: 'Tarihler',
        icon: Icons.calendar_today_outlined,
        child: Column(children: [
          _fieldLabel('Açılış Tarihi'),
          TextFormField(
            controller: _openDateCtrl,
            keyboardType: TextInputType.datetime,
            inputFormatters: [
              LengthLimitingTextInputFormatter(10),
              _DateInputFormatter(),
            ],
            decoration: _inputDec('GG/AA/YYYY', Icons.calendar_today_outlined),
            validator: (v) {
              if (v == null || v.isEmpty) return null; // opsiyonel
              if (!_isValidDate(v))
                return 'Geçerli bir tarih giriniz (GG/AA/YYYY)';
              return null;
            },
          ),
          const SizedBox(height: 12),
          _fieldLabel('Son Kullanma Tarihi (SKT)'),
          TextFormField(
            controller: _expiryDateCtrl,
            keyboardType: TextInputType.datetime,
            inputFormatters: [
              LengthLimitingTextInputFormatter(10),
              _DateInputFormatter(),
            ],
            decoration: _inputDec('GG/AA/YYYY', Icons.event_busy_outlined),
            validator: (v) {
              if (v == null || v.isEmpty) return null;
              if (!_isValidDate(v))
                return 'Geçerli bir tarih giriniz (GG/AA/YYYY)';
              // SKT açılış tarihinden önce olamaz
              if (_openDateCtrl.text.isNotEmpty &&
                  _isValidDate(_openDateCtrl.text)) {
                final open = _parseDate(_openDateCtrl.text);
                final exp = _parseDate(v);
                if (exp != null && open != null && exp.isBefore(open)) {
                  return 'SKT, açılış tarihinden önce olamaz.';
                }
              }
              return null;
            },
          ),
        ]),
      );

  Widget _usageCard() => _card(
        title: 'Kullanım Zamanı',
        icon: Icons.access_time_outlined,
        child: Column(children: [
          Row(children: [
            Expanded(child: _usageBtn('☀️ Sabah', 'Sabah')),
            const SizedBox(width: 8),
            Expanded(child: _usageBtn('🌙 Akşam', 'Akşam')),
            const SizedBox(width: 8),
            Expanded(child: _usageBtn('🌗 Her İkisi', 'Sabah & Akşam')),
          ]),
          const SizedBox(height: 12),
          _fieldLabel('Miktar'),
          TextFormField(
            controller: _amountCtrl,
            maxLength: _maxAmountLength,
            inputFormatters: [
              LengthLimitingTextInputFormatter(_maxAmountLength)
            ],
            decoration: _inputDec('örn: 30ml, 50g', Icons.inventory_2_outlined),
            validator: (v) {
              if (v != null && v.isNotEmpty && v.trim().length < 2) {
                return 'Geçerli bir miktar giriniz.';
              }
              return null;
            },
          ),
        ]),
      );

  Widget _remainingCard() => _card(
        title: 'Kalan Miktar',
        icon: Icons.water_drop_outlined,
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Kalan: %$_remaining',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark)),
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
                    color:
                        _remaining < 20 ? AppColors.accent : AppColors.primary),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.softGreen,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withOpacity(0.1),
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
                Text('0%',
                    style: TextStyle(fontSize: 10, color: AppColors.textGrey)),
                Text('50%',
                    style: TextStyle(fontSize: 10, color: AppColors.textGrey)),
                Text('100%',
                    style: TextStyle(fontSize: 10, color: AppColors.textGrey)),
              ]),
        ]),
      );

  Widget _ratingCard() => _card(
        title: 'Puanım',
        icon: Icons.star_outline,
        child: Column(children: [
          Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                return GestureDetector(
                  onTap: () => setState(() => _rating = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      i < _rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color:
                          i < _rating ? AppColors.peach : AppColors.softGreen,
                      size: 36,
                    ),
                  ),
                );
              })),
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
        ]),
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
            hintStyle:
                const TextStyle(color: AppColors.textLight, fontSize: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.softGreen, width: 2)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.softGreen, width: 2)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2)),
            filled: true,
            fillColor: AppColors.cream,
          ),
          validator: (v) {
            if (v != null && v.isNotEmpty) {
              final sanitized = _sanitize(v);
              if (sanitized.isEmpty) return 'Geçersiz karakter içeriyor.';
            }
            return null;
          },
        ),
      );

  Widget _buildBottomBar() => Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.softGreen, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('İptal',
                  style: TextStyle(
                      color: AppColors.textDark, fontWeight: FontWeight.w500)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: DecoratedBox(
              decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: BorderRadius.circular(14)),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                            Icon(Icons.check, color: Colors.white, size: 18),
                            SizedBox(width: 6),
                            Text('Kaydet',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14)),
                          ]),
              ),
            ),
          ),
        ]),
      );

  // Yardımcı widgetlar
  Widget _card(
          {required String title,
          required IconData icon,
          required Widget child}) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: AppColors.primary, size: 17),
            const SizedBox(width: 6),
            Text(title,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark)),
          ]),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.softGreen),
          const SizedBox(height: 12),
          child,
        ]),
      );

  Widget _fieldLabel(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textGrey)),
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
              width: 1.5),
        ),
        child: Center(
            child: Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: active ? Colors.white : AppColors.textGrey))),
      ),
    );
  }

  DateTime? _parseDate(String date) {
    try {
      final parts = date.split('/');
      return DateTime(
          int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
    } catch (_) {
      return null;
    }
  }
}

// Tarih girişini otomatik formatlayan formatter (GG/AA/YYYY)
class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue next) {
    final digits = next.text.replaceAll('/', '');
    if (digits.length > 8) return old;
    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 2 || i == 4) buf.write('/');
      buf.write(digits[i]);
    }
    final str = buf.toString();
    return TextEditingValue(
      text: str,
      selection: TextSelection.collapsed(offset: str.length),
    );
  }
}
