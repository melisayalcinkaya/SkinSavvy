// ============================================================
// lib/presentation/screens/profile/share_finished_screen.dart
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/shelf_item.dart';
import '../../../state/shelf_controller.dart';
import '../../widgets/app_snack.dart';
import '../../widgets/product_image.dart';

class ShareFinishedScreen extends StatefulWidget {
  const ShareFinishedScreen({super.key});

  @override
  State<ShareFinishedScreen> createState() => _ShareFinishedScreenState();
}

class _ShareFinishedScreenState extends State<ShareFinishedScreen> {
  final Set<String> _selectedIds = {};

  List<ShelfItem> _finished = const [];

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedIds.length == _finished.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.addAll(
          List.generate(_finished.length, (i) => i.toString()),
        );
      }
    });
  }

  String _buildShareText() {
    final selected = _finished
        .asMap()
        .entries
        .where((e) => _selectedIds.contains(e.key.toString()))
        .map((e) => e.value)
        .toList();

    final buffer = StringBuffer();
    buffer.writeln('🌿 SkinSavvy ile cilt bakım listem:');
    buffer.writeln('');

    final rebuy = selected.where((p) => p.wouldRebuy ?? false).toList();
    final notRebuy = selected.where((p) => !(p.wouldRebuy ?? false)).toList();

    if (rebuy.isNotEmpty) {
      buffer.writeln('✅ Tekrar Alacaklarım:');
      for (final p in rebuy) {
        buffer.writeln('• ${p.name} (${p.brand})');
      }
      buffer.writeln('');
    }

    if (notRebuy.isNotEmpty) {
      buffer.writeln('❌ Tekrar Almayacaklarım:');
      for (final p in notRebuy) {
        buffer.writeln('• ${p.name} (${p.brand})');
      }
      buffer.writeln('');
    }

    buffer.writeln('📱 SkinSavvy uygulamasından paylaşıldı.');
    return buffer.toString();
  }

  void _share() {
    if (_selectedIds.isEmpty) {
      _showError('Lütfen paylaşmak istediğiniz ürünleri seçin.');
      return;
    }
    _showShareOptions(_buildShareText());
  }

  void _showShareOptions(String text) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
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
              const Text(
                'Paylaş',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 260),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textDark,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Sistem paylaşım menüsü WhatsApp, Instagram, e-posta gibi yüklü
              // uygulamaları kendisi listeler; web'de tarayıcının paylaşım
              // penceresi, o da yoksa e-posta açılır.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _shareOption('📋', 'Kopyala', () async {
                    await Clipboard.setData(ClipboardData(text: text));
                    if (!sheetContext.mounted) return;
                    Navigator.pop(sheetContext);
                    _showSuccess('Metin panoya kopyalandı!');
                  }),
                  _shareOption('📤', 'Paylaş…', () async {
                    Navigator.pop(sheetContext);
                    await SharePlus.instance.share(
                      ShareParams(
                        text: text,
                        subject: 'SkinSavvy cilt bakım listem',
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shareOption(String emoji, String label, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.cream,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
            ),
          ],
        ),
      );

  void _showError(String msg) => showAppSnack(context, msg, error: true);

  void _showSuccess(String msg) => showAppSnack(context, msg);

  @override
  Widget build(BuildContext context) {
    _finished = context.watch<ShelfController>().finished;
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _finished.isEmpty
                  ? _emptyState()
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _infoCard(),
                        const SizedBox(height: 12),
                        _selectAllRow(),
                        const SizedBox(height: 8),
                        ..._finished.asMap().entries.map(
                          (e) => _productTile(e.key, e.value),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
            ),
            if (_finished.isNotEmpty) _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(4, 10, 16, 10),
    child: Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
        ),
        const Expanded(
          child: Text(
            'Bitirdiklerimi Paylaş',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
          ),
        ),
        const SizedBox(width: 48),
      ],
    ),
  );

  Widget _infoCard() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.lightGreen,
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.share_outlined, color: AppColors.primary, size: 16),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Bitirdiğiniz ürünleri seçip arkadaşlarınızla paylaşabilirsiniz. Paylaşım metni otomatik oluşturulur.',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.primary,
              height: 1.5,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _selectAllRow() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        '${_selectedIds.length}/${_finished.length} seçildi',
        style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
      ),
      GestureDetector(
        onTap: _selectAll,
        child: Text(
          _selectedIds.length == _finished.length
              ? 'Seçimi Kaldır'
              : 'Tümünü Seç',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );

  Widget _productTile(int index, ShelfItem p) {
    final id = index.toString();
    final selected = _selectedIds.contains(id);

    return GestureDetector(
      onTap: () => _toggleSelect(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.lightGreen : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.softGreen,
            width: selected ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
            ),
          ],
        ),
        child: Row(
          children: [
            // Checkbox
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.softGreen,
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 10),
            // Ürün görseli
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: ProductImage(
                p.imageUrl,
                width: 44,
                height: 44,
                radius: 0,
                category: p.category,
              ),
            ),
            const SizedBox(width: 10),
            // Ürün bilgisi
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    p.brand,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    p.note,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textGrey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Tekrar alır mı rozeti
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (p.wouldRebuy ?? false)
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFFFEEE8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                (p.wouldRebuy ?? false) ? '✓' : '✗',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: (p.wouldRebuy ?? false)
                      ? AppColors.primary
                      : AppColors.accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
    child: SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: _selectedIds.isNotEmpty
              ? AppGradients.primary
              : const LinearGradient(
                  colors: [AppColors.softGreen, AppColors.softGreen],
                ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: ElevatedButton(
          onPressed: _selectedIds.isEmpty ? null : _share,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.share_outlined, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                _selectedIds.isEmpty
                    ? 'Ürün Seçin'
                    : '${_selectedIds.length} Ürünü Paylaş',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _emptyState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.lightGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Henüz bitirdiğiniz ürün yok',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Bir ürünü bitirdiğinizde buradan paylaşabilirsiniz.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textGrey,
              height: 1.5,
            ),
          ),
        ],
      ),
    ),
  );
}
