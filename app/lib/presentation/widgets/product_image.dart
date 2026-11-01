import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/constants/skin_options.dart';
import '../../core/theme/app_theme.dart';

/// Ürün görseli: uygulama içi varlık, base64 (kullanıcının yüklediği) ya da
/// ağ adresi olabilir. Görsel yoksa veya yüklenemezse kategori emojisi
/// gösterilir; bozuk bağlantı ekranı çökertmez.
class ProductImage extends StatelessWidget {
  const ProductImage(
    this.source, {
    super.key,
    this.width,
    this.height,
    this.radius = 14,
    this.category = '',
    this.fit = BoxFit.cover,
  });

  final String source;
  final double? width;
  final double? height;
  final double radius;
  final String category;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    Widget fallback(BuildContext _, Object _, StackTrace? _) => _placeholder();
    final Widget image;
    if (source.startsWith('assets/')) {
      image = Image.asset(
        source,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: fallback,
      );
    } else if (source.startsWith('data:image')) {
      image = Image.memory(
        base64Decode(source.substring(source.indexOf(',') + 1)),
        fit: fit,
        width: width,
        height: height,
        gaplessPlayback: true,
        errorBuilder: fallback,
      );
    } else if (source.startsWith('http')) {
      image = Image.network(
        source,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: fallback,
      );
    } else {
      image = _placeholder();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(width: width, height: height, child: image),
    );
  }

  Widget _placeholder() => LayoutBuilder(
    builder: (context, c) {
      final side = min(
        c.hasBoundedWidth ? c.maxWidth : (width ?? 60),
        c.hasBoundedHeight ? c.maxHeight : (height ?? 60),
      );
      return Container(
        width: width,
        height: height,
        color: AppColors.lightGreen,
        alignment: Alignment.center,
        child: Text(
          categoryEmoji(category),
          style: TextStyle(fontSize: side * 0.4),
        ),
      );
    },
  );
}
