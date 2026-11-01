import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class RoutineEditorScreen extends StatefulWidget {
  final String routineType; // 'morning' | 'evening'
  const RoutineEditorScreen({super.key, required this.routineType});
  @override
  State<RoutineEditorScreen> createState() => _RoutineEditorScreenState();
}

class _RoutineEditorScreenState extends State<RoutineEditorScreen> {
  String activeCat = 'all';
  final days7 = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

  final categories = const [
    {'id': 'all', 'label': 'Tümü', 'emoji': '🌿'},
    {'id': 'cleanser', 'label': 'Temizleyici', 'emoji': '💧'},
    {'id': 'serum', 'label': 'Serum', 'emoji': '✨'},
    {'id': 'moisturizer', 'label': 'Nemlendirici', 'emoji': '🧴'},
    {'id': 'sunscreen', 'label': 'Güneş', 'emoji': '☀️'},
    {'id': 'mask', 'label': 'Maske', 'emoji': '🎭'},
  ];

  final myProducts = [
    {'id': 'r1', 'name': 'Hydrating Cleanser', 'brand': 'CeraVe', 'cat': 'cleanser', 'emoji': '💧'},
    {'id': 'r2', 'name': 'Vitamin C Serum', 'brand': 'The Ordinary', 'cat': 'serum', 'emoji': '✨'},
    {'id': 'r3', 'name': 'Moisturizer', 'brand': 'La Roche-Posay', 'cat': 'moisturizer', 'emoji': '🧴'},
    {'id': 'r4', 'name': 'SPF 50+', 'brand': 'Bioderma', 'cat': 'sunscreen', 'emoji': '☀️'},
    {'id': 'r5', 'name': 'Retinol Serum', 'brand': "Paula's Choice", 'cat': 'serum', 'emoji': '🌙'},
    {'id': 'r6', 'name': 'Clay Mask', 'brand': 'Innisfree', 'cat': 'mask', 'emoji': '🎭'},
  ];

  // dayIndex -> list of product ids
  final Map<int, List<String>> schedule = {2: ['r1', 'r2'], 3: ['r1', 'r2', 'r4'], 4: ['r1'], 5: ['r3']};

  void _toggleSchedule(int day, String pid) {
    setState(() {
      schedule.putIfAbsent(day, () => []);
      if (schedule[day]!.contains(pid)) {
        schedule[day]!.remove(pid);
      } else {
        schedule[day]!.add(pid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = activeCat == 'all' ? myProducts : myProducts.where((p) => p['cat'] == activeCat).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            child: Row(children: [
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back, color: AppColors.textDark)),
              Expanded(child: Text(widget.routineType == 'morning' ? 'Sabah Rutini' : 'Akşam Rutini',
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textDark))),
              GestureDetector(onTap: () => Navigator.pop(context),
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(10)),
                  child: const Text('Kaydet', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)))),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: AppColors.lightGreen,
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.touch_app_outlined, size: 13, color: AppColors.primary), SizedBox(width: 6),
              Text('Ürünü güne eklemek için noktaya dokun', style: TextStyle(fontSize: 9.5, color: AppColors.textGrey)),
            ]),
          ),
          Expanded(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Container(
                width: 84, color: AppColors.cream,
                child: ListView(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
                  children: categories.map((c) {
                    final active = activeCat == c['id'];
                    return GestureDetector(
                      onTap: () => setState(() => activeCat = c['id'] as String),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 4), padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
                        decoration: BoxDecoration(color: active ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(14),
                          border: active ? Border.all(color: AppColors.softGreen) : null),
                        child: Column(children: [
                          Container(width: 34, height: 34,
                            decoration: BoxDecoration(gradient: active ? AppGradients.primary : null, color: active ? null : AppColors.softGreen, borderRadius: BorderRadius.circular(11)),
                            child: Center(child: Text(c['emoji'] as String, style: const TextStyle(fontSize: 16)))),
                          const SizedBox(height: 3),
                          Text(c['label'] as String, textAlign: TextAlign.center, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w500, color: active ? AppColors.primary : AppColors.textGrey)),
                        ]),
                      ),
                    );
                  }).toList(),
                ),
              ),
              Expanded(
                child: ListView(padding: const EdgeInsets.all(10), children: filtered.map((p) {
                  final pid = p['id'] as String;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 7), padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(14)),
                    child: Row(children: [
                      Container(width: 32, height: 32, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(9), border: Border.all(color: AppColors.softGreen)),
                        child: Center(child: Text(p['emoji'] as String, style: const TextStyle(fontSize: 16)))),
                      const SizedBox(width: 9),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p['name'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(p['brand'] as String, style: const TextStyle(fontSize: 9, color: AppColors.textGrey)),
                        const SizedBox(height: 4),
                        Wrap(spacing: 2, children: List.generate(7, (i) {
                          final on = (schedule[i] ?? []).contains(pid);
                          return GestureDetector(
                            onTap: () => _toggleSchedule(i, pid),
                            child: Container(width: 15, height: 15,
                              decoration: BoxDecoration(gradient: on ? AppGradients.primary : null, color: on ? null : AppColors.softGreen, borderRadius: BorderRadius.circular(4)),
                              child: Center(child: Text(days7[i][0], style: TextStyle(fontSize: 6.5, fontWeight: FontWeight.bold, color: on ? Colors.white : AppColors.textLight)))),
                          );
                        })),
                      ])),
                    ]),
                  );
                }).toList()),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}