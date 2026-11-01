// ============================================================
// lib/presentation/screens/routine/routine_item_detail_modal.dart
// ============================================================
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';

class RoutineItemDetailModal extends StatefulWidget {
  final RoutineItem item;
  final bool isMorning;
  final VoidCallback onToggleComplete;
  final VoidCallback onRemoveFromRoutine;

  const RoutineItemDetailModal({
    super.key,
    required this.item,
    required this.isMorning,
    required this.onToggleComplete,
    required this.onRemoveFromRoutine,
  });

  @override
  State<RoutineItemDetailModal> createState() => _RoutineItemDetailModalState();
}

class _RoutineItemDetailModalState extends State<RoutineItemDetailModal> {
  late bool _isCompleted;

  @override
  void initState() {
    super.initState();
    _isCompleted = widget.item.isCompleted;
  }

  void _toggle() {
    setState(() => _isCompleted = !_isCompleted);
    widget.onToggleComplete();
  }

  void _confirmRemove() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Rutinden Çıkar',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark)),
        content: Text(
            '"${widget.item.productName}" ürününü rutinden çıkarmak istediğinizden emin misiniz?',
            style: const TextStyle(
                fontSize: 13, color: AppColors.textGrey, height: 1.5)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal',
                  style: TextStyle(color: AppColors.textGrey))),
          TextButton(
              onPressed: () {
                Navigator.pop(context); // dialog kapat
                Navigator.pop(context); // modal kapat
                widget.onRemoveFromRoutine();
              },
              child: const Text('Çıkar',
                  style: TextStyle(
                      color: AppColors.accent, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            decoration: BoxDecoration(
                color: AppColors.softGreen,
                borderRadius: BorderRadius.circular(2))),

        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: widget.isMorning
                    ? AppGradients.morning
                    : AppGradients.evening,
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.isMorning
                    ? Icons.wb_sunny_outlined
                    : Icons.nightlight_outlined,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(
                    widget.isMorning ? 'Sabah Rutini' : 'Akşam Rutini',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textGrey),
                  ),
                  Text(widget.item.productName,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark)),
                ])),
            // Tamamlandı toggle
            GestureDetector(
              onTap: _toggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _isCompleted ? AppColors.lightGreen : AppColors.cream,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        _isCompleted ? AppColors.primary : AppColors.softGreen,
                    width: 2,
                  ),
                ),
                child: _isCompleted
                    ? const Icon(Icons.check,
                        color: AppColors.primary, size: 16)
                    : null,
              ),
            ),
          ]),
        ),

        const SizedBox(height: 16),
        const Divider(height: 1, color: AppColors.softGreen),
        const SizedBox(height: 16),

        // Ürün Detayları
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(children: [
            // Bilgi satırları
            _infoRow(Icons.business_outlined, 'Marka', widget.item.brand),
            const SizedBox(height: 10),
            _infoRow(
              _isCompleted
                  ? Icons.check_circle_outline
                  : Icons.radio_button_unchecked,
              'Durum',
              _isCompleted ? 'Tamamlandı' : 'Bekliyor',
              valueColor: _isCompleted ? AppColors.primary : AppColors.textGrey,
            ),
          ]),
        ),

        const SizedBox(height: 16),
        const Divider(height: 1, color: AppColors.softGreen),
        const SizedBox(height: 16),

        // Kullanım ipucu
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppColors.lightGreen,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.lightbulb_outline,
                  color: AppColors.primary, size: 15),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(
                _getUsageTip(widget.item.productName),
                style: const TextStyle(
                    fontSize: 11, color: AppColors.primary, height: 1.5),
              )),
            ]),
          ),
        ),

        const SizedBox(height: 16),

        // Aksiyon butonları
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            // Tamamlandı butonu
            Expanded(
                child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: _isCompleted
                    ? const LinearGradient(
                        colors: [AppColors.softGreen, AppColors.softGreen])
                    : AppGradients.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ElevatedButton.icon(
                onPressed: _toggle,
                icon: Icon(
                  _isCompleted ? Icons.close : Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
                label: Text(
                  _isCompleted ? 'Geri Al' : 'Tamamlandı',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            )),
            const SizedBox(width: 10),
            // Rutinden çıkar butonu
            OutlinedButton(
              onPressed: _confirmRemove,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.softGreen, width: 2),
                padding:
                    const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Icon(Icons.remove_circle_outline,
                  color: AppColors.accent, size: 20),
            ),
          ]),
        ),

        const SizedBox(height: 24),
      ]),
    );
  }

  Widget _infoRow(IconData icon, String label, String value,
          {Color? valueColor}) =>
      Row(children: [
        Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: AppColors.cream, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: AppColors.primary)),
        const SizedBox(width: 10),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(fontSize: 10, color: AppColors.textGrey)),
          Text(value,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? AppColors.textDark)),
        ])),
      ]);

  String _getUsageTip(String productName) {
    final name = productName.toLowerCase();
    if (name.contains('spf') || name.contains('sun')) {
      return 'Güneş kremini her sabah, nemlendiricinizden sonra uygulayın.';
    } else if (name.contains('vitamin c') || name.contains('serum')) {
      return 'Serumlar temiz cilde, nemlendirici öncesi uygulanmalıdır.';
    } else if (name.contains('retinol')) {
      return 'Retinol yalnızca geceleri kullanılmalıdır. SPF ile birleştirin.';
    } else if (name.contains('clean') || name.contains('temiz')) {
      return 'Temizleyiciyi ılık suyla, dairesel hareketlerle uygulayın.';
    }
    return 'Ürünü düzenli kullanmak en iyi sonucu verir.';
  }
}
