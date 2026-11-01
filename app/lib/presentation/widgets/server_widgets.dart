import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/json.dart';
import '../../data/remote/api_client.dart';
import '../../state/catalog_controller.dart';

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

/// Reddedilen önerinin gerekçesi (yalnızca öneren görür).
class RejectedNotice extends StatelessWidget {
  const RejectedNotice({super.key, required this.reason});

  final String? reason;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: const Color(0xFFFFEEE8),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Önerin onaylanmadı',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          reason == null || reason!.isEmpty
              ? 'Yönetici bir gerekçe yazmadı.'
              : 'Gerekçe: $reason',
          style: const TextStyle(fontSize: 12, color: AppColors.textDark),
        ),
        const SizedBox(height: 4),
        const Text(
          'Bilgileri düzeltip ürünü yeniden önerebilirsin.',
          style: TextStyle(fontSize: 11, color: AppColors.textGrey),
        ),
      ],
    ),
  );
}

/// Ürün detayında diğer kullanıcıların yorumları (sunucu modu).
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
    _future ??= api == null ? null : _load(api);
  }

  Future<List<Map<String, dynamic>>> _load(ApiClient api) async {
    final data = await api.get(
      '/products/${Uri.encodeComponent(widget.productId)}/reviews',
      query: {'limit': '20'},
    );
    return [for (final r in data as List) asMap(r)];
  }

  @override
  Widget build(BuildContext context) {
    final future = _future;
    if (future == null) return const SizedBox.shrink();
    return FutureBuilder(
      future: future,
      builder: (context, snap) {
        final items = snap.data ?? const [];
        return Container(
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
              if (snap.connectionState != ConnectionState.done)
                const LinearProgressIndicator(color: AppColors.primary)
              else if (snap.hasError)
                Text(
                  '${snap.error}',
                  style: const TextStyle(fontSize: 11, color: AppColors.accent),
                )
              else if (items.isEmpty)
                const Text(
                  'Henüz yorum yok. İlk yorumu sen yaz.',
                  style: TextStyle(fontSize: 11, color: AppColors.textGrey),
                )
              else
                for (final r in items) _ReviewRow(r),
            ],
          ),
        );
      },
    );
  }
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
              Text(
                asBool(r['mine'])
                    ? 'Sen'
                    : asString(r['author']) ?? 'Kullanıcı',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
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
