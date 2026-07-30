class RentalTrialResult {
  final String storeId;
  final String storeSlug;
  final DateTime trialEndsAt;

  const RentalTrialResult({
    required this.storeId,
    required this.storeSlug,
    required this.trialEndsAt,
  });

  factory RentalTrialResult.fromJson(Map<String, dynamic> json) {
    final rawEndsAt = json['trial_ends_at']?.toString() ?? '';
    final endsAt = DateTime.tryParse(rawEndsAt);
    if (endsAt == null) {
      throw const FormatException('Kiralık vitrin deneme süresi okunamadı.');
    }

    return RentalTrialResult(
      storeId: json['store_id']?.toString() ?? '',
      storeSlug: json['store_slug']?.toString() ?? '',
      trialEndsAt: endsAt,
    );
  }
}
