import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/json.dart';
import '../../data/remote/api_client.dart';
import '../../state/catalog_controller.dart';
import '../../data/demo/demo_reviews.dart';
import '../../state/review_controller.dart';

/// Sunucu modunda katalog yüklenirken ya da yüklenemediğinde gösterilir.
class CatalogStatusBanner extends StatelessWidget {
  const CatalogStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogController>();
    if (!catalog.isRemote) return const SizedBox.shrink();
    if (catalog.isLoading && catalog.products.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 12),
            Text(
              'Katalog yükleniyor…',
              style: TextStyle(fontSize: 12, color: AppColors.textGrey),
            ),
          ],
        ),
      );
    }
    final error = catalog.loadError;
    if (error == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEE8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined, color: AppColors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(fontSize: 12, color: AppColors.textDark),
            ),
          ),
          TextButton(
            onPressed: catalog.isLoading ? null : catalog.reload,
            child: const Text('Tekrar dene'),
          ),
        ],
      ),
    );
  }
}

/// Ürün detayında kullanıcı yorumları.
///
/// Sunucu modunda API'den, cihaz modunda topluluk yorumlarından
/// ([demoReviews]) gelir; kullanıcının kendi yorumu "Sen" olarak en üstte.
class CommunityReviews extends StatefulWidget {
  const CommunityReviews({super.key, required this.productId});

  final String productId;

  @override
  State<CommunityReviews> createState() => _CommunityReviewsState();
}

class _CommunityReviewsState extends State<CommunityReviews> {
  Future<List<Map<String, dynamic>>>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final api = context.read<ApiClient?>();
    if (api != null) _future ??= _load(api);
  }

  Future<List<Map<String, dynamic>>> _load(ApiClient api) async {
    final data = await api.get(
      '/products/${Uri.encodeComponent(widget.productId)}/reviews',
      query: {'limit': '20'},
    );
    return [for (final r in data as List) asMap(r)];
  }

  /// Cihaz modu: kendi yorumun + topluluk yorumları (yeniden eskiye).
  List<Map<String, dynamic>> _local(BuildContext context) {
    final mine = context.watch<ReviewController>().forProduct(widget.productId);
    final community = context.read<CatalogController>().communityReviews(
      widget.productId,
    )..sort((a, b) => b.date.compareTo(a.date));
    return [
      if (mine != null)
        {
          'mine': true,
          'rating': mine.rating,
          'comment': mine.comment,
          'createdAt': (mine.updatedAt ?? mine.createdAt).toIso8601String(),
        },
      for (final r in community)
        {
          'author': r.author,
          'rating': r.rating,
          'comment': r.comment,
          'createdAt': r.date,
        },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final future = _future;
    if (future == null) return _box(items: _local(context));
    return FutureBuilder(
      future: future,
      builder: (context, snap) => _box(
        items: snap.data ?? const [],
        loading: snap.connectionState != ConnectionState.done,
        error: snap.hasError ? '${snap.error}' : null,
      ),
    );
  }

  Widget _box({
    required List<Map<String, dynamic>> items,
    bool loading = false,
    String? error,
  }) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(top: 10),
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kullanıcı yorumları',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 6),
        if (loading)
          const LinearProgressIndicator(color: AppColors.primary)
        else if (error != null)
          Text(
            error,
            style: const TextStyle(fontSize: 11, color: AppColors.accent),
          )
        else if (items.isEmpty)
          const Text(
            'Henüz yorum yok. Ürünü dolabına ekleyip ilk yorumu sen yaz.',
            style: TextStyle(fontSize: 11, color: AppColors.textGrey),
          )
        else
          for (final r in items) _ReviewRow(r),
      ],
    ),
  );
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow(this.r);

  final Map<String, dynamic> r;

  @override
  Widget build(BuildContext context) {
    final rating = asInt(r['rating']).clamp(0, 5);
    final created = DateTime.tryParse(asString(r['createdAt']) ?? '');
    final comment = asString(r['comment']) ?? '';
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  asBool(r['mine'])
                      ? 'Sen'
                      : asString(r['author']) ?? 'Kullanıcı',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              for (var i = 0; i < 5; i++)
                Icon(
                  Icons.star,
                  size: 12,
                  color: i < rating ? AppColors.peach : AppColors.softGreen,
                ),
              const Spacer(),
              Text(
                formatDateShort(created?.toLocal()),
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              comment,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textGrey,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
