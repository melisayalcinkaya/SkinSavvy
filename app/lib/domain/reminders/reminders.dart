import '../../core/utils/date_utils.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/product.dart';
import '../../data/models/routine.dart';
import '../../data/models/shelf_item.dart';

/// Bir ürünün kullanılabileceği son gün ve bu sınırın nereden geldiği.
///
/// İki sınır vardır: ambalajdaki son kullanma tarihi (SKT) ve açıldıktan
/// sonraki kullanım süresi (PAO, kavanoz simgesindeki "12M"). Hangisi önce
/// dolarsa o geçerlidir; açılmış bir kremin SKT'si 2028 olsa da 12 ay sonra
/// bozulmuş sayılır.
class ExpiryInfo {
  const ExpiryInfo(this.date, {required this.fromPao});

  final DateTime date;

  /// Sınır açılış tarihi + PAO'dan mı geliyor?
  final bool fromPao;

  int daysLeft(DateTime today) =>
      dateOnly(date).difference(dateOnly(today)).inDays;
}

ExpiryInfo? expiryInfo(ShelfItem item) {
  final opened = item.openedOn;
  final pao = item.paoMonths;
  final paoDate = opened != null && pao != null && pao > 0
      ? addMonths(dateOnly(opened), pao)
      : null;
  final skt = item.expiresOn == null ? null : dateOnly(item.expiresOn!);
  if (paoDate == null && skt == null) return null;
  if (paoDate != null && (skt == null || paoDate.isBefore(skt))) {
    return ExpiryInfo(paoDate, fromPao: true);
  }
  return ExpiryInfo(skt!, fromPao: false);
}

enum ReminderKind {
  expired,
  expiresSoon,
  submissionRejected,
  submissionApproved,
  reviewQueue,
  routineDue,
  lowStock,
}

class Reminder {
  const Reminder({
    required this.kind,
    required this.title,
    required this.detail,
    this.shelfItemId,
    this.productId,
    this.slot,
    this.daysLeft,
  });

  final ReminderKind kind;
  final String title;
  final String detail;
  final String? shelfItemId;

  /// Öneri kararlarında katalogdaki ürün.
  final String? productId;
  final RoutineSlot? slot;
  final int? daysLeft;

  /// Kullanıcıyı harekete geçirmesi gereken (rozet sayısına giren) türler.
  bool get urgent =>
      kind == ReminderKind.expired ||
      kind == ReminderKind.expiresSoon ||
      kind == ReminderKind.submissionRejected;

  /// Aynı hatırlatmanın kimliği (liste anahtarı ve testler için).
  String get key =>
      '${kind.name}:${shelfItemId ?? productId ?? slot?.name ?? ''}';
}

/// O günkü bir rutin vaktinin durumu.
typedef SlotProgress = ({RoutineSlot slot, int done, int total});

/// Uygulama içi hatırlatmaları hesaplar. Saklanmaz, her seferinde mevcut
/// verilerden üretilir: kullanıcı ürünü bitirince ya da rutini tamamlayınca
/// hatırlatma kendiliğinden kaybolur.
List<Reminder> buildReminders({
  required List<ShelfItem> items,
  required AppSettings settings,
  required DateTime now,
  List<SlotProgress> routine = const [],
  List<Product> decisions = const [],
  int reviewQueue = 0,
}) {
  final today = dateOnly(now);
  final result = <Reminder>[];

  for (final item in items) {
    if (item.status != ShelfStatus.using) continue;

    if (settings.expiryWarning) {
      final info = expiryInfo(item);
      if (info != null) {
        final left = info.daysLeft(today);
        final source = info.fromPao
            ? 'Açıldıktan sonraki kullanım süresi (${item.paoMonths} ay)'
            : 'Son kullanma tarihi';
        if (left < 0) {
          result.add(
            Reminder(
              kind: ReminderKind.expired,
              title: '${item.name} süresi doldu',
              detail:
                  '$source ${formatDateShort(info.date)} tarihinde doldu. '
                  'Bozulmuş ürün tahriş yapabilir; kullanmayı bırak.',
              shelfItemId: item.id,
              daysLeft: left,
            ),
          );
        } else if (left <= settings.expiryWarningDays) {
          result.add(
            Reminder(
              kind: ReminderKind.expiresSoon,
              title: left == 0
                  ? '${item.name} bugün son gün'
                  : '${item.name}: $left gün kaldı',
              detail: '$source ${formatDateShort(info.date)}.',
              shelfItemId: item.id,
              daysLeft: left,
            ),
          );
        }
      }
    }

    if (settings.lowStock && item.isRunningLow) {
      result.add(
        Reminder(
          kind: ReminderKind.lowStock,
          title: '${item.name} bitmek üzere',
          detail:
              'Yaklaşık %${item.remaining} kaldı. '
              'Yenisini alacaksan istek listene ekleyebilirsin.',
          shelfItemId: item.id,
        ),
      );
    }
  }

  // Önerilen ürünler için ekibin kararı (kullanıcı henüz görmediyse).
  if (settings.productApproval) {
    for (final p in decisions) {
      if (p.isRejected) {
        result.add(
          Reminder(
            kind: ReminderKind.submissionRejected,
            title: '${p.name} onaylanmadı',
            detail: p.rejectReason == null || p.rejectReason!.isEmpty
                ? 'Önerin ekip tarafından onaylanmadı. Düzeltip yeniden gönderebilirsin.'
                : 'Gerekçe: ${p.rejectReason} Düzeltip yeniden gönderebilirsin.',
            productId: p.id,
          ),
        );
      } else if (p.status == ProductStatus.approved) {
        result.add(
          Reminder(
            kind: ReminderKind.submissionApproved,
            title: '${p.name} onaylandı',
            detail:
                'Önerdiğin ürün artık herkesin kataloğunda. Katkın için teşekkürler!',
            productId: p.id,
          ),
        );
      }
    }
  }
  if (reviewQueue > 0) {
    result.add(
      Reminder(
        kind: ReminderKind.reviewQueue,
        title: '$reviewQueue ürün onay bekliyor',
        detail:
            'Kullanıcıların önerdiği ürünleri inceleyip onayla ya da reddet.',
      ),
    );
  }

  final minutes = now.hour * 60 + now.minute;
  for (final p in routine) {
    final morning = p.slot == RoutineSlot.morning;
    final enabled = morning ? settings.morningEnabled : settings.eveningEnabled;
    final time = morning ? settings.morningTime : settings.eveningTime;
    final at = parseTimeOfDay(time);
    if (!enabled || at == null || p.total == 0 || p.done >= p.total) continue;
    if (minutes < at) continue;
    // Sabah rutini öğleden sonra artık hatırlatılmaz.
    if (morning && minutes >= 14 * 60) continue;
    result.add(
      Reminder(
        kind: ReminderKind.routineDue,
        title: morning ? 'Sabah rutini zamanı' : 'Akşam rutini zamanı',
        detail:
            '$time için ayarladığın rutinde ${p.total - p.done} adım bekliyor.',
        slot: p.slot,
      ),
    );
  }

  int rank(Reminder r) => r.kind.index * 10000 + (r.daysLeft ?? 0) + 5000;
  result.sort((a, b) => rank(a).compareTo(rank(b)));
  return result;
}
