import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ThemeScreen extends StatefulWidget {
  const ThemeScreen({super.key});

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  String _selectedTheme = 'light'; // light | dark | system

  final List<Map<String, dynamic>> _themes = [
    {
      'id': 'light',
      'label': 'Açık Tema',
      'sub': 'Beyaz arka plan, koyu yazılar',
      'emoji': '☀️',
      'preview': [AppColors.cream, Colors.white, AppColors.primary],
    },
    {
      'id': 'dark',
      'label': 'Koyu Tema',
      'sub': 'Koyu arka plan, açık yazılar',
      'emoji': '🌙',
      'preview': [const Color(0xFF1A1A2E), const Color(0xFF16213E), AppColors.primary],
    },
    {
      'id': 'system',
      'label': 'Sistemi Takip Et',
      'sub': 'Cihaz temasını otomatik uygular',
      'emoji': '📱',
      'preview': [AppColors.softGreen, AppColors.cream, AppColors.secondary],
    },
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
                _previewCard(),
                const SizedBox(height: 12),
                _themeOptionsCard(),
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
      const Expanded(child: Text('Tema',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textDark))),
      const SizedBox(width: 48),
    ]),
  );

  Widget _previewCard() {
    final selected = _themes.firstWhere((t) => t['id'] == _selectedTheme);
    final colors = selected['preview'] as List<Color>;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.palette_outlined, color: AppColors.primary, size: 17),
          SizedBox(width: 6),
          Text('Önizleme', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark)),
        ]),
        const SizedBox(height: 12),
        const Divider(height: 1, color: AppColors.softGreen),
        const SizedBox(height: 16),
        // Telefon önizlemesi
        Center(
          child: Container(
            width: 160, height: 100,
            decoration: BoxDecoration(
              color: colors[0],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.softGreen, width: 1.5),
            ),
            child: Column(children: [
              // Topbar simülasyonu
              Container(
                height: 28,
                decoration: BoxDecoration(
                  color: colors[1],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(children: [
                  Container(width: 40, height: 8, decoration: BoxDecoration(
                    color: colors[2], borderRadius: BorderRadius.circular(4))),
                  const Spacer(),
                  Container(width: 20, height: 20, decoration: BoxDecoration(
                    color: colors[2], shape: BoxShape.circle)),
                ]),
              ),
              const SizedBox(height: 8),
              // Kart simülasyonu
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(children: [
                  Container(height: 10, decoration: BoxDecoration(
                    color: colors[1], borderRadius: BorderRadius.circular(6))),
                  const SizedBox(height: 6),
                  Row(children: [
                    Expanded(child: Container(height: 28, decoration: BoxDecoration(
                      color: colors[1], borderRadius: BorderRadius.circular(8)))),
                    const SizedBox(width: 6),
                    Expanded(child: Container(height: 28, decoration: BoxDecoration(
                      color: colors[2].withOpacity(0.3), borderRadius: BorderRadius.circular(8)))),
                  ]),
                ]),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Center(child: Text(
          '${selected['emoji']} ${selected['label']}',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark),
        )),
      ]),
    );
  }

  Widget _themeOptionsCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [
        Icon(Icons.style_outlined, color: AppColors.primary, size: 17),
        SizedBox(width: 6),
        Text('Tema Seçin', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark)),
      ]),
      const SizedBox(height: 12),
      const Divider(height: 1, color: AppColors.softGreen),
      const SizedBox(height: 12),
      ..._themes.map((t) {
        final selected = _selectedTheme == t['id'];
        return GestureDetector(
          onTap: () => setState(() => _selectedTheme = t['id'] as String),
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
              Text(t['emoji'] as String, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t['label'] as String, style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500,
                  color: selected ? AppColors.primary : AppColors.textDark,
                )),
                Text(t['sub'] as String,
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
        'Koyu tema backend entegrasyonu tamamlandığında aktif olacaktır. Şu an yalnızca Açık Tema geçerlidir.',
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
            // Gerçek uygulamada SharedPreferences'a kaydet:
            // await SharedPreferences.getInstance()
            //   .then((p) => p.setString('theme', _selectedTheme));
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Row(children: [
                Icon(Icons.check_circle, color: Colors.white, size: 16),
                SizedBox(width: 8), Text('Tema kaydedildi'),
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