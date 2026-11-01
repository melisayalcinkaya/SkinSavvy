import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/text_utils.dart';
import '../../../data/models/product.dart';
import '../../../data/models/routine.dart';
import '../../../data/models/shelf_item.dart';
import '../../../state/routine_controller.dart';
import '../../../state/shelf_controller.dart';
import '../../widgets/app_snack.dart';
import '../../widgets/date_input.dart';

/// Ürünü dolaba "kullanıyorum" olarak ekler. Katalogdan bir ürün ya da
/// alınacaklar/bitirdiklerim listesindeki bir kayıt ile açılabilir.
class AddProductModal extends StatefulWidget {
  const AddProductModal({super.key, this.product, this.shelfItem})
    : assert(product != null || shelfItem != null);

  final Product? product;
  final ShelfItem? shelfItem;

  @override
  State<AddProductModal> createState() => _AddProductModalState();
}

class _AddProductModalState extends State<AddProductModal> {
  final _formKey = GlobalKey<FormState>();
  final openDateCtrl = TextEditingController(
    text: formatDateInput(DateTime.now()),
  );
  final expiryDateCtrl = TextEditingController();
  final amountCtrl = TextEditingController();
  final Set<RoutineSlot> slots = {RoutineSlot.morning};
  int? paoMonths;
  bool addToRoutine = true;

  static const paoChoices = [3, 6, 9, 12, 18, 24];

  String get _name => widget.product?.name ?? widget.shelfItem!.name;
  String get _brand => widget.product?.brand ?? widget.shelfItem!.brand;

  @override
  void dispose() {
    openDateCtrl.dispose();
    expiryDateCtrl.dispose();
    amountCtrl.dispose();
    super.dispose();
  }

  String get _usage => switch (slots.length) {
    2 => 'Sabah & Akşam',
    1 => slots.first == RoutineSlot.morning ? 'Sabah' : 'Akşam',
    _ => '',
  };

  void _save({required bool withDetails}) {
    if (withDetails && !_formKey.currentState!.validate()) return;
    final shelf = context.read<ShelfController>();
    final routine = context.read<RoutineController>();
    final opened = withDetails ? parseDateInput(openDateCtrl.text) : null;
    final expires = withDetails ? parseDateInput(expiryDateCtrl.text) : null;
    final amount = withDetails ? sanitizeInput(amountCtrl.text) : '';
    final usage = withDetails ? _usage : '';

    final ShelfItem item;
    final existing = widget.shelfItem;
    if (existing != null) {
      item = shelf.startUsing(
        existing.id,
        openedOn: opened,
        expiresOn: expires,
        paoMonths: withDetails ? paoMonths : null,
        amount: amount,
        usage: usage,
      );
    } else {
      item = shelf.addProduct(
        widget.product!,
        openedOn: opened,
        expiresOn: expires,
        paoMonths: withDetails ? paoMonths : null,
        amount: amount,
        usage: usage,
      );
    }
    if (withDetails && addToRoutine) {
      for (final slot in slots) {
        routine.addProduct(item.id, slot);
      }
    }
    Navigator.pop(context);
    showAppSnack(
      context,
      withDetails
          ? 'Ürün dolabına eklendi'
          : 'Ürün eklendi, detayları sonra girebilirsin',
      bottom: 70,
    );
  }

  void _addToWishlist() {
    context.read<ShelfController>().addProduct(
      widget.product!,
      status: ShelfStatus.wishlist,
    );
    Navigator.pop(context);
    showAppSnack(context, 'Alınacaklar listene eklendi', bottom: 70);
  }

  String? _validateDate(String? v, {required bool required}) {
    if (v == null || v.isEmpty) return required ? 'Tarih girin.' : null;
    final d = parseDateInput(v);
    if (d == null) return 'GG/AA/YYYY biçiminde geçerli bir tarih girin.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final canWishlist = widget.product != null;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.softGreen,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text(
                    'Ürün Detaylarını Ekle',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_name — $_brand',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textGrey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Açılış Tarihi'),
                            _dateField(
                              openDateCtrl,
                              Icons.calendar_today_outlined,
                              required: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Son Kullanma (SKT)'),
                            _dateField(
                              expiryDateCtrl,
                              Icons.event_busy_outlined,
                              required: false,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _label('Açıldıktan Sonra Kullanım Süresi'),
                  const Text(
                    'Ambalajdaki açık kavanoz simgesi (ör. 12M)',
                    style: TextStyle(fontSize: 10, color: AppColors.textLight),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final m in paoChoices)
                        ChoiceChip(
                          label: Text('$m ay'),
                          selected: paoMonths == m,
                          onSelected: (on) =>
                              setState(() => paoMonths = on ? m : null),
                          selectedColor: AppColors.lightGreen,
                          labelStyle: TextStyle(
                            fontSize: 11,
                            color: paoMonths == m
                                ? AppColors.primary
                                : AppColors.textGrey,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _label('Miktar'),
                  TextFormField(
                    controller: amountCtrl,
                    maxLength: 20,
                    inputFormatters: [LengthLimitingTextInputFormatter(20)],
                    decoration: const InputDecoration(
                      counterText: '',
                      hintText: 'örn: 30 ml',
                      prefixIcon: Icon(
                        Icons.inventory_2_outlined,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _label('Kullanım Zamanı'),
                  Row(
                    children: [
                      Expanded(
                        child: _usageBtn('Sabah', '☀️', RoutineSlot.morning),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _usageBtn('Akşam', '🌙', RoutineSlot.evening),
                      ),
                    ],
                  ),
                  if (slots.isNotEmpty)
                    CheckboxListTile(
                      value: addToRoutine,
                      onChanged: (v) =>
                          setState(() => addToRoutine = v ?? false),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: AppColors.primary,
                      title: const Text(
                        'Rutinime de ekle (her gün)',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppGradients.primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ElevatedButton(
                        onPressed: () => _save(withDetails: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check, color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Kaydet',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _save(withDetails: false),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: AppColors.softGreen,
                          width: 2,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Daha Sonra Doldururum',
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  if (canWishlist)
                    TextButton.icon(
                      onPressed: _addToWishlist,
                      icon: const Icon(
                        Icons.favorite_border,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      label: const Text(
                        'Henüz almadım, alınacaklara ekle',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Text(
      t,
      style: const TextStyle(
        fontSize: 11,
        color: AppColors.textGrey,
        fontWeight: FontWeight.w500,
      ),
    ),
  );

  Widget _dateField(
    TextEditingController c,
    IconData icon, {
    required bool required,
  }) => TextFormField(
    controller: c,
    keyboardType: TextInputType.number,
    inputFormatters: [DateInputFormatter()],
    validator: (v) => _validateDate(v, required: required),
    decoration: InputDecoration(
      hintText: 'GG/AA/YYYY',
      errorMaxLines: 2,
      prefixIcon: Icon(icon, color: AppColors.secondary, size: 18),
    ),
  );

  Widget _usageBtn(String label, String emoji, RoutineSlot slot) {
    final active = slots.contains(slot);
    return Semantics(
      button: true,
      selected: active,
      child: GestureDetector(
        onTap: () =>
            setState(() => active ? slots.remove(slot) : slots.add(slot)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: active ? AppGradients.primary : null,
            color: active ? null : AppColors.cream,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              '$emoji $label',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: active ? Colors.white : AppColors.textGrey,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
