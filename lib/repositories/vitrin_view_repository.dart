/// Vitrin görüntülenme sayacı için repository arayüzü.
abstract class VitrinViewRepository {
  /// Bir vitrin görüntülenmesini kaydeder.
  Future<void> recordView({
    required String slug,
    required String source,
  });

  /// Bugünkü görüntülenme sayısını getirir.
  Future<int> fetchTodayViewCount({
    required String slug,
    required String editToken,
  });
}
