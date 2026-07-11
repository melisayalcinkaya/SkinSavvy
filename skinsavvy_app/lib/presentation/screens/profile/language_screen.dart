import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _selectedLang = 'tr';

  final List<Map<String, String>> _languages = [
    {'id': 'tr', 'label': 'Türkçe', 'flag': '🇹🇷', 'sub': 'Varsayılan dil'},
    {'id': 'en', 'label': 'English', 'flag': '🇬🇧', 'sub': 'English language'},
  ];

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
                _langCard(),
                const SizedBox(height: 12),
                _infoCard(),
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
      const Expanded(child: Text('Dil',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textDark))),
      const SizedBox(width: 48),
    ]),
  );

  Widget _langCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [
        Icon(Icons.language_outlined, color: AppColors.primary, size: 17),
        SizedBox(width: 6),
        Text('Uygulama Dili', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark)),
      ]),
      const SizedBox(height: 12),
      const Divider(height: 1, color: AppColors.softGreen),
      const SizedBox(height: 12),
      ..._languages.map((l) {
        final selected = _selectedLang == l['id'];
        return GestureDetector(
          onTap: () => setState(() => _selectedLang = l['id']!),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: selected ? AppColors.lightGreen : AppColors.cream,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.softGreen,
                width: selected ? 2 : 1.5,
              ),
            ),
            child: Row(children: [
              Text(l['flag']!, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l['label']!, style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500,
                  color: selected ? AppColors.primary : AppColors.textDark,
                )),
                Text(l['sub']!,
                  style: const TextStyle(fontSize: 10, color: AppColors.textGrey)),
              ])),
              if (selected)
                const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
            ]),
          ),
        );
      }),
    ]),
  );

  Widget _infoCard() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.lightGreen, borderRadius: BorderRadius.circular(16)),
    child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(Icons.info_outline, color: AppColors.primary, size: 16),
      SizedBox(width: 8),
      Expanded(child: Text(
        'Dil değişikliği uygulamayı yeniden başlatmanızı gerektirebilir. İngilizce desteği yakında eklenecektir.',
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
        child: const Text('İptal',
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w500)),
      )),
      const SizedBox(width: 12),
      Expanded(flex: 2, child: DecoratedBox(
        decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(14)),
        child: ElevatedButton(
          onPressed: () {
            // Gerçek uygulamada:
            // await SharedPreferences.getInstance()
            //   .then((p) => p.setString('language', _selectedLang));
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Row(children: [
                Icon(Icons.check_circle, color: Colors.white, size: 16),
                SizedBox(width: 8), Text('Dil kaydedildi'),
              ]),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
            ));
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
            Icon(Icons.check, color: Colors.white, size: 18),
            SizedBox(width: 6),
            Text('Kaydet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
          ]),
        ),
      )),
    ]),
  );
}