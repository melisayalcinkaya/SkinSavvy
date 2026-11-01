import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../main_navigation.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});
  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  int _step = 0;
  final int _totalSteps = 5;

  String? skinType;
  final Set<String> concerns = {};
  final Set<String> allergens = {};
  String? routineIntensity;

  void _next() {
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavigation()));
    }
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: SafeArea(
          child: Column(children: [
            const SizedBox(height: 12),
            _buildProgress(),
            const SizedBox(height: 10),
            Expanded(child: _buildStepContent()),
          ]),
        ),
      ),
    );
  }

  Widget _buildProgress() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Row(children: List.generate(_totalSteps, (i) => Expanded(
      child: Container(
        height: 4,
        margin: EdgeInsets.only(right: i == _totalSteps - 1 ? 0 : 4),
        decoration: BoxDecoration(
          gradient: i <= _step ? AppGradients.primary : null,
          color: i <= _step ? null : AppColors.softGreen,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    ))),
  );

  Widget _buildStepContent() {
    switch (_step) {
      case 0: return _skinTypeStep();
      case 1: return _concernsStep();
      case 2: return _allergensStep();
      case 3: return _intensityStep();
      default: return _summaryStep();
    }
  }

  Widget _stepHeader(String step, String title, String subtitle) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(step, style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w500, color: AppColors.textDark)),
      const SizedBox(height: 6),
      Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
      const SizedBox(height: 18),
    ]),
  );

  Widget _optionTile({required String emoji, required String label, String? sub, required bool selected, required VoidCallback onTap}) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: selected ? AppColors.lightGreen : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: selected ? AppColors.primary : AppColors.softGreen, width: 2),
      ),
      child: Row(children: [
        Container(
          width: 20, height: 20,
          decoration: BoxDecoration(shape: BoxShape.circle, color: selected ? AppColors.primary : Colors.transparent,
            border: Border.all(color: selected ? AppColors.primary : AppColors.softGreen, width: 2)),
          child: selected ? const Icon(Icons.check, color: Colors.white, size: 12) : null,
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$emoji $label', style: const TextStyle(fontSize: 13, color: AppColors.textDark)),
          if (sub != null) Text(sub, style: const TextStyle(fontSize: 10, color: AppColors.textGrey)),
        ])),
      ]),
    ),
  );

  Widget _bottomNav({bool showBack = true}) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
    child: Row(children: [
      if (showBack) ...[
        SizedBox(width: 48, child: OutlinedButton(onPressed: _back,
          style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.softGreen, width: 2), padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          child: const Icon(Icons.arrow_back, color: AppColors.textDark, size: 18))),
        const SizedBox(width: 10),
      ],
      Expanded(child: DecoratedBox(
        decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(14)),
        child: ElevatedButton(onPressed: _next,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 14)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
            Text('Devam Et', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
            SizedBox(width: 6), Icon(Icons.arrow_forward, color: Colors.white, size: 16),
          ]),
        ),
      )),
    ]),
  );

  Widget _skinTypeStep() {
    final options = [['🌸','Karma Cilt'],['💧','Kuru Cilt'],['✨','Yağlı Cilt'],['🌿','Normal Cilt'],['🌷','Hassas Cilt']];
    skinType ??= options[0][1];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _stepHeader('ADIM 1/5', 'Cilt tipiniz nedir?', 'Size en uygun rutini oluşturmamız için gerekli'),
      Expanded(child: ListView(padding: const EdgeInsets.symmetric(horizontal: 20),
        children: options.map((o) => _optionTile(emoji: o[0], label: o[1], selected: skinType == o[1], onTap: () => setState(() => skinType = o[1]))).toList())),
      _bottomNav(showBack: false),
    ]);
  }

  Widget _concernsStep() {
    final options = [['🔴','Sivilce / Akne'],['🟤','Leke / Renk Eşitsizliği'],['〰️','Kırışıklık / Anti-Aging'],['🕳️','Gözenek'],['💦','Nemsizlik']];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _stepHeader('ADIM 2/5', 'Cilt endişeleriniz?', 'Birden fazla seçebilirsiniz'),
      Expanded(child: ListView(padding: const EdgeInsets.symmetric(horizontal: 20),
        children: options.map((o) => _optionTile(emoji: o[0], label: o[1], selected: concerns.contains(o[1]),
          onTap: () => setState(() => concerns.contains(o[1]) ? concerns.remove(o[1]) : concerns.add(o[1])))).toList())),
      _bottomNav(),
    ]);
  }

  Widget _allergensStep() {
    final options = ['Parfüm / Fragrance','Alkol','Retinol','Niacinamide','Salisilik Asit','Lanolin','Sülfat'];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _stepHeader('ADIM 3/5', 'Alerjiniz olan etken madde var mı?', 'Size bu içerikleri önermeyeceğiz'),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: TextField(
        decoration: InputDecoration(hintText: 'Madde adı ara...', prefixIcon: const Icon(Icons.search, color: AppColors.textLight)))),
      const SizedBox(height: 14),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Text('SIK KARŞILAŞILAN ALERJENLER', style: TextStyle(fontSize: 10, color: AppColors.textGrey, fontWeight: FontWeight.w600))),
      const SizedBox(height: 8),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Wrap(spacing: 7, runSpacing: 7, children: options.map((o) {
          final sel = allergens.contains(o);
          return GestureDetector(
            onTap: () => setState(() => sel ? allergens.remove(o) : allergens.add(o)),
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(color: sel ? const Color(0xFFFFEEE8) : AppColors.lightGreen, borderRadius: BorderRadius.circular(20)),
              child: Text(o, style: TextStyle(fontSize: 11, color: sel ? AppColors.accent : AppColors.primary, fontWeight: FontWeight.w500))),
          );
        }).toList()),
      )),
      _bottomNav(),
    ]);
  }

  Widget _intensityStep() {
    final options = [
      ['🌱','Basit (2-3 adım)','Temizleyici, nemlendirici, SPF'],
      ['🌿','Orta (4-6 adım)','+ Serum, tonik'],
      ['🌳','Detaylı (7+ adım)','K-beauty tarzı çok adımlı'],
    ];
    routineIntensity ??= options[0][1];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _stepHeader('ADIM 4/5', 'Rutin yoğunluğu tercihiniz?', 'Kaç adımlık bir rutin istersiniz?'),
      Expanded(child: ListView(padding: const EdgeInsets.symmetric(horizontal: 20),
        children: options.map((o) => _optionTile(emoji: o[0], label: o[1], sub: o[2], selected: routineIntensity == o[1],
          onTap: () => setState(() => routineIntensity = o[1]))).toList())),
      _bottomNav(),
    ]);
  }

  Widget _summaryStep() => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Column(children: [
        Image.asset('assets/images/logo.png', width: 100, height: 100),
        const SizedBox(height: 8),
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(gradient: AppGradients.primary, shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 24)]),
          child: const Icon(Icons.check, color: Colors.white, size: 32),
        ),
      ]),
      const SizedBox(height: 18),
      const Text('Profiliniz Hazır! 🎉', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: AppColors.textDark)),
      const SizedBox(height: 8),
      const Text('Cilt tipinize uygun ürün önerileri ve kişisel rutininiz hazırlandı', textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: AppColors.textGrey, height: 1.5)),
      const SizedBox(height: 22),
      Container(width: double.infinity, padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _summaryRow(Icons.water_drop, skinType ?? '-'),
          const SizedBox(height: 10),
          _summaryRow(Icons.error_outline, concerns.isEmpty ? 'Belirtilmedi' : concerns.join(', ')),
          const SizedBox(height: 10),
          _summaryRow(Icons.eco_outlined, routineIntensity ?? '-'),
        ]),
      ),
      const SizedBox(height: 22),
      SizedBox(width: double.infinity, child: DecoratedBox(
        decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(14)),
        child: ElevatedButton(onPressed: _next,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 15)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
            Text('Uygulamaya Başla', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
            SizedBox(width: 6), Icon(Icons.arrow_forward, color: Colors.white, size: 16),
          ]),
        ),
      )),
    ]),
  );

  Widget _summaryRow(IconData icon, String text) => Row(children: [
    Icon(icon, color: AppColors.primary, size: 18), const SizedBox(width: 8),
    Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textDark))),
  ]);
}