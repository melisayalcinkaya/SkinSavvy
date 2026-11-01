import 'package:flutter_test/flutter_test.dart';
import 'package:skinsavvy_app/core/utils/date_utils.dart';
import 'package:skinsavvy_app/core/utils/text_utils.dart';
import 'package:skinsavvy_app/state/catalog_controller.dart';

void main() {
  group('parseDateInput', () {
    test('geçerli tarihi okur', () {
      expect(parseDateInput('20/01/2026'), DateTime(2026, 1, 20));
    });

    test('takvimde olmayan tarihleri reddeder', () {
      expect(parseDateInput('31/02/2026'), isNull);
      expect(parseDateInput('29/02/2025'), isNull); // artık yıl değil
      expect(parseDateInput('29/02/2028'), DateTime(2028, 2, 29));
    });

    test('biçim dışı girdileri reddeder', () {
      expect(parseDateInput('2026-01-20'), isNull);
      expect(parseDateInput('1/1/2026'), isNull);
      expect(parseDateInput(''), isNull);
    });
  });

  test('addMonths ayın son gününe kırpar', () {
    expect(addMonths(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 28));
    expect(addMonths(DateTime(2026, 11, 15), 3), DateTime(2027, 2, 15));
  });

  test('formatDateShort Türkçe ay kısaltması kullanır', () {
    expect(formatDateShort(DateTime(2026, 8, 3)), '3 Ağu 2026');
    expect(formatDateShort(null), '-');
  });

  test('searchKey Türkçe harf ve büyük/küçük farkını yok sayar', () {
    expect(searchKey('İÇERİK Şampuanı'), searchKey('icerik sampuani'));
    expect(searchKey('IŞIK'), 'isik');
  });

  test('sanitizeInput etiketleri atar ama kesme işaretini korur', () {
    expect(
      sanitizeInput("  <b>Paula's</b> Choice<script>  "),
      "Paula's Choice",
    );
  });

  group('parseIngredients', () {
    test('virgül, noktalı virgül ve satır sonuyla böler', () {
      expect(parseIngredients('Aqua, Glycerin;Niacinamide\nZinc PCA.'), [
        'Aqua',
        'Glycerin',
        'Niacinamide',
        'Zinc PCA',
      ]);
    });

    test('parantez içindeki virgülleri bölmez', () {
      expect(parseIngredients('Parfum (Fragrance, Koku), Aqua'), [
        'Parfum (Fragrance, Koku)',
        'Aqua',
      ]);
    });

    test('boş öğeleri atar', () {
      expect(parseIngredients(' , Aqua,, '), ['Aqua']);
    });
  });
}
