import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/skin_options.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/image_utils.dart';
import '../../../data/models/product.dart';
import '../../../data/remote/api_client.dart';
import '../../../state/catalog_controller.dart';
import '../../../state/session_controller.dart';
import '../../../state/shelf_controller.dart';
import '../../widgets/app_snack.dart';
import '../../widgets/analysis_card.dart';
import '../../widgets/product_image.dart';
import 'pending_approval_screen.dart';
import 'product_detail_screen.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key, this.initialName = '', this.resubmit});

  /// Arama kutusuna yazılan ad ("Ürün bulunamadı" ekranından gelince).
  final String initialName;

  /// Reddedilen bir öneri: form onun bilgileriyle dolar, gönderilince
  /// eski öneri yerine yenisi incelemeye girer.
  final Product? resubmit;
  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Product? _old = widget.resubmit;
  late final _nameCtrl = TextEditingController(
    text: _old?.name ?? widget.initialName.trim(),
  );
  late final _brandCtrl = TextEditingController(text: _old?.brand);
  late final _descCtrl = TextEditingController(text: _old?.description);
  late final _ingredientsCtrl = TextEditingController(
    text: _old?.ingredients.join(', '),
  );
  late final _barcodeCtrl = TextEditingController(text: _old?.barcode);

  late String? _selectedCategory = _old?.category;
  late final List<String> _selectedSkinTypes = [...?_old?.skinTypes];
  late String? _imageData = (_old?.imageUrl.isEmpty ?? true)
      ? null
      : _old!.imageUrl;
  bool _isLoading = false;
  int _currentStep = 0;

  // Güvenlik: max karakter limitleri
  // Sunucudaki sınırlarla aynı (backend/app/schemas.py).
  static const int _maxNameLength = 80;
  static const int _maxBrandLength = 60;
  static const int _maxDescLength = 500;
  static const int _maxIngredientsLength = 2000;

  static const _categories = productCategories;
  static const _skinTypes = productSkinTypes;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _descCtrl.dispose();
    _ingredientsCtrl.dispose();
    _barcodeCtrl.dispose();
    super.dispose();
  }

  // ── Fotoğraf seçici ────────────────────────────────────────
  Future<void> _pickImage() async {
    try {
      // Görsel cihazda küçültülür; hem depolama hem yükleme boyutu düşer.
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (picked == null) return;
      final image = toImageDataUrl(
        await picked.readAsBytes(),
        maxKb: maxProductImageKb,
      );
      if (image.error != null) {
        _showError(image.error!);
        return;
      }
      setState(() => _imageData = image.url);
    } on PlatformException {
      _showError('Galeriye erişilemedi. İzinleri kontrol edin.');
    }
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

    final ingredients = parseIngredients(_ingredientsCtrl.text);
    if (ingredients.length < 2) {
      _showError('İçerik listesini virgülle ayırarak girin (en az 2 madde).');
      setState(() => _currentStep = 1);
      return;
    }

    final catalog = context.read<CatalogController>();
    final duplicate = catalog.findDuplicate(
      _nameCtrl.text,
      _brandCtrl.text,
      barcode: _barcodeCtrl.text,
    );
    if (duplicate != null && duplicate.id != _old?.id) {
      _showDuplicateWarning(duplicate.id);
      return;
    }

    setState(() => _isLoading = true);
    // Ürün yönetici onayına kadar "pending" kalır ve yalnızca ekleyen kişiye
    // görünür. Sunucu modunda API'ye gönderilir.
    final Product product;
    try {
      product = await catalog.submit(
        name: _nameCtrl.text,
        brand: _brandCtrl.text,
        category: _selectedCategory!,
        skinTypes: List.of(_selectedSkinTypes),
        ingredients: ingredients,
        description: _descCtrl.text,
        barcode: _barcodeCtrl.text,
        imageUrl: _imageData ?? '',
        submitterName: context.read<SessionController>().user?.publicName,
        replacing: _old?.id,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(e.message);
      return;
    }
    if (!mounted) return;
    final shelf = context.read<ShelfController>();
    // Düzeltilen önerinin eski dolap kaydı yenisiyle değişir (çift olmasın).
    final previous = _old == null ? null : shelf.activeForProduct(_old.id);
    if (previous != null) shelf.remove(previous.id);
    shelf.addProduct(product);
    setState(() => _isLoading = false);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PendingApprovalScreen(
          productName: product.name,
          brandName: product.brand,
        ),
      ),
    );
  }

  void _showError(String msg) =>
      showAppSnack(context, msg, error: true, bottom: 70);

  void _showDuplicateWarning(String existingId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Ürün Zaten Mevcut',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        content: const Text(
          'Bu ürün sistemde zaten kayıtlı. Mevcut ürünü koleksiyonunuza ekleyebilirsiniz.',
          style: TextStyle(fontSize: 13, color: AppColors.textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Geri Dön',
              style: TextStyle(color: AppColors.textGrey),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductDetailScreen(productId: existingId),
                ),
              );
            },
            child: const Text(
              'Mevcut Ürüne Git',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
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
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: isActive || isDone
                            ? AppGradients.primary
                            : null,
                        color: isActive || isDone ? null : AppColors.softGreen,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 14,
                              )
                            : Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isActive
                                      ? Colors.white
                                      : AppColors.textGrey,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      steps[i],
                      style: TextStyle(
                        fontSize: 8.5,
                        color: isActive
                            ? AppColors.primary
                            : AppColors.textGrey,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if (i < steps.length - 1)
                Container(
                  width: 24,
                  height: 2,
                  color: i < _currentStep
                      ? AppColors.primary
                      : AppColors.softGreen,
                ),
            ],
          ),
        );
      }),
    );
  }

  // ── ADIM 1: Temel Bilgiler ─────────────────────────────────
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Ürün Adı *'),
        TextFormField(
          controller: _nameCtrl,
          maxLength: _maxNameLength,
          inputFormatters: [LengthLimitingTextInputFormatter(_maxNameLength)],
          textCapitalization: TextCapitalization.words,
          decoration: _inputDec(
            'örn: Hydrating Facial Cleanser',
            Icons.inventory_2_outlined,
          ),
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
        const Text(
          'Birden fazla seçebilirsiniz',
          style: TextStyle(fontSize: 10, color: AppColors.textGrey),
        ),
        const SizedBox(height: 8),
        _skinTypeChips(),
      ],
    );
  }

  // ── ADIM 2: Detaylar ───────────────────────────────────────
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('İçerik Listesi (Ingredients) *'),
        const Text(
          'Virgülle ayırarak giriniz',
          style: TextStyle(fontSize: 10, color: AppColors.textGrey),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _ingredientsCtrl,
          maxLength: _maxIngredientsLength,
          maxLines: 5,
          inputFormatters: [
            LengthLimitingTextInputFormatter(_maxIngredientsLength),
          ],
          decoration: InputDecoration(
            hintText: 'Aqua, Glycerin, Niacinamide...',
            hintStyle: const TextStyle(
              color: AppColors.textLight,
              fontSize: 12,
            ),
            alignLabelWithHint: true,
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
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'İçerik listesi zorunludur.';
            }
            if (v.trim().length < 10) {
              return 'Lütfen daha detaylı içerik listesi giriniz.';
            }
            return null;
          },
        ),
        // Yazdıkça profile göre analiz: kullanıcı ürünü göndermeden önce
        // kendi alerjenlerini ve uyarıları görür.
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _ingredientsCtrl,
          builder: (context, value, _) {
            final list = parseIngredients(value.text);
            if (list.length < 2) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: AnalysisCard(
                analysis: analyzeForUser(context, list),
                showIngredients: false,
              ),
            );
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
            hintStyle: const TextStyle(
              color: AppColors.textLight,
              fontSize: 12,
            ),
            alignLabelWithHint: true,
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
      ],
    );
  }

  // ── ADIM 3: Fotoğraf ───────────────────────────────────────
  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Ürün Fotoğrafı (Opsiyonel)'),
        const Text(
          'En fazla $maxProductImageKb KB • JPG veya PNG',
          style: TextStyle(fontSize: 10, color: AppColors.textGrey),
        ),
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
                color: AppColors.softGreen,
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: _imageData != null
                ? ProductImage(_imageData!, radius: 14)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.lightGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt_outlined,
                          color: AppColors.primary,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Fotoğraf Seç',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Galeriden seç veya fotoğraf çek',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.lightGreen,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: AppColors.primary, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ürün bilgileriniz incelendikten sonra sisteme eklenecektir. Bu süreçte ürün yalnızca sizin dolabınızda "Beklemede" olarak görünür.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
        hint: const Text(
          'Kategori seçin',
          style: TextStyle(color: AppColors.textLight, fontSize: 13),
        ),
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textGrey),
        items: _categories
            .map(
              (c) => DropdownMenuItem(
                value: c,
                child: Text(
                  c,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            )
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
        onTap: () => setState(
          () => selected
              ? _selectedSkinTypes.remove(t)
              : _selectedSkinTypes.add(t),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? AppColors.lightGreen : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.softGreen,
              width: 1.5,
            ),
          ),
          child: Text(
            t,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: selected ? AppColors.primary : AppColors.textGrey,
            ),
          ),
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
    child: Text(
      t,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textDark,
      ),
    ),
  );

  // ── İleri / Geri butonları ─────────────────────────────────
  Widget _buildNavButtons() {
    final isLast = _currentStep == 2;
    return Row(
      children: [
        if (_currentStep > 0) ...[
          SizedBox(
            width: 48,
            child: OutlinedButton(
              onPressed: () => setState(() => _currentStep--),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.softGreen, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: AppColors.textDark,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              borderRadius: BorderRadius.circular(14),
            ),
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
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isLast ? 'İncelemeye Gönder' : 'Devam Et',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          isLast ? Icons.send_outlined : Icons.arrow_forward,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
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
              // Header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: AppColors.textDark,
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'Yeni Ürün Ekle',
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
                    const SizedBox(height: 14),
                    _buildStepIndicator(),
                  ],
                ),
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
            ],
          ),
        ),
      ),
    );
  }
}
