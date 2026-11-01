import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import 'pending_approval_screen.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});
  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _ingredientsCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();

  String? _selectedCategory;
  final List<String> _selectedSkinTypes = [];
  File? _selectedImage;
  bool _isLoading = false;
  int _currentStep = 0;

  // Güvenlik: max karakter limitleri
  static const int _maxNameLength = 100;
  static const int _maxBrandLength = 100;
  static const int _maxDescLength = 500;
  static const int _maxIngredientsLength = 2000;
  static const int _maxImageSizeMB = 5;

  final List<String> _categories = [
    'Temizleyici',
    'Nemlendirici',
    'Serum',
    'Güneş Kremi',
    'Maske',
    'Tonik',
    'Göz Kremi',
    'Yağ',
    'Peeling',
    'Diğer',
  ];

  final List<String> _skinTypes = [
    'Tüm Cilt Tipleri',
    'Kuru Cilt',
    'Yağlı Cilt',
    'Karma Cilt',
    'Normal Cilt',
    'Hassas Cilt',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _descCtrl.dispose();
    _ingredientsCtrl.dispose();
    _barcodeCtrl.dispose();
    super.dispose();
  }

  // ── Güvenlik: Input sanitizer ──────────────────────────────
  String _sanitize(String input) {
    // Tehlikeli karakter ve script taglarını temizle
    return input
        .replaceAll(RegExp(r'<[^>]*>'), '') // HTML tag temizle
        .replaceAll(RegExp('[<>"\']'), '') // tehlikeli karakterler
        .trim();
  }

  // ── Güvenlik: Fotoğraf doğrulama ──────────────────────────
  Future<bool> _validateImage(File file) async {
    // Dosya boyutu kontrolü (max 5MB)
    final bytes = await file.length();
    final mb = bytes / (1024 * 1024);
    if (mb > _maxImageSizeMB) {
      _showError('Fotoğraf boyutu maksimum $_maxImageSizeMB MB olabilir.');
      return false;
    }

    // Dosya uzantısı kontrolü
    final ext = file.path.split('.').last.toLowerCase();
    if (!['jpg', 'jpeg', 'png'].contains(ext)) {
      _showError('Sadece JPG ve PNG formatları kabul edilmektedir.');
      return false;
    }

    return true;
  }

  // ── Fotoğraf seçici (gerçek uygulamada image_picker kullanılır) ──
  Future<void> _pickImage() async {
    // Gerçek implementasyonda:
    // final picker = ImagePicker();
    // final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    // if (picked != null) {
    //   final file = File(picked.path);
    //   final valid = await _validateImage(file);
    //   if (valid) setState(() => _selectedImage = file);
    // }

    // Şimdilik demo için sadece state güncelle
    setState(() {
      // Simülasyon: fotoğraf seçildi
    });
    _showInfo(
        'Fotoğraf seçici — gerçek uygulamada image_picker paketi kullanılacak.');
  }

  // ── Duplicate kontrol ──────────────────────────────────────
  Future<bool> _checkDuplicate() async {
    // Gerçek uygulamada Firebase'de kontrol edilir:
    // final query = await FirebaseFirestore.instance
    //   .collection('products')
    //   .where('name', isEqualTo: _sanitize(_nameCtrl.text))
    //   .where('brand', isEqualTo: _sanitize(_brandCtrl.text))
    //   .get();
    // return query.docs.isNotEmpty;
    return false; // Demo için false
  }

  // ── Form gönder ────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      _showError('Lütfen bir kategori seçin.');
      return;
    }
    if (_selectedSkinTypes.isEmpty) {
      _showError('Lütfen en az bir cilt tipi seçin.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Duplicate kontrolü
      final isDuplicate = await _checkDuplicate();
      if (isDuplicate) {
        setState(() => _isLoading = false);
        _showDuplicateWarning();
        return;
      }

      // Gerçek uygulamada Firebase işlemleri:
      // 1. Fotoğraf Storage'a yükle
      // 2. Ürün Firestore'a ekle (status: pending)
      // 3. Kullanıcının user_products koleksiyonuna ekle
      // 4. Admin'e bildirim gönder

      // Simüle edelim
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PendingApprovalScreen(
            productName: _sanitize(_nameCtrl.text),
            brandName: _sanitize(_brandCtrl.text),
          ),
        ),
      );
    } catch (e) {
      _showError('Bir hata oluştu. Lütfen tekrar deneyin.');
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
      margin: const EdgeInsets.only(bottom: 70, left: 20, right: 20),
    ));
  }

  void _showInfo(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      margin: const EdgeInsets.only(bottom: 70, left: 20, right: 20),
    ));
  }

  void _showDuplicateWarning() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Ürün Zaten Mevcut',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark)),
        content: const Text(
            'Bu ürün sistemde zaten kayıtlı. Mevcut ürünü koleksiyonunuza ekleyebilirsiniz.',
            style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Geri Dön',
                  style: TextStyle(color: AppColors.textGrey))),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Mevcut Ürüne Git',
                  style: TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  // ── Adım göstergesi ────────────────────────────────────────
  Widget _buildStepIndicator() {
    final steps = ['Temel Bilgiler', 'Detaylar', 'Fotoğraf'];
    return Row(
      children: List.generate(steps.length, (i) {
        final isActive = i == _currentStep;
        final isDone = i < _currentStep;
        return Expanded(
          child: Row(children: [
            Expanded(
                child: Column(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: isActive || isDone ? AppGradients.primary : null,
                  color: isActive || isDone ? null : AppColors.softGreen,
                  shape: BoxShape.circle,
                ),
                child: Center(
                    child: isDone
                        ? const Icon(Icons.check, color: Colors.white, size: 14)
                        : Text('${i + 1}',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isActive
                                    ? Colors.white
                                    : AppColors.textGrey))),
              ),
              const SizedBox(height: 4),
              Text(steps[i],
                  style: TextStyle(
                      fontSize: 8.5,
                      color: isActive ? AppColors.primary : AppColors.textGrey,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.w400)),
            ])),
            if (i < steps.length - 1)
              Container(
                  width: 24,
                  height: 2,
                  color: i < _currentStep
                      ? AppColors.primary
                      : AppColors.softGreen),
          ]),
        );
      }),
    );
  }

  // ── ADIM 1: Temel Bilgiler ─────────────────────────────────
  Widget _buildStep1() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle('Ürün Adı *'),
      TextFormField(
        controller: _nameCtrl,
        maxLength: _maxNameLength,
        inputFormatters: [LengthLimitingTextInputFormatter(_maxNameLength)],
        textCapitalization: TextCapitalization.words,
        decoration: _inputDec(
            'örn: Hydrating Facial Cleanser', Icons.inventory_2_outlined),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Ürün adı zorunludur.';
          if (v.trim().length < 3) return 'En az 3 karakter giriniz.';
          return null;
        },
      ),
      const SizedBox(height: 14),
      _sectionTitle('Marka *'),
      TextFormField(
        controller: _brandCtrl,
        maxLength: _maxBrandLength,
        inputFormatters: [LengthLimitingTextInputFormatter(_maxBrandLength)],
        textCapitalization: TextCapitalization.words,
        decoration: _inputDec('örn: CeraVe', Icons.business_outlined),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Marka zorunludur.';
          if (v.trim().length < 2) return 'En az 2 karakter giriniz.';
          return null;
        },
      ),
      const SizedBox(height: 14),
      _sectionTitle('Kategori *'),
      _categoryDropdown(),
      const SizedBox(height: 14),
      _sectionTitle('Uygun Cilt Tipleri *'),
      const Text('Birden fazla seçebilirsiniz',
          style: TextStyle(fontSize: 10, color: AppColors.textGrey)),
      const SizedBox(height: 8),
      _skinTypeChips(),
    ]);
  }

  // ── ADIM 2: Detaylar ───────────────────────────────────────
  Widget _buildStep2() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle('İçerik Listesi (Ingredients) *'),
      const Text('Virgülle ayırarak giriniz',
          style: TextStyle(fontSize: 10, color: AppColors.textGrey)),
      const SizedBox(height: 8),
      TextFormField(
        controller: _ingredientsCtrl,
        maxLength: _maxIngredientsLength,
        maxLines: 5,
        inputFormatters: [
          LengthLimitingTextInputFormatter(_maxIngredientsLength)
        ],
        decoration: InputDecoration(
          hintText: 'Aqua, Glycerin, Niacinamide...',
          hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 12),
          alignLabelWithHint: true,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: AppColors.softGreen, width: 2)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: AppColors.softGreen, width: 2)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary, width: 2)),
          filled: true,
          fillColor: AppColors.cream,
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty)
            return 'İçerik listesi zorunludur.';
          if (v.trim().length < 10)
            return 'Lütfen daha detaylı içerik listesi giriniz.';
          return null;
        },
      ),
      const SizedBox(height: 14),
      _sectionTitle('Ürün Açıklaması (Opsiyonel)'),
      TextFormField(
        controller: _descCtrl,
        maxLength: _maxDescLength,
        maxLines: 3,
        inputFormatters: [LengthLimitingTextInputFormatter(_maxDescLength)],
        decoration: InputDecoration(
          hintText: 'Ürün hakkında kısa bilgi...',
          hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 12),
          alignLabelWithHint: true,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: AppColors.softGreen, width: 2)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: AppColors.softGreen, width: 2)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary, width: 2)),
          filled: true,
          fillColor: AppColors.cream,
        ),
      ),
      const SizedBox(height: 14),
      _sectionTitle('Barkod Numarası (Opsiyonel)'),
      TextFormField(
        controller: _barcodeCtrl,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(13),
        ],
        decoration: _inputDec('örn: 3600523008130', Icons.qr_code_outlined),
      ),
    ]);
  }

  // ── ADIM 3: Fotoğraf ───────────────────────────────────────
  Widget _buildStep3() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle('Ürün Fotoğrafı *'),
      const Text('Max 5MB • JPG veya PNG',
          style: TextStyle(fontSize: 10, color: AppColors.textGrey)),
      const SizedBox(height: 12),
      GestureDetector(
        onTap: _pickImage,
        child: Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppColors.softGreen, width: 2, style: BorderStyle.solid),
          ),
          child: _selectedImage != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(_selectedImage!, fit: BoxFit.cover))
              : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                          color: AppColors.lightGreen, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt_outlined,
                          color: AppColors.primary, size: 26)),
                  const SizedBox(height: 12),
                  const Text('Fotoğraf Seç',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary)),
                  const SizedBox(height: 4),
                  const Text('Galeriden seç veya fotoğraf çek',
                      style:
                          TextStyle(fontSize: 11, color: AppColors.textGrey)),
                ]),
        ),
      ),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: AppColors.lightGreen,
            borderRadius: BorderRadius.circular(14)),
        child:
            const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.info_outline, color: AppColors.primary, size: 16),
          SizedBox(width: 8),
          Expanded(
              child: Text(
            'Ürün bilgileriniz incelendikten sonra sisteme eklenecektir. Bu süreçte ürün yalnızca sizin dolabınızda "Beklemede" olarak görünür.',
            style:
                TextStyle(fontSize: 11, color: AppColors.primary, height: 1.5),
          )),
        ]),
      ),
    ]);
  }

  Widget _categoryDropdown() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.softGreen, width: 2),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedCategory,
            hint: const Text('Kategori seçin',
                style: TextStyle(color: AppColors.textLight, fontSize: 13)),
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down,
                color: AppColors.textGrey),
            items: _categories
                .map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textDark))))
                .toList(),
            onChanged: (v) => setState(() => _selectedCategory = v),
          ),
        ),
      );

  Widget _skinTypeChips() => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _skinTypes.map((t) {
          final selected = _selectedSkinTypes.contains(t);
          return GestureDetector(
            onTap: () => setState(() => selected
                ? _selectedSkinTypes.remove(t)
                : _selectedSkinTypes.add(t)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: selected ? AppColors.lightGreen : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: selected ? AppColors.primary : AppColors.softGreen,
                    width: 1.5),
              ),
              child: Text(t,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color:
                          selected ? AppColors.primary : AppColors.textGrey)),
            ),
          );
        }).toList(),
      );

  InputDecoration _inputDec(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.secondary, size: 20),
      );

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark)),
      );

  // ── İleri / Geri butonları ─────────────────────────────────
  Widget _buildNavButtons() {
    final isLast = _currentStep == 2;
    return Row(children: [
      if (_currentStep > 0) ...[
        SizedBox(
            width: 48,
            child: OutlinedButton(
              onPressed: () => setState(() => _currentStep--),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.softGreen, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Icon(Icons.arrow_back,
                  color: AppColors.textDark, size: 18),
            )),
        const SizedBox(width: 10),
      ],
      Expanded(
          child: DecoratedBox(
        decoration: BoxDecoration(
            gradient: AppGradients.primary,
            borderRadius: BorderRadius.circular(14)),
        child: ElevatedButton(
          onPressed: _isLoading
              ? null
              : () {
                  if (isLast) {
                    _submit();
                  } else {
                    if (_formKey.currentState!.validate()) {
                      if (_currentStep == 0 && _selectedCategory == null) {
                        _showError('Lütfen bir kategori seçin.');
                        return;
                      }
                      if (_currentStep == 0 && _selectedSkinTypes.isEmpty) {
                        _showError('Lütfen en az bir cilt tipi seçin.');
                        return;
                      }
                      setState(() => _currentStep++);
                    }
                  }
                },
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
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(isLast ? 'İncelemeye Gönder' : 'Devam Et',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  const SizedBox(width: 6),
                  Icon(isLast ? Icons.send_outlined : Icons.arrow_forward,
                      color: Colors.white, size: 16),
                ]),
        ),
      )),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(children: [
            // Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Column(children: [
                Row(children: [
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back,
                          color: AppColors.textDark)),
                  const Expanded(
                      child: Text('Yeni Ürün Ekle',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textDark))),
                  const SizedBox(width: 48),
                ]),
                const SizedBox(height: 14),
                _buildStepIndicator(),
              ]),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: KeyedSubtree(
                    key: ValueKey(_currentStep),
                    child: _currentStep == 0
                        ? _buildStep1()
                        : _currentStep == 1
                            ? _buildStep2()
                            : _buildStep3(),
                  ),
                ),
              ),
            ),
            // Bottom nav
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: _buildNavButtons(),
            ),
          ]),
        ),
      ),
    );
  }
}
