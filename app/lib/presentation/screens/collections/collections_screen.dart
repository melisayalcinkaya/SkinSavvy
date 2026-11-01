import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import 'edit_product_screen.dart';
import 'finish_product_screen.dart';
import '../reviews/write_review_screen.dart';
import '../shared/add_product_modal.dart';
import '../profile/share_finished_screen.dart';

class CollectionsScreen extends StatefulWidget {
  const CollectionsScreen({super.key});
  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> {

  void _showAddToRoutineModal(BuildContext context, MyProduct product) {
  String selectedTime = 'morning';
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => StatefulBuilder(
      builder: (ctx, setModalState) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: AppColors.softGreen, borderRadius: BorderRadius.circular(2))),
          Text('${product.name} — Rutine Ekle',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textDark)),
          const SizedBox(height: 6),
          const Text('Hangi rutine eklemek istiyorsunuz?',
            style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => setModalState(() => selectedTime = 'morning'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: selectedTime == 'morning' ? AppGradients.morning : null,
                  color: selectedTime == 'morning' ? null : AppColors.cream,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selectedTime == 'morning' ? AppColors.accent : AppColors.softGreen,
                    width: selectedTime == 'morning' ? 2 : 1.5),
                ),
                child: Column(children: const [
                  Text('☀️', style: TextStyle(fontSize: 24)),
                  SizedBox(height: 4),
                  Text('Sabah', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                ]),
              ),
            )),
            const SizedBox(width: 12),
            Expanded(child: GestureDetector(
              onTap: () => setModalState(() => selectedTime = 'evening'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: selectedTime == 'evening' ? AppGradients.evening : null,
                  color: selectedTime == 'evening' ? null : AppColors.cream,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selectedTime == 'evening' ? AppColors.primary : AppColors.softGreen,
                    width: selectedTime == 'evening' ? 2 : 1.5),
                ),
                child: Column(children: const [
                  Text('🌙', style: TextStyle(fontSize: 24)),
                  SizedBox(height: 4),
                  Text('Akşam', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                ]),
              ),
            )),
          ]),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: DecoratedBox(
            decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(14)),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Kullandıklarım listesine ekle (zaten orada ama emin ol)
                setState(() {
                  // Gerçek uygulamada Firebase'e yaz:
                  // routine collection güncelle
                });
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Row(children: [
                    const Icon(Icons.check_circle, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text('${product.name} ${selectedTime == 'morning' ? 'sabah' : 'akşam'} rutinine eklendi'),
                  ]),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  margin: const EdgeInsets.only(bottom: 70, left: 20, right: 20),
                ));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('Rutine Ekle',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
            ),
          )),
        ]),
      ),
    ),
  );
}
  String activeTab = 'all';
  String query = '';

  final tabs = const [
    {'id': 'all', 'label': 'Tümü', 'icon': Icons.apps_outlined},
    {'id': 'using', 'label': 'Kullandıklarım', 'icon': Icons.water_drop_outlined},
    {'id': 'wishlist', 'label': 'Alınacaklar', 'icon': Icons.favorite_border},
    {'id': 'finished', 'label': 'Bitirdiklerim', 'icon': Icons.check_circle_outline},
  ];

  final List<MyProduct> myProducts = [
    MyProduct(name: 'Hydrating Cleanser', brand: 'CeraVe', imageUrl: 'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=200', category: 'Temizleyici', status: 'Kullanımda', remaining: 75, openDate: '20 Oca 2024', expiryDate: '20 Oca 2026', amount: '236ml', usage: 'Sabah & Akşam', rating: 5, note: 'Cildi kurutmuyor, çok seviyorum!', isFavorite: true),
    MyProduct(name: 'Vitamin C Serum', brand: 'The Ordinary', imageUrl: 'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?w=200', category: 'Serum', status: 'Kullanımda', remaining: 40, openDate: '10 Şub 2024', expiryDate: '10 Ağu 2024', amount: '30ml', usage: 'Sabah', rating: 4, note: 'Lekeler için harika!', isFavorite: true),
    MyProduct(name: 'Retinol Cream', brand: "Paula's Choice", imageUrl: 'https://images.unsplash.com/photo-1590439471364-192aa70c9999?w=200', category: 'Krem', status: 'Bitmek Üzere', remaining: 15, openDate: '15 Oca 2024', expiryDate: '15 Tem 2024', amount: '50ml', usage: 'Akşam', rating: 4, note: 'Bitmek üzere, yenisini almayı unutma!'),
  ];

  final List<WishlistProduct> wishlist = [
    WishlistProduct(name: 'Niacinamide Serum', brand: 'The Ordinary', imageUrl: 'https://images.unsplash.com/photo-1608248543803-ba4f8c70ae0b?w=200', category: 'Serum', price: '349.90'),
    WishlistProduct(name: 'Clay Mask', brand: 'Innisfree', imageUrl: 'https://images.unsplash.com/photo-1571781926291-c477ebfd024b?w=200', category: 'Maske', price: '189.90'),
  ];

  final List<FinishedProduct> finished = [
    FinishedProduct(name: 'Hyaluronic Acid', brand: 'The Ordinary', imageUrl: 'https://images.unsplash.com/photo-1590439471364-192aa70c9999?w=200', category: 'Serum', wouldRebuy: true, note: 'Tekrar alırım — etkisi harikaydı'),
    FinishedProduct(name: 'Old Retinol', brand: 'Olay', imageUrl: 'https://images.unsplash.com/photo-1608248543803-ba4f8c70ae0b?w=200', category: 'Krem', wouldRebuy: false, note: 'Tekrar almam — cildimi tahriş etti'),
  ];

  List<MyProduct> get usingList => myProducts.where((p) => p.status == 'Kullanımda' || p.status == 'Bitmek Üzere').toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: SafeArea(
          child: Column(children: [
            _header(),
            Expanded(child: ListView(padding: const EdgeInsets.only(top: 10), children: [
              if (activeTab == 'all') _statsRow(),
              _content(),
            ])),
          ]),
        ),
      ),
    );
  }

  Widget _header() => Container(
    color: Colors.white.withOpacity(0.95),
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Koleksiyonlarım', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.textDark)),
      const SizedBox(height: 4),
      Text('${_currentLength()} ürün', style: const TextStyle(fontSize: 10, color: AppColors.textGrey)),
      const SizedBox(height: 10),
      TextField(onChanged: (v) => setState(() => query = v.toLowerCase()),
        decoration: const InputDecoration(hintText: 'Ürün ara...', prefixIcon: Icon(Icons.search, color: AppColors.textLight))),
      const SizedBox(height: 10),
      SizedBox(height: 32, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final active = activeTab == tabs[i]['id'];
          return GestureDetector(onTap: () => setState(() => activeTab = tabs[i]['id'] as String),
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
              decoration: BoxDecoration(gradient: active ? AppGradients.primary : null, color: active ? null : Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(tabs[i]['icon'] as IconData, size: 13, color: active ? Colors.white : AppColors.textGrey),
                const SizedBox(width: 5),
                Text(tabs[i]['label'] as String, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: active ? Colors.white : AppColors.textGrey)),
              ])));
        })),
    ]),
  );

  int _currentLength() {
    switch (activeTab) {
      case 'using': return usingList.length;
      case 'wishlist': return wishlist.length;
      case 'finished': return finished.length;
      default: return myProducts.length;
    }
  }

  Widget _statsRow() {
    final warn = myProducts.where((p) => p.remaining < 20).length;
    final fav = myProducts.where((p) => p.isFavorite).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Row(children: [
        Expanded(child: _miniStat(Icons.inventory_2_outlined, AppColors.primary, '${myProducts.length}', 'Toplam')),
        const SizedBox(width: 8),
        Expanded(child: _miniStat(Icons.error_outline, AppColors.accent, '$warn', 'Bitmek Üzere')),
        const SizedBox(width: 8),
        Expanded(child: _miniStat(Icons.favorite_border, AppColors.primary, '$fav', 'Favori')),
      ]),
    );
  }

  Widget _miniStat(IconData icon, Color color, String value, String label) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 16), const SizedBox(height: 3),
      Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: AppColors.textDark)),
      Text(label, style: const TextStyle(fontSize: 8.5, color: AppColors.textGrey)),
    ]),
  );

  Widget _content() {
  if (activeTab == 'wishlist') {return Column(
    children: wishlist.map((it) => _wishlistCard(context, it)).toList(),
  );
}
    if (activeTab == 'finished') return Column(children: [...finished.map(_finishedCard), _shareBanner()]);
    final list = activeTab == 'using' ? usingList : myProducts;
    return Column(children: list.map(_productCard).toList());
  }

  Widget _productCard(MyProduct it) => Container(
    margin: const EdgeInsets.fromLTRB(14, 0, 14, 12), padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network(it.imageUrl, width: 60, height: 60, fit: BoxFit.cover)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(it.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark))),
            if (it.isFavorite) const Icon(Icons.favorite, size: 13, color: AppColors.accent),
          ]),
          OutlinedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(context,
                MaterialPageRoute(builder: (_) => WriteReviewScreen(product: it)));
              if (result == true) setState(() {});
            },
            icon: const Icon(Icons.chat_bubble_outline, size: 13, color: AppColors.primary),
            label: const Text('Yorum Yaz', style: TextStyle(fontSize: 11, color: AppColors.primary)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.softGreen, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
          Text(it.brand, style: const TextStyle(fontSize: 10, color: AppColors.primary)),
          const SizedBox(height: 5),
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: it.status == 'Bitmek Üzere' ? const Color(0xFFFFEEE8) : AppColors.lightGreen, borderRadius: BorderRadius.circular(20)),
              child: Text(it.status, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: it.status == 'Bitmek Üzere' ? AppColors.accent : AppColors.primary))),
            const SizedBox(width: 5),
            Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(20)),
              child: Text(it.category, style: const TextStyle(fontSize: 9, color: AppColors.textGrey))),
          ]),
        ])),
        GestureDetector(
  onTap: () {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: AppColors.softGreen, borderRadius: BorderRadius.circular(2))),
          ListTile(
            leading: const Icon(Icons.edit_outlined, color: AppColors.primary),
            title: const Text('Düzenle'),
            onTap: () async {
              Navigator.pop(context);
              final updated = await Navigator.push(context,
                MaterialPageRoute(builder: (_) => EditProductScreen(product: it)));
              if (updated == true) setState(() {});
            },
          ),
          ListTile(
            leading: const Icon(Icons.check_circle_outline, color: AppColors.accent),
            title: const Text('Ürünü Bitir'),
            onTap: () async {
              Navigator.pop(context);
              final result = await Navigator.push(context,
                MaterialPageRoute(builder: (_) => FinishProductScreen(product: it)));
              if (result == 'finished') setState(() {});
            },
          ),
        ]),
      ),
    );
  },
  child: const Icon(Icons.more_vert, color: AppColors.textLight, size: 16),
),
      ]),
      const SizedBox(height: 10),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Kalan miktar', style: TextStyle(fontSize: 10, color: AppColors.textGrey)),
        Text('%${it.remaining}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.textDark)),
      ]),
      const SizedBox(height: 3),
      ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: it.remaining / 100, minHeight: 6, backgroundColor: AppColors.softGreen,
        valueColor: AlwaysStoppedAnimation(it.remaining < 20 ? AppColors.accent : AppColors.primary))),
      const SizedBox(height: 10),
      GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), childAspectRatio: 4, mainAxisSpacing: 6, crossAxisSpacing: 6, children: [
        _detailItem(Icons.calendar_today_outlined, 'Açılış', it.openDate),
        _detailItem(Icons.event_busy_outlined, 'Son kullanma', it.expiryDate),
        _detailItem(Icons.inventory_2_outlined, 'Miktar', it.amount),
        _detailItem(Icons.access_time, 'Kullanım', it.usage),
      ]),
      const SizedBox(height: 6),
      Row(children: List.generate(5, (i) => Icon(Icons.star, size: 14, color: i < it.rating ? AppColors.peach : AppColors.softGreen))),
      if (it.note.isNotEmpty) ...[
        const SizedBox(height: 8),
        Container(width: double.infinity, padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(12)),
          child: Text(it.note, style: const TextStyle(fontSize: 10.5, color: AppColors.textDark))),
      ],
      const SizedBox(height: 10),
      Row(children: [
      Expanded(child: OutlinedButton.icon(
        onPressed: () async {              // ← burası değişti
          final updated = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditProductScreen(product: it),
            ),
          );
          if (updated == true) setState(() {});
        },
    icon: const Icon(Icons.edit_outlined, size: 13, color: AppColors.textDark),
    label: const Text('Düzenle', style: TextStyle(fontSize: 11, color: AppColors.textDark)),
    style: OutlinedButton.styleFrom(
    side: const BorderSide(color: AppColors.softGreen, width: 2),
    padding: const EdgeInsets.symmetric(vertical: 9),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
        const SizedBox(width: 8),
        Expanded(child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppGradients.primary,
            borderRadius: BorderRadius.circular(12)),
          child: ElevatedButton(
            onPressed: () => _showAddToRoutineModal(context, it),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 9)),
            child: const Text('Rutine Ekle',
              style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500)),
          ),
        )),
      ]),
    ]),
  );

  Widget _detailItem(IconData icon, String label, String value) => Row(children: [
    Icon(icon, size: 13, color: AppColors.textLight), const SizedBox(width: 5),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 8.5, color: AppColors.textGrey)),
      Text(value, style: const TextStyle(fontSize: 10.5, color: AppColors.textDark, fontWeight: FontWeight.w500)),
    ])),
  ]);

// 1. DÜZELTME: BuildContext context parametresi eklendi
  Widget _wishlistCard(BuildContext context, WishlistProduct it) => Container(
    margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white, 
      borderRadius: BorderRadius.circular(20), 
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14), 
          child: Image.network(
            it.imageUrl, 
            width: 60, 
            height: 60, 
            fit: BoxFit.cover,
            // 2. DÜZELTME: Hatalı link/görsel çökmesini engellemek için errorBuilder eklendi
            errorBuilder: (context, error, stackTrace) => Container(
              width: 60, height: 60, color: AppColors.cream,
              child: const Icon(Icons.image_not_supported, color: AppColors.textLight, size: 20),
            ),
          )
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(it.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textDark))), 
            const Icon(Icons.favorite, size: 14, color: AppColors.accent)
          ]),
          Text(it.brand, style: const TextStyle(fontSize: 11, color: AppColors.primary)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), 
            decoration: BoxDecoration(color: AppColors.lightGreen, borderRadius: BorderRadius.circular(20)),
            child: Text(it.category, style: const TextStyle(fontSize: 9, color: AppColors.primary))
          ),
        ])),
      ]),
      const SizedBox(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('₺${it.price}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textDark)),
        DecoratedBox(
          decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(12)),
          child: ElevatedButton.icon(
            onPressed: () {
              // Önce MyProduct'a çevir
              final myProduct = MyProduct(
                name: it.name, 
                brand: it.brand, 
                imageUrl: it.imageUrl,
                category: it.category, 
                status: 'Kullanımda', 
                remaining: 100,
                openDate: '', 
                expiryDate: '', 
                amount: '', 
                usage: '', 
                rating: 0, 
                note: '',
              );
              // 1. DÜZELTME İLE ÇÖZÜLEN KISIM: Artık parametre olan context kullanılıyor
              _showAddToRoutineModal(context, myProduct);
            },
            icon: const Icon(Icons.add, size: 14, color: Colors.white),
            label: const Text('Rutine Ekle', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent, 
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9)
            ),
          ),
        ),
      ]),
    ]),
  );

  Widget _finishedCard(FinishedProduct it) => Container(
  margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
  padding: const EdgeInsets.all(14),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
  ),
  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    // Ürün bilgisi
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(it.imageUrl, width: 60, height: 60, fit: BoxFit.cover),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(it.name,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textDark)),
        Text(it.brand,
          style: const TextStyle(fontSize: 11, color: AppColors.primary)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: it.wouldRebuy ? AppColors.lightGreen : const Color(0xFFFFEEE8),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            it.wouldRebuy ? '✓ Tekrar Alırım' : '✗ Tekrar Almam',
            style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w500,
              color: it.wouldRebuy ? AppColors.primary : AppColors.accent,
            ),
          ),
        ),
      ])),
    ]),
    const SizedBox(height: 10),

    // Not kutusu
    Container(
      width: double.infinity,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(12)),
      child: Text(it.note, style: const TextStyle(fontSize: 10.5, color: AppColors.textDark)),
    ),
    const SizedBox(height: 10),

    // Butonlar satırı
    Row(children: [
      // Yorum Yaz
      Expanded(child: OutlinedButton.icon(
        onPressed: () async {
          final product = MyProduct(
            name: it.name,
            brand: it.brand,
            imageUrl: it.imageUrl,
            category: it.category,
            status: 'Bitti',
            remaining: 0,
            openDate: '',
            expiryDate: '',
            amount: '',
            usage: '',
            rating: 0,
            note: it.note,
          );
          final result = await Navigator.push(context,
            MaterialPageRoute(builder: (_) => WriteReviewScreen(product: product)));
          if (result == true && mounted) setState(() {});
        },
        icon: const Icon(Icons.chat_bubble_outline, size: 13, color: AppColors.primary),
        label: const Text('Yorum Yaz',
          style: TextStyle(fontSize: 11, color: AppColors.primary)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.softGreen, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      )),
      const SizedBox(width: 8),

      // Tekrar Kullan
      Expanded(child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppGradients.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ElevatedButton.icon(
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => AddProductModal(
              productName: it.name,
              productBrand: it.brand,
            ),
          ),
          icon: const Icon(Icons.refresh, color: Colors.white, size: 13),
          label: const Text('Tekrar Kullan',
            style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      )),
    ]),
  ]),
);

  Widget _shareBanner() => GestureDetector(
    onTap: () => Navigator.push(context,
      MaterialPageRoute(builder: (_) => const ShareFinishedScreen())),
    child: Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.lightGreen, borderRadius: BorderRadius.circular(16)),
      child: const Row(children: [
        Icon(Icons.share_outlined, color: AppColors.primary, size: 17),
        SizedBox(width: 8),
        Expanded(child: Text('Bitirdiklerimi arkadaşlarımla paylaş',
          style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500))),
        Icon(Icons.chevron_right, color: AppColors.primary, size: 16),
      ]),
    ),
  );
}