/// Taslak çakışma çözümü — PR5-C23.
///
/// Farklı alanlar otomatik birleşir, aynı alan çakışması kullanıcıya
/// gösterilir. Sessiz "son yazan kazanır" yok.
class DraftConflictResolver {
  const DraftConflictResolver();

  /// İki yama aynı alan mı?
  bool ayniAlan(String a, String b) => a == b;

  /// Farklı alanlar: otomatik birleştir — her ikisi de korunur.
  Map<String, dynamic> birlestir(Map<String, dynamic> yerel, Map<String, dynamic> uzak) {
    return {...uzak, ...yerel};
  }

  /// Aynı alan çakışması: kullanıcı seçeneği — ezme yok.
  DraftConflict cozumBekliyor({
    required String alan,
    required dynamic yerelDeger,
    required dynamic uzakDeger,
  }) {
    return DraftConflict(alan: alan, yerelDeger: yerelDeger, uzakDeger: uzakDeger);
  }
}

class DraftConflict {
  const DraftConflict({required this.alan, required this.yerelDeger, required this.uzakDeger});
  final String alan;
  final dynamic yerelDeger;
  final dynamic uzakDeger;
}
