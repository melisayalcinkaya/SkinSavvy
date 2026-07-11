import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

class EditSkinProfileScreen extends StatefulWidget {
  const EditSkinProfileScreen({super.key});

  @override
  State<EditSkinProfileScreen> createState() => _EditSkinProfileScreenState();
}

class _EditSkinProfileScreenState extends State<EditSkinProfileScreen> {
  bool _isLoading = false;

  // Mevcut değerler (gerçekte Firebase'den çekilir)
  String? _selectedSkinType = 'Karma Cilt';
  final Set<String> _selectedConcerns = {'Sivilce / Akne', 'Leke / Renk Eşitsizliği'};
  final Set<String> _selectedAllergens = {'Retinol'};
  String? _selectedIntensity = 'Basit (2-3 adım)';
  final TextEditingController _customAllergenCtrl = TextEditingController();

  final List<Map<String, String>> _skinTypes = [
    {'emoji': '🌸', 'label': 'Karma Cilt'},
    {'emoji': '💧', 'label': 'Kuru Cilt'},
    {'emoji': '✨', 'label': 'Yağlı Cilt'},
    {'emoji': '🌿', 'label': 'Normal Cilt'},
    {'emoji': '🌷', 'label': 'Hassas Cilt'},
  ];

  final List<Map<String, String>> _concerns = [
    {'emoji': '🔴', 'label': 'Sivilce / Akne'},
    {'emoji': '🟤', 'label': 'Leke / Renk Eşitsizliği'},
    {'emoji': '〰️', 'label': 'Kırışıklık / Anti-Aging'},
    {'emoji': '🕳️', 'label': 'Gözenek'},
    {'emoji': '💦', 'label': 'Nemsizlik'},
    {'emoji': '🌡️', 'label': 'Kuruluk'},
    {'emoji': '🔆', 'label': 'Cilt Tonu Eşitsizliği'},
  ];

  final List<String> _commonAllergens = [
    'Parfüm / Fragrance', 'Alkol', 'Retinol',
    'Niacinamide', 'Salisilik Asit', 'Lanolin',
    'Sülfat', 'Paraben', 'Propilen Glikol',
  ];

  final List<Map<String, String>> _intensities = [
    {'emoji': '🌱', 'label': 'Basit (2-3 adım)', 'sub': 'Temizleyici, nemlendirici, SPF'},
    {'emoji': '🌿', 'label': 'Orta (4-6 adım)', 'sub': '+ Serum, tonik'},
    {'emoji': '🌳', 'label': 'Detaylı (7+ adım)', 'sub': 'K-beauty tarzı çok adımlı'},
  ];

  @override
  void dispose() {
    _customAllergenCtrl.dispose();
    super.dispose();
  }

  void _addCustomAllergen() {
    final val = _customAllergenCtrl.text.trim();
    if (val.isEmpty) return;
    if (val.length < 2) {
      _showError('En az 2 karakter giriniz.');
      return;
    }
    if (val.length > 50) {
      _showError('En fazla 50 karakter giriniz.');
      return;
    }
    // Güvenlik: tehlikeli karakter kontrolü
    if (RegExp('[<>"\']').hasMatch(val)) {
      _showError('Geçersiz karakter içeriyor.');
      return;
    }
    setState(() {
      _selectedAllergens.add(val);
      _customAllergenCtrl.clear();
    });
  }

  Future<void> _save() async {
    if (_selectedSkinType == null) {
      _showError('Lütfen cilt tipinizi seçin.');
      return;
    }
    if (_selectedConcerns.isEmpty) {
      _showError('Lütfen en az bir cilt endişesi seçin.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Gerçek uygulamada Firebase:
      // await FirebaseFirestore.instance
      //   .collection('users')
      //   .doc(FirebaseAuth.instance.currentUser!.uid)
      //   .update({
      //     'skinType': _selectedSkinType,
      //     'concerns': _selectedConcerns.toList(),
      //     'allergens': _selectedAllergens.toList(),
      //     'routineIntensity': _selectedIntensity,
      //     'updatedAt': FieldValue.serverTimestamp(),
      //   });

      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      _showSuccess('Cilt profiliniz güncellendi');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showError('Güncelleme sırasında hata oluştu.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg), backgroundColor: AppColors.accent,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
  ));

  void _showSuccess(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Row(children: [
      const Icon(Icons.check_circle, color: Colors.white, size: 16),
      const SizedBox(width: 8), Text(msg),
    ]),
    backgroundColor: AppColors.primary,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
  ));

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
                _skinTypeCard(),
                const SizedBox(height: 12),
                _concernsCard(),
                const SizedBox(height: 12),
                _allergensCard(),
                const SizedBox(height: 12),
                _intensityCard(),
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
      const Expanded(child: Text('Cilt Profilim',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textDark))),
      const SizedBox(width: 48),
    ]),
  );

  Widget _skinTypeCard() => _card(
    title: 'Cilt Tipim',
    icon: Icons.water_drop_outlined,
    subtitle: 'Yalnızca bir seçenek seçilebilir',
    child: Column(
      children: _skinTypes.map((t) {
        final selected = _selectedSkinType == t['label'];
        return GestureDetector(
          onTap: () => setState(() => _selectedSkinType = t['label']),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: selected ? AppColors.lightGreen : AppColors.cream,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.softGreen,
                width: selected ? 2 : 1.5,
              ),
            ),
            child: Row(children: [
              Text(t['emoji']!, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(child: Text(t['label']!,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                  color: selected ? AppColors.primary : AppColors.textDark))),
              if (selected) const Icon(Icons.check_circle, color: AppColors.primary, size: 18),
            ]),
          ),
        );
      }).toList(),
    ),
  );

  Widget _concernsCard() => _card(
    title: 'Cilt Endişelerim',
    icon: Icons.favorite_border,
    subtitle: 'Birden fazla seçebilirsiniz',
    child: Wrap(
      spacing: 8, runSpacing: 8,
      children: _concerns.map((c) {
        final selected = _selectedConcerns.contains(c['label']);
        return GestureDetector(
          onTap: () => setState(() =>
            selected ? _selectedConcerns.remove(c['label']) : _selectedConcerns.add(c['label']!)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? AppColors.lightGreen : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.softGreen,
                width: selected ? 2 : 1.5,
              ),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(c['emoji']!, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 5),
              Text(c['label']!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                color: selected ? AppColors.primary : AppColors.textGrey)),
            ]),
          ),
        );
      }).toList(),
    ),
  );

  Widget _allergensCard() => _card(
    title: 'Alerjilerim',
    icon: Icons.warning_amber_outlined,
    subtitle: 'Bu içerikleri içeren ürünler uyarı verir',
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Seçili alerjenler
      if (_selectedAllergens.isNotEmpty) ...[
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _selectedAllergens.map((a) => Chip(
            label: Text(a, style: const TextStyle(fontSize: 11, color: AppColors.accent)),
            backgroundColor: const Color(0xFFFFEEE8),
            side: const BorderSide(color: AppColors.accent, width: 1.5),
            deleteIcon: const Icon(Icons.close, size: 14, color: AppColors.accent),
            onDeleted: () => setState(() => _selectedAllergens.remove(a)),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          )).toList(),
        ),
        const SizedBox(height: 12),
        const Divider(height: 1, color: AppColors.softGreen),
        const SizedBox(height: 12),
      ],
      // Yaygın alerjenler
      const Text('Sık Karşılaşılanlar',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textGrey)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8, runSpacing: 8,
        children: _commonAllergens
          .where((a) => !_selectedAllergens.contains(a))
          .map((a) => GestureDetector(
            onTap: () => setState(() => _selectedAllergens.add(a)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.softGreen, width: 1.5),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.add, size: 12, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(a, style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
              ]),
            ),
          )).toList(),
      ),
      const SizedBox(height: 12),
      const Divider(height: 1, color: AppColors.softGreen),
      const SizedBox(height: 12),
      // Manuel ekleme
      const Text('Listeye Ekle',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textGrey)),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: TextField(
          controller: _customAllergenCtrl,
          maxLength: 50,
          inputFormatters: [
            LengthLimitingTextInputFormatter(50),
            FilteringTextInputFormatter.deny(RegExp('[<>"\']')),
          ],
          decoration: InputDecoration(
            hintText: 'Madde adı girin...',
            hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 12),
            prefixIcon: const Icon(Icons.search, color: AppColors.textLight, size: 18),
            counterText: '',
          ),
          onSubmitted: (_) => _addCustomAllergen(),
        )),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _addCustomAllergen,
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.add, color: Colors.white, size: 20),
          ),
        ),
      ]),
    ]),
  );

  Widget _intensityCard() => _card(
    title: 'Rutin Yoğunluğu',
    icon: Icons.tune_outlined,
    subtitle: 'Ne kadar detaylı bir rutin istiyorsunuz?',
    child: Column(
      children: _intensities.map((it) {
        final selected = _selectedIntensity == it['label'];
        return GestureDetector(
          onTap: () => setState(() => _selectedIntensity = it['label']),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: selected ? AppColors.lightGreen : AppColors.cream,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.softGreen,
                width: selected ? 2 : 1.5,
              ),
            ),
            child: Row(children: [
              Text(it['emoji']!, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(it['label']!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                  color: selected ? AppColors.primary : AppColors.textDark)),
                Text(it['sub']!, style: const TextStyle(fontSize: 10, color: AppColors.textGrey)),
              ])),
              if (selected) const Icon(Icons.check_circle, color: AppColors.primary, size: 18),
            ]),
          ),
        );
      }).toList(),
    ),
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
        child: const Text('İptal',
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w500)),
      )),
      const SizedBox(width: 12),
      Expanded(flex: 2, child: DecoratedBox(
        decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(14)),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: _isLoading
            ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
                Icon(Icons.check, color: Colors.white, size: 18),
                SizedBox(width: 6),
                Text('Kaydet',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
              ]),
        ),
      )),
    ]),
  );

  Widget _card({
    required String title,
    required IconData icon,
    required Widget child,
    String? subtitle,
  }) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, color: AppColors.primary, size: 17),
        const SizedBox(width: 6),
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark)),
      ]),
      if (subtitle != null) ...[
        const SizedBox(height: 3),
        Padding(
          padding: const EdgeInsets.only(left: 23),
          child: Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textGrey)),
        ),
      ],
      const SizedBox(height: 12),
      const Divider(height: 1, color: AppColors.softGreen),
      const SizedBox(height: 12),
      child,
    ]),
  );
}