import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/skin_options.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/product.dart';
import '../../../state/catalog_controller.dart';
import '../../widgets/app_snack.dart';
import '../../widgets/product_photo.dart';

/// Ekibin öneriyi düzeltip onayladığı form. Ad, marka, kategori, cilt
/// tipleri, içerik, açıklama, barkod ve fotoğraf değiştirilebilir.
///
/// Kaydedilince düzeltilmiş ürünü döndürür; onaylama işini çağıran yapar.
/// Sınırlar ürün önerme formuyla ve sunucuyla aynıdır.
class ModerationEditScreen extends StatefulWidget {
  const ModerationEditScreen({super.key, required this.product});

  final Product product;

  @override
  State<ModerationEditScreen> createState() => _ModerationEditScreenState();
}

class _ModerationEditScreenState extends State<ModerationEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Product _p = widget.product;
  late final _name = TextEditingController(text: _p.name);
  late final _brand = TextEditingController(text: _p.brand);
  late final _ingredients = TextEditingController(
    text: _p.ingredients.join(', '),
  );
  late final _description = TextEditingController(text: _p.description);
  late final _barcode = TextEditingController(text: _p.barcode);
  late String _category = productCategories.contains(_p.category)
      ? _p.category
      : productCategories.first;
  late final Set<String> _skinTypes = {..._p.skinTypes};
  late String _image = _p.imageUrl;

  @override
  void dispose() {
    for (final c in [_name, _brand, _ingredients, _description, _barcode]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final url = await pickProductPhoto(
      (m) => showAppSnack(context, m, error: true),
    );
    if (url != null && mounted) setState(() => _image = url);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final ingredients = parseIngredients(_ingredients.text);
    String? error;
    if (_skinTypes.isEmpty) error = 'En az bir cilt tipi seçin.';
    if (ingredients.length < 2) error = 'İçerik listesi en az 2 madde olmalı.';
    if (_image.isEmpty) error = 'Ürün fotoğrafı zorunlu.';
    final barcode = _barcode.text.trim();
    final dup = context.read<CatalogController>().findDuplicate(
      _name.text,
      _brand.text,
      barcode: barcode,
      ignoreId: _p.id,
    );
    if (dup != null) {
      error =
          '"${dup.brand} ${dup.name}" zaten katalogda; '
          'bu öneriyi "Yinelenen" olarak işaretleyin.';
    }
    if (error != null) {
      showAppSnack(context, error, error: true);
      return;
    }
    Navigator.pop(
      context,
      _p.copyWith(
        name: _name.text.trim(),
        brand: _brand.text.trim(),
        category: _category,
        skinTypes: [
          for (final t in productSkinTypes)
            if (_skinTypes.contains(t)) t,
        ],
        ingredients: ingredients,
        description: _description.text.trim(),
        barcode: barcode.isEmpty ? null : barcode,
        clearBarcode: barcode.isEmpty,
        imageUrl: _image,
      ),
    );
  }

  String? _required(String? v, int min) =>
      (v ?? '').trim().length < min ? 'En az $min karakter girin.' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          tooltip: 'Geri',
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Düzenle ve onayla',
          style: TextStyle(fontSize: 15, color: AppColors.textDark),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Öneren: ${_p.addedBy ?? 'kullanıcı'}. Düzelttiğin bilgiler '
                  'onayla birlikte kaydedilir; önerene "ekip düzenledi" notuyla '
                  'bildirim gider.',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textGrey,
                  ),
                ),
                const SizedBox(height: 12),
                ProductPhotoBox(image: _image, onTap: _pickImage, height: 170),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _name,
                  maxLength: 80,
                  decoration: const InputDecoration(labelText: 'Ürün adı'),
                  validator: (v) => _required(v, 3),
                ),
                TextFormField(
                  controller: _brand,
                  maxLength: 60,
                  decoration: const InputDecoration(labelText: 'Marka'),
                  validator: (v) => _required(v, 2),
                ),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Kategori'),
                  items: [
                    for (final c in productCategories)
                      DropdownMenuItem(value: c, child: Text(c)),
                  ],
                  onChanged: (v) => setState(() => _category = v ?? _category),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Uygun cilt tipleri',
                  style: TextStyle(fontSize: 12, color: AppColors.textDark),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final t in productSkinTypes)
                      FilterChip(
                        label: Text(t, style: const TextStyle(fontSize: 11)),
                        selected: _skinTypes.contains(t),
                        selectedColor: AppColors.lightGreen,
                        checkmarkColor: AppColors.primary,
                        onSelected: (on) => setState(
                          () => on ? _skinTypes.add(t) : _skinTypes.remove(t),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _ingredients,
                  maxLength: 2000,
                  minLines: 3,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'İçerik listesi (virgülle)',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => _required(v, 10),
                ),
                TextFormField(
                  controller: _description,
                  maxLength: 500,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama (isteğe bağlı)',
                    alignLabelWithHint: true,
                  ),
                ),
                TextFormField(
                  controller: _barcode,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(13),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Barkod (isteğe bağlı)',
                  ),
                ),
                const SizedBox(height: 20),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppGradients.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Kaydet ve onayla'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
