import 'json.dart';

class SkinProfile {
  const SkinProfile({
    this.skinType,
    this.concerns = const {},
    this.allergens = const {},
    this.intensity,
  });

  final String? skinType;
  final Set<String> concerns;
  final Set<String> allergens;
  final String? intensity;

  SkinProfile copyWith({
    String? skinType,
    Set<String>? concerns,
    Set<String>? allergens,
    String? intensity,
  }) => SkinProfile(
    skinType: skinType ?? this.skinType,
    concerns: concerns ?? this.concerns,
    allergens: allergens ?? this.allergens,
    intensity: intensity ?? this.intensity,
  );

  Map<String, dynamic> toJson() => {
    'skinType': skinType,
    'concerns': concerns.toList(),
    'allergens': allergens.toList(),
    'intensity': intensity,
  };

  factory SkinProfile.fromJson(Map<String, dynamic> j) => SkinProfile(
    skinType: asString(j['skinType']),
    concerns: asStringList(j['concerns']).toSet(),
    allergens: asStringList(j['allergens']).toSet(),
    intensity: asString(j['intensity']),
  );
}

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.bio = '',
    this.avatar,
    this.skinProfile = const SkinProfile(),
    this.onboarded = false,
    this.isDemo = false,
  });

  final String id;
  final String name;
  final String email;
  final String bio;

  /// Küçültülmüş profil fotoğrafı (base64 JPEG). Sunucu modunda URL olur.
  final String? avatar;
  final SkinProfile skinProfile;

  /// Karşılama akışı tamamlandı mı? Tamamlanmadıysa yönlendirici oraya götürür.
  final bool onboarded;
  final bool isDemo;

  String get firstName => name.trim().split(RegExp(r'\s+')).first;

  AppUser copyWith({
    String? name,
    String? email,
    String? bio,
    String? avatar,
    bool clearAvatar = false,
    SkinProfile? skinProfile,
    bool? onboarded,
  }) => AppUser(
    id: id,
    name: name ?? this.name,
    email: email ?? this.email,
    bio: bio ?? this.bio,
    avatar: clearAvatar ? null : (avatar ?? this.avatar),
    skinProfile: skinProfile ?? this.skinProfile,
    onboarded: onboarded ?? this.onboarded,
    isDemo: isDemo,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'bio': bio,
    'avatar': avatar,
    'skinProfile': skinProfile.toJson(),
    'onboarded': onboarded,
    'isDemo': isDemo,
  };

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
    id: asString(j['id']) ?? '',
    name: asString(j['name']) ?? '',
    email: asString(j['email']) ?? '',
    bio: asString(j['bio']) ?? '',
    avatar: asString(j['avatar']),
    skinProfile: SkinProfile.fromJson(asMap(j['skinProfile'])),
    onboarded: asBool(j['onboarded']),
    isDemo: asBool(j['isDemo']),
  );
}
