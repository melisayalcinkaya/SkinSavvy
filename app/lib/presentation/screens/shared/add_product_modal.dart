import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class AddProductModal extends StatefulWidget {
  final String productName;
  final String productBrand;
  const AddProductModal(
      {super.key, required this.productName, required this.productBrand});
  @override
  State<AddProductModal> createState() => _AddProductModalState();
}

class _AddProductModalState extends State<AddProductModal> {
  String usageTime = 'morning';
  final openDateCtrl = TextEditingController(text: '30/06/2026');
  final expiryDateCtrl = TextEditingController();
  final amountCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: SingleChildScrollView(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(
                child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                        color: AppColors.softGreen,
                        borderRadius: BorderRadius.circular(2)))),
            const Text('Ürün Detaylarını Ekle',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark)),
            const SizedBox(height: 4),
            Text('${widget.productName} — ${widget.productBrand}',
                style:
                    const TextStyle(fontSize: 11, color: AppColors.textGrey)),
            const SizedBox(height: 16),
            _label('Açılış Tarihi'),
            _dateField(openDateCtrl, Icons.calendar_today_outlined),
            const SizedBox(height: 12),
            _label('Son Kullanma Tarihi (SKT)'),
            _dateField(expiryDateCtrl, Icons.event_busy_outlined),
            const SizedBox(height: 12),
            _label('Miktar'),
            TextField(
                controller: amountCtrl,
                decoration: const InputDecoration(
                    hintText: 'örn: 30ml',
                    prefixIcon: Icon(Icons.inventory_2_outlined,
                        color: AppColors.secondary))),
            const SizedBox(height: 12),
            _label('Kullanım Zamanı'),
            Row(children: [
              Expanded(child: _usageBtn('Sabah', '☀️', 'morning')),
              const SizedBox(width: 8),
              Expanded(child: _usageBtn('Akşam', '🌙', 'evening')),
            ]),
            const SizedBox(height: 18),
            SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                      gradient: AppGradients.primary,
                      borderRadius: BorderRadius.circular(14)),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showSnack(context, 'Ürün detaylarıyla eklendi');
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.check, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text('Kaydet',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                        ]),
                  ),
                )),
            const SizedBox(height: 8),
            SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showSnack(
                        context, 'Ürün eklendi, detayları sonra girebilirsin');
                  },
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: AppColors.softGreen, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                  child: const Text('Daha Sonra Doldururum',
                      style: TextStyle(
                          color: AppColors.textDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                )),
          ]),
        ),
      ),
    );
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      margin: const EdgeInsets.only(bottom: 70, left: 60, right: 60),
    ));
  }

  Widget _label(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(t,
          style: const TextStyle(
              fontSize: 11,
              color: AppColors.textGrey,
              fontWeight: FontWeight.w500)));

  Widget _dateField(TextEditingController c, IconData icon) => TextField(
      controller: c,
      decoration: InputDecoration(
          hintText: 'GG/AA/YYYY',
          prefixIcon: Icon(icon, color: AppColors.secondary)));

  Widget _usageBtn(String label, String emoji, String value) {
    final active = usageTime == value;
    return GestureDetector(
        onTap: () => setState(() => usageTime = value),
        child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
                gradient: active ? AppGradients.primary : null,
                color: active ? null : AppColors.cream,
                borderRadius: BorderRadius.circular(12)),
            child: Center(
                child: Text('$emoji $label',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: active ? Colors.white : AppColors.textGrey)))));
  }
}
