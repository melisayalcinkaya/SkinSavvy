const _monthsShort = [
  'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', //
  'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
];

/// Pazartesi = 1 ... Pazar = 7 (DateTime.weekday ile aynı sıra).
const weekdayShort = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
const weekdayLetter = ['Pt', 'S', 'Ç', 'Pe', 'C', 'Ct', 'P'];

String _two(int v) => v.toString().padLeft(2, '0');

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// "20 Oca 2026"
String formatDateShort(DateTime? d) =>
    d == null ? '-' : '${d.day} ${_monthsShort[d.month - 1]} ${d.year}';

/// Form alanları için "20/01/2026".
String formatDateInput(DateTime? d) =>
    d == null ? '' : '${_two(d.day)}/${_two(d.month)}/${d.year}';

/// Kayıt anahtarı olarak "2026-01-20".
String dateKey(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

/// "GG/AA/YYYY" biçimini ayrıştırır; 31 Şubat gibi geçersiz tarihlerde null döner.
DateTime? parseDateInput(String value) {
  final m = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(value.trim());
  if (m == null) return null;
  final day = int.parse(m.group(1)!);
  final month = int.parse(m.group(2)!);
  final year = int.parse(m.group(3)!);
  if (year < 2000 || year > 2100) return null;
  final date = DateTime(year, month, day);
  if (date.year != year || date.month != month || date.day != day) return null;
  return date;
}

/// Ay ekler; 31 Ocak + 1 ay = 28/29 Şubat (ayın son gününe kırpılır).
DateTime addMonths(DateTime d, int months) {
  final total = d.month - 1 + months;
  final year = d.year + (total ~/ 12);
  final month = total % 12 + 1;
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, d.day > lastDay ? lastDay : d.day);
}

/// "HH:mm" → dakika; geçersizse null.
int? parseTimeOfDay(String value) {
  final m = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$').firstMatch(value);
  if (m == null) return null;
  return int.parse(m.group(1)!) * 60 + int.parse(m.group(2)!);
}

String formatMinutes(int minutes) =>
    '${_two(minutes ~/ 60)}:${_two(minutes % 60)}';
