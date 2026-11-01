import 'dart:async';

import 'catalog_controller.dart';
import 'review_controller.dart';
import 'shelf_controller.dart';

/// Ekibin öneri kararlarını (onay, yinelenen, silme) önerenin dolabına ve
/// yorumlarına yansıtır. Katalog her değiştiğinde çalışır; uygulama
/// kapalıyken verilen kararlar da açılışta işlenir.
class DecisionSync {
  DecisionSync(this.catalog, this.shelf, this.reviews) {
    catalog.addListener(_apply);
    // İlk uygulama build dışında yapılır (sağlayıcı oluşturulurken
    // dinleyicileri uyarmak hata verir).
    scheduleMicrotask(_apply);
  }

  final CatalogController catalog;
  final ShelfController shelf;
  final ReviewController reviews;
  bool _disposed = false;

  void _apply() {
    if (_disposed) return;
    final decided = [
      for (final p in catalog.submissions)
        if (!p.isPending) p,
    ];
    if (decided.isEmpty) return;
    shelf.applyDecisions(decided, catalog.byId);
    reviews.applyDecisions(decided);
  }

  void dispose() {
    _disposed = true;
    catalog.removeListener(_apply);
  }
}
