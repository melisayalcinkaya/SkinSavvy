/// Demo kataloğundaki ürünlere topluluğun yazdığı örnek yorumlar.
///
/// Ürün puanı ve "N değerlendirme" sayısı uydurulmaz; bu yorumlardan (ve
/// kullanıcının kendi yorumundan) hesaplanır. Sunucu da aynı listeyi
/// backend/app/data/demo_reviews.json dosyasından yükler.
class CommunityReview {
  const CommunityReview({
    required this.productId,
    required this.author,
    required this.rating,
    required this.comment,
    required this.date,
  });

  final String productId;
  final String author;
  final int rating;
  final String comment;

  /// ISO tarih ("2026-10-02").
  final String date;

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'author': author,
    'rating': rating,
    'comment': comment,
    'date': date,
  };
}

const demoReviews = <CommunityReview>[
  CommunityReview(
    productId: 'p-temizleyici-lumen',
    author: 'Zeynep K.',
    rating: 5,
    comment: 'Gerginlik bırakmıyor, hassas cildimde kızarıklık yapmadı.',
    date: '2026-07-10',
  ),
  CommunityReview(
    productId: 'p-temizleyici-lumen',
    author: 'Mert Y.',
    rating: 4,
    comment:
        'Makyajı tek başına tam çıkarmıyor, akşam yağ bazlıyla birlikte kullanıyorum.',
    date: '2026-08-02',
  ),
  CommunityReview(
    productId: 'p-serum-c-aurora',
    author: 'Elif S.',
    rating: 4,
    comment:
        'İki ayda lekelerim belirgin açıldı. Kokusu var, hassas ciltler dikkat.',
    date: '2026-08-11',
  ),
  CommunityReview(
    productId: 'p-serum-c-aurora',
    author: 'Deniz A.',
    rating: 3,
    comment:
        'Açtıktan birkaç ay sonra rengi koyulaştı, küçük boy almak daha mantıklı.',
    date: '2026-09-14',
  ),
  CommunityReview(
    productId: 'p-krem-seramid-lumen',
    author: 'Deniz A.',
    rating: 5,
    comment: 'Kışın kuruyan yanaklarım için kurtarıcı oldu, ağır da durmuyor.',
    date: '2026-09-01',
  ),
  CommunityReview(
    productId: 'p-gunes-mineral-solara',
    author: 'Zeynep K.',
    rating: 4,
    comment: 'Beyazlık bırakmıyor ama gün ortasında tazelemek gerekiyor.',
    date: '2026-08-20',
  ),
  CommunityReview(
    productId: 'p-gunes-mineral-solara',
    author: 'Mert Y.',
    rating: 5,
    comment: 'Gözümü yakmayan tek güneş kremi.',
    date: '2026-09-28',
  ),
  CommunityReview(
    productId: 'p-serum-retinol-aurora',
    author: 'Elif S.',
    rating: 4,
    comment:
        'İlk iki hafta hafif soyulma yaptı, haftada üç akşama indirince geçti.',
    date: '2026-09-22',
  ),
  CommunityReview(
    productId: 'p-tonik-bha-clarity',
    author: 'Mert Y.',
    rating: 5,
    comment:
        'Burnumdaki siyah noktalar azaldı. Retinolle aynı akşam kullanmıyorum.',
    date: '2026-10-05',
  ),
  CommunityReview(
    productId: 'p-serum-niacinamide-clarity',
    author: 'Zeynep K.',
    rating: 4,
    comment: 'Yağlanmayı azalttı. Üstüne nemlendirici sürünce topaklanmıyor.',
    date: '2026-10-09',
  ),
  CommunityReview(
    productId: 'p-maske-kil-terra',
    author: 'Deniz A.',
    rating: 2,
    comment: 'Kokusu çok ağır, iki kullanımda kaşıntı yaptı.',
    date: '2026-10-15',
  ),
  CommunityReview(
    productId: 'p-serum-hyaluronik-aurora',
    author: 'Elif S.',
    rating: 5,
    comment: 'Nemli cilde sürünce çok iyi emiliyor, makyaj altı da güzel.',
    date: '2026-10-18',
  ),
];
