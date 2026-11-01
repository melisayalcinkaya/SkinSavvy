import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/text_utils.dart';
import '../../../data/models/routine.dart';
import '../../../data/models/shelf_item.dart';
import '../../../domain/ingredients/ingredient_analyzer.dart';
import '../../../domain/reminders/reminders.dart';
import '../../../state/catalog_controller.dart';
import '../../../state/review_controller.dart';
import '../../../state/routine_controller.dart';
import '../../../state/settings_controller.dart';
import '../../../state/shelf_controller.dart';
import '../../widgets/analysis_card.dart';
import '../../widgets/app_snack.dart';
import '../../widgets/product_image.dart';
import '../profile/share_finished_screen.dart';
import '../reviews/write_review_screen.dart';
import '../shared/add_product_modal.dart';
import 'edit_product_screen.dart';
import 'finish_product_screen.dart';

enum _Tab {
  all('Tümü', Icons.apps_outlined),
  using('Kullandıklarım', Icons.water_drop_outlined),
  wishlist('Alınacaklar', Icons.favorite_border),
  finished('Bitirdiklerim', Icons.check_circle_outline);

  const _Tab(this.label, this.icon);
  final String label;
  final IconData icon;
}

class CollectionsScreen extends StatefulWidget {
  const CollectionsScreen({super.key});
  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> {
  _Tab activeTab = _Tab.all;
  String query = '';

  /// Bitirdiklerim süzgeci: null hepsi, true memnun kaldıklarım, false
  /// kalmadıklarım ("Tekrar Alırım / Almam" cevabına göre).
  bool? satisfied;

  List<ShelfItem> _filter(List<ShelfItem> items) {
    final q = searchKey(query);
    if (q.isEmpty) return items;
    return items
        .where(
          (e) =>
              searchKey(e.name).contains(q) || searchKey(e.brand).contains(q),
        )
        .toList();
  }

  List<ShelfItem> _itemsFor(ShelfController shelf) =>
      _filter(switch (activeTab) {
        _Tab.all => shelf.owned,
        _Tab.using => shelf.using,
        _Tab.wishlist => shelf.wishlist,
        _Tab.finished => shelf.finishedBy(satisfied: satisfied),
      });

  void _showAddToRoutineModal(ShelfItem product) {
    final routine = context.read<RoutineController>();
    var selected = RoutineSlot.morning;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.softGreen,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  '${product.name} — Rutine Ekle',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Hangi rutine eklemek istiyorsunuz?',
                  style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    for (final slot in RoutineSlot.values) ...[
                      if (slot == RoutineSlot.evening)
                        const SizedBox(width: 12),
                      Expanded(
                        child: _slotOption(
                          slot,
                          selected == slot,
                          inRoutine: routine.entryFor(product.id, slot) != null,
                          onTap: () => setModalState(() => selected = slot),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppGradients.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        routine.addProduct(product.id, selected);
                        final label = selected == RoutineSlot.morning
                            ? 'sabah'
                            : 'akşam';
                        showAppSnack(
                          context,
                          '${product.name} $label rutinine eklendi',
                          bottom: 70,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Rutine Ekle',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _slotOption(
    RoutineSlot slot,
    bool active, {
    required bool inRoutine,
    required VoidCallback onTap,
  }) {
    final morning = slot == RoutineSlot.morning;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: active
              ? (morning ? AppGradients.morning : AppGradients.evening)
              : null,
          color: active ? null : AppColors.cream,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active
                ? (morning ? AppColors.accent : AppColors.primary)
                : AppColors.softGreen,
            width: active ? 2 : 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(morning ? '☀️' : '🌙', style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              morning ? 'Sabah' : 'Akşam',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: active ? Colors.white : AppColors.textDark,
              ),
            ),
            if (inRoutine)
              Text(
                'Zaten ekli',
                style: TextStyle(
                  fontSize: 9,
                  color: active ? Colors.white : AppColors.textGrey,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shelf = context.watch<ShelfController>();
    final items = _itemsFor(shelf);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: SafeArea(
          child: Column(
            children: [
              _header(items.length),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(top: 10, bottom: 16),
                  children: [
                    if (activeTab == _Tab.all && query.isEmpty)
                      _statsRow(shelf),
                    if (activeTab == _Tab.finished && shelf.finished.isNotEmpty)
                      _satisfactionFilter(shelf),
                    if (items.isEmpty) _emptyState() else ..._cards(items),
                    if (activeTab == _Tab.finished && shelf.finished.isNotEmpty)
                      _shareBanner(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _satisfactionFilter(ShelfController shelf) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
    child: Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final (value, label) in [
          (null, 'Tümü'),
          (true, 'Memnun kaldıklarım'),
          (false, 'Memnun kalmadıklarım'),
        ])
          ChoiceChip(
            label: Text(
              '$label (${shelf.finishedBy(satisfied: value).length})',
              style: TextStyle(
                fontSize: 11,
                color: satisfied == value
                    ? AppColors.primary
                    : AppColors.textGrey,
              ),
            ),
            selected: satisfied == value,
            showCheckmark: false,
            selectedColor: AppColors.lightGreen,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: satisfied == value
                  ? AppColors.primary
                  : AppColors.softGreen,
            ),
            onSelected: (_) => setState(() => satisfied = value),
          ),
      ],
    ),
  );

  Iterable<Widget> _cards(List<ShelfItem> items) => items.map(
    (it) => switch (it.status) {
      ShelfStatus.using => _productCard(it),
      ShelfStatus.wishlist => _wishlistCard(it),
      ShelfStatus.finished => _finishedCard(it),
    },
  );

  Widget _header(int count) => Container(
    color: Colors.white.withValues(alpha: 0.95),
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Koleksiyonlarım',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$count ürün',
          style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
        ),
        const SizedBox(height: 10),
        TextField(
          onChanged: (v) => setState(() => query = v),
          decoration: const InputDecoration(
            hintText: 'Ürün ara...',
            prefixIcon: Icon(Icons.search, color: AppColors.textLight),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 32,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _Tab.values.length,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (_, i) {
              final tab = _Tab.values[i];
              final active = activeTab == tab;
              return GestureDetector(
                onTap: () => setState(() => activeTab = tab),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    gradient: active ? AppGradients.primary : null,
                    color: active ? null : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tab.icon,
                        size: 13,
                        color: active ? Colors.white : AppColors.textGrey,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        tab.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: active ? Colors.white : AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );

  Widget _statsRow(ShelfController shelf) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
    child: Row(
      children: [
        Expanded(
          child: _miniStat(
            Icons.inventory_2_outlined,
            AppColors.primary,
            '${shelf.owned.length}',
            'Toplam',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _miniStat(
            Icons.error_outline,
            AppColors.accent,
            '${shelf.runningLowCount}',
            'Bitmek Üzere',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _miniStat(
            Icons.favorite_border,
            AppColors.primary,
            '${shelf.favoriteCount}',
            'Favori',
          ),
        ),
      ],
    ),
  );

  Widget _miniStat(IconData icon, Color color, String value, String label) =>
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 3),
            Text(
              value,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: AppColors.textGrey),
            ),
          ],
        ),
      );

  Widget _emptyState() {
    final shelf = context.read<ShelfController>();
    final (icon, title, sub) = switch (activeTab) {
      _ when query.isNotEmpty => (
        Icons.search_off_outlined,
        'Sonuç yok',
        '"$query" ile eşleşen ürün bulunamadı.',
      ),
      _Tab.wishlist => (
        Icons.favorite_border,
        'Alınacaklar listen boş',
        'Ürün detayında "alınacaklara ekle" diyerek listeyi doldurabilirsin.',
      ),
      _Tab.finished when satisfied != null && shelf.finished.isNotEmpty => (
        Icons.filter_alt_off_outlined,
        'Bu grupta ürün yok',
        satisfied == true
            ? 'Bitirip "Tekrar Alırım" dediğin ürünler burada görünür.'
            : 'Bitirip "Tekrar Almam" dediğin ürünler burada görünür.',
      ),
      _Tab.finished => (
        Icons.check_circle_outline,
        'Henüz bitirdiğin ürün yok',
        'Bir ürün bittiğinde ⋮ menüsünden "Ürünü Bitir"i seç.',
      ),
      _ => (
        Icons.inventory_2_outlined,
        'Dolabın boş',
        'Ürünler sekmesinden kullandığın ürünleri ekleyerek başla.',
      ),
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 24),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.lightGreen,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sub,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textGrey,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(
    String text, {
    Color bg = AppColors.cream,
    Color fg = AppColors.textGrey,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: fg),
    ),
  );

  BoxDecoration get _cardDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
    ],
  );

  Future<void> _openReview(ShelfItem it) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => WriteReviewScreen(product: it)),
  );

  void _showItemMenu(ShelfItem it) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.softGreen,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('Düzenle'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditProductScreen(product: it),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.accent,
                ),
                title: const Text('Ürünü Bitir'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FinishProductScreen(product: it),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: AppColors.textGrey,
                ),
                title: const Text('Dolaptan Kaldır'),
                subtitle: const Text(
                  'Yanlışlıkla eklediysen',
                  style: TextStyle(fontSize: 11),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _confirmRemove(it);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmRemove(ShelfItem it) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Dolaptan Kaldır',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        content: Text(
          '"${it.name}" dolabından ve rutinlerinden kaldırılacak.',
          style: const TextStyle(fontSize: 13, color: AppColors.textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              'İptal',
              style: TextStyle(color: AppColors.textGrey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Kaldır',
              style: TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      context.read<ShelfController>().remove(it.id);
      showAppSnack(context, 'Ürün kaldırıldı', bottom: 70);
    }
  }

  Widget _productCard(ShelfItem it) {
    final hasReview = context.select<ReviewController, bool>(
      (r) => r.forShelfItem(it.id) != null,
    );
    final pending = context.select<CatalogController, bool>(
      (c) => c.byId(it.productId)?.isPending ?? false,
    );
    // Profildeki bir alerjen bu üründe var mı?
    final avoid = analyzeForUser(context, it.ingredients).findings
        .where((f) => f.level == FindingLevel.avoid)
        .map((f) => f.title)
        .toList();
    // SKT ile açılış + PAO'dan hangisi önce dolarsa.
    final expiry = expiryInfo(it);
    final daysLeft = expiry?.daysLeft(DateTime.now());
    final warnDays = context.select<SettingsController, int>(
      (s) => s.settings.expiryWarningDays,
    );
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProductImage(
                it.imageUrl,
                width: 60,
                height: 60,
                category: it.category,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            it.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context
                              .read<ShelfController>()
                              .toggleFavorite(it.id),
                          child: Icon(
                            it.isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 15,
                            color: it.isFavorite
                                ? AppColors.accent
                                : AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      it.brand,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 5,
                      runSpacing: 4,
                      children: [
                        _chip(
                          it.statusLabel,
                          bg: it.isRunningLow
                              ? const Color(0xFFFFEEE8)
                              : AppColors.lightGreen,
                          fg: it.isRunningLow
                              ? AppColors.accent
                              : AppColors.primary,
                        ),
                        _chip(it.category),
                        if (pending)
                          _chip('Onay bekliyor', bg: AppColors.softGreen),
                        if (daysLeft != null && daysLeft <= warnDays)
                          _chip(
                            daysLeft < 0
                                ? 'Süresi doldu'
                                : daysLeft == 0
                                ? 'Bugün son gün'
                                : '$daysLeft gün kaldı',
                            bg: daysLeft < 0
                                ? const Color(0xFFFFEEE8)
                                : const Color(0xFFFFF3E3),
                            fg: daysLeft < 0
                                ? AppColors.accent
                                : const Color(0xFFB4651F),
                          ),
                        for (final title in avoid)
                          _chip(
                            '⚠ $title',
                            bg: const Color(0xFFFFEEE8),
                            fg: AppColors.accent,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Diğer işlemler',
                visualDensity: VisualDensity.compact,
                onPressed: () => _showItemMenu(it),
                icon: const Icon(
                  Icons.more_vert,
                  color: AppColors.textLight,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Kalan miktar',
                style: TextStyle(fontSize: 11, color: AppColors.textGrey),
              ),
              Text(
                '%${it.remaining}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: it.remaining / 100,
              minHeight: 6,
              backgroundColor: AppColors.softGreen,
              valueColor: AlwaysStoppedAnimation(
                it.isRunningLow ? AppColors.accent : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 4,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            children: [
              _detailItem(
                Icons.calendar_today_outlined,
                'Açılış',
                formatDateShort(it.openedOn),
              ),
              _detailItem(
                Icons.event_busy_outlined,
                'Son kullanma',
                formatDateShort(expiry?.date),
              ),
              _detailItem(
                Icons.inventory_2_outlined,
                'Miktar',
                it.amount.isEmpty ? '-' : it.amount,
              ),
              _detailItem(
                Icons.access_time,
                'Kullanım',
                it.usage.isEmpty ? '-' : it.usage,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              ...List.generate(
                5,
                (i) => Icon(
                  Icons.star,
                  size: 14,
                  color: i < it.rating ? AppColors.peach : AppColors.softGreen,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _openReview(it),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                icon: const Icon(
                  Icons.chat_bubble_outline,
                  size: 13,
                  color: AppColors.primary,
                ),
                label: Text(
                  hasReview ? 'Yorumu Düzenle' : 'Yorum Yaz',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          if (it.note.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                it.note,
                style: const TextStyle(fontSize: 11, color: AppColors.textDark),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditProductScreen(product: it),
                    ),
                  ),
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 13,
                    color: AppColors.textDark,
                  ),
                  label: const Text(
                    'Düzenle',
                    style: TextStyle(fontSize: 11, color: AppColors.textDark),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: AppColors.softGreen,
                      width: 2,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppGradients.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton(
                    onPressed: () => _showAddToRoutineModal(it),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 9),
                    ),
                    child: const Text(
                      'Rutine Ekle',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailItem(IconData icon, String label, String value) => Row(
    children: [
      Icon(icon, size: 13, color: AppColors.textLight),
      const SizedBox(width: 5),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: AppColors.textGrey),
            ),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _wishlistCard(ShelfItem it) => Container(
    margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
    padding: const EdgeInsets.all(14),
    decoration: _cardDecoration,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProductImage(
              it.imageUrl,
              width: 60,
              height: 60,
              category: it.category,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    it.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    it.brand,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _chip(
                    it.category,
                    bg: AppColors.lightGreen,
                    fg: AppColors.primary,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Listeden çıkar',
              visualDensity: VisualDensity.compact,
              onPressed: () => context.read<ShelfController>().remove(it.id),
              icon: const Icon(
                Icons.close,
                size: 18,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton.icon(
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => AddProductModal(shelfItem: it),
                  ),
                  icon: const Icon(Icons.add, size: 14, color: Colors.white),
                  label: const Text(
                    'Aldım, Kullanmaya Başla',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _finishedCard(ShelfItem it) {
    final hasReview = context.select<ReviewController, bool>(
      (r) => r.forShelfItem(it.id) != null,
    );
    final rebuy = it.wouldRebuy ?? false;
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProductImage(
                it.imageUrl,
                width: 60,
                height: 60,
                category: it.category,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      it.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      it.brand,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 5,
                      children: [
                        _chip(
                          rebuy ? '✓ Tekrar Alırım' : '✗ Tekrar Almam',
                          bg: rebuy
                              ? AppColors.lightGreen
                              : const Color(0xFFFFEEE8),
                          fg: rebuy ? AppColors.primary : AppColors.accent,
                        ),
                        if (it.finishedOn != null)
                          _chip('Bitti: ${formatDateShort(it.finishedOn)}'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (it.note.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                it.note,
                style: const TextStyle(fontSize: 11, color: AppColors.textDark),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openReview(it),
                  icon: const Icon(
                    Icons.chat_bubble_outline,
                    size: 13,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    hasReview ? 'Yorumu Düzenle' : 'Yorum Yaz',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: AppColors.softGreen,
                      width: 2,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppGradients.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => AddProductModal(shelfItem: it),
                    ),
                    icon: const Icon(
                      Icons.refresh,
                      color: Colors.white,
                      size: 13,
                    ),
                    label: const Text(
                      'Tekrar Kullan',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _shareBanner() => GestureDetector(
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ShareFinishedScreen()),
    ),
    child: Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.share_outlined, color: AppColors.primary, size: 17),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Bitirdiklerimi arkadaşlarımla paylaş',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(Icons.chevron_right, color: AppColors.primary, size: 16),
        ],
      ),
    ),
  );
}
