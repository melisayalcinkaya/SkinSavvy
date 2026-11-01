import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import 'routine_editor_screen.dart';
import 'routine_item_detail_modal.dart';

class RoutineHomeScreen extends StatefulWidget {
  const RoutineHomeScreen({super.key});
  @override
  State<RoutineHomeScreen> createState() => _RoutineHomeScreenState();
}

class _RoutineHomeScreenState extends State<RoutineHomeScreen> {
  int selectedDate = 15;
  final dates = [12, 13, 14, 15, 16, 17, 18];
  final days = ['P', 'Pt', 'S', 'Ç', 'Pe', 'C', 'Ct'];
  final todayDate = 15;

  final List<RoutineItem> morning = [
    RoutineItem(
        id: '1',
        productName: 'Hydrating Cleanser',
        brand: 'CeraVe',
        time: '08:00',
        emoji: '💧',
        isCompleted: true),
    RoutineItem(
        id: '2',
        productName: 'Vitamin C Serum',
        brand: 'The Ordinary',
        time: '08:05',
        emoji: '✨',
        isCompleted: true),
    RoutineItem(
        id: '3',
        productName: 'SPF 50+',
        brand: 'Bioderma',
        time: '08:10',
        emoji: '☀️',
        isCompleted: false),
  ];
  final List<RoutineItem> evening = [
    RoutineItem(
        id: '4',
        productName: 'Cleansing Oil',
        brand: 'DHC',
        time: '21:00',
        emoji: '🧴',
        isCompleted: false),
    RoutineItem(
        id: '5',
        productName: 'Retinol Serum',
        brand: "Paula's Choice",
        time: '21:10',
        emoji: '🌙',
        isCompleted: false),
  ];

  void _openEditor(String type) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => RoutineEditorScreen(routineType: type)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: SafeArea(
          child: Column(children: [
            _header(),
            Expanded(
              child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  children: [
                    _routineCard(
                        isMorning: true, items: morning, title: 'Sabah Rutini'),
                    _routineCard(
                        isMorning: false,
                        items: evening,
                        title: 'Akşam Rutini'),
                    _statsRow(),
                    _tipCard(),
                  ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _header() => Container(
        color: Colors.white.withOpacity(0.95),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Merhaba Melis 👋',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textDark)),
                  SizedBox(height: 2),
                  Text('Bugün cildiniz nasıl?',
                      style:
                          TextStyle(fontSize: 10, color: AppColors.textGrey)),
                ]),
            GestureDetector(
              onTap: () {
                // profil sayfasına yönlendir — isteğe bağlı
              },
              child: Image.asset(
                'assets/images/logo.png',
                width: 42,
                height: 42,
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(16)),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(7, (i) {
                  final d = dates[i];
                  final isSel = d == selectedDate;
                  final isToday = d == todayDate && !isSel;
                  return GestureDetector(
                    onTap: () => setState(() => selectedDate = d),
                    child: Column(children: [
                      Text(days[i],
                          style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.textGrey,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                            gradient: isSel ? AppGradients.primary : null,
                            color: isToday ? AppColors.peach : null,
                            shape: BoxShape.circle),
                        child: Center(
                            child: Text('$d',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isSel
                                        ? Colors.white
                                        : isToday
                                            ? AppColors.accent
                                            : AppColors.textDark))),
                      ),
                    ]),
                  );
                })),
          ),
        ]),
      );

  Widget _routineCard(
      {required bool isMorning,
      required List<RoutineItem> items,
      required String title}) {
    final done = items.where((i) => i.isCompleted).length;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ]),
      child: Column(children: [
        Row(children: [
          Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  gradient:
                      isMorning ? AppGradients.morning : AppGradients.evening,
                  shape: BoxShape.circle),
              child: Icon(
                  isMorning
                      ? Icons.wb_sunny_outlined
                      : Icons.nightlight_outlined,
                  color: Colors.white,
                  size: 17)),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDark)),
                const SizedBox(height: 3),

                // --- YENİ EKLENEN SAAT VE DURUM KISMI ---
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: AppColors.lightGreen,
                        borderRadius: BorderRadius.circular(20)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.access_time,
                          size: 10, color: AppColors.primary),
                      const SizedBox(width: 3),
                      Text(isMorning ? '08:00' : '21:00',
                          style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500)),
                      const Text(' • ',
                          style: TextStyle(
                              fontSize: 10, color: AppColors.primary)),
                      Text('$done/${items.length} tamamlandı',
                          style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500)),
                    ])),
                // --- ENTEGRASYON SONU ---
              ])),
          GestureDetector(
            onTap: () => _openEditor(isMorning ? 'morning' : 'evening'),
            child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: AppColors.lightGreen,
                    borderRadius: BorderRadius.circular(10)),
                child: Row(children: const [
                  Icon(Icons.edit_outlined, size: 14, color: AppColors.primary),
                  SizedBox(width: 4),
                  Text('Düzenle',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500)),
                ])),
          ),
        ]),
        const SizedBox(height: 10),
        ...items.map((item) => GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => RoutineItemDetailModal(
                    item: item,
                    isMorning: isMorning,
                    onToggleComplete: () =>
                        setState(() => item.isCompleted = !item.isCompleted),
                    onRemoveFromRoutine: () {
                      setState(() {
                        if (isMorning)
                          morning.remove(item);
                        else
                          evening.remove(item);
                      });
                    },
                  ),
                );
              },
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: item.isCompleted ? 0.55 : 1,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 7),
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(14)),
                  child: Row(children: [
                    Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                            color: item.isCompleted
                                ? AppColors.lightGreen
                                : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: item.isCompleted
                                    ? AppColors.primary
                                    : AppColors.softGreen,
                                width: 2)),
                        child: item.isCompleted
                            ? const Icon(Icons.check,
                                color: AppColors.primary, size: 16)
                            : Center(
                                child: Text(item.emoji,
                                    style: const TextStyle(fontSize: 15)))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(item.productName,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textDark,
                                  decoration: item.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null)),
                          Text('${item.brand} • ${item.time}',
                              style: const TextStyle(
                                  fontSize: 10, color: AppColors.textGrey)),
                        ])),
                    const Icon(Icons.chevron_right,
                        color: AppColors.textLight, size: 16),
                  ]),
                ),
              ),
            )),
      ]),
    );
  }

  Widget _statsRow() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Row(children: [
          Expanded(
              child: _statCard(Icons.water_drop_outlined, AppColors.primary,
                  '7 gün', 'Seri devam ediyor 🔥')),
          const SizedBox(width: 10),
          Expanded(
              child: _statCard(Icons.auto_awesome_outlined, AppColors.peach,
                  '85%', 'Bu hafta tamamlama')),
        ]),
      );

  Widget _statCard(IconData icon, Color color, String value, String sub) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark)),
          const SizedBox(height: 2),
          Text(sub,
              style: const TextStyle(fontSize: 10, color: AppColors.textGrey)),
        ]),
      );

  Widget _tipCard() => Container(
        margin: const EdgeInsets.fromLTRB(14, 6, 14, 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            gradient: AppGradients.primary,
            borderRadius: BorderRadius.circular(20)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
              child: const Icon(Icons.lightbulb_outline,
                  color: Colors.white, size: 16)),
          const SizedBox(width: 10),
          const Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Günün İpucu',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 12)),
                SizedBox(height: 4),
                Text(
                    'Güneş kremi her gün kullanılmalıdır. UV ışınları bulutlu havalarda da zarar verebilir.',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 10, height: 1.5)),
              ])),
        ]),
      );
}
