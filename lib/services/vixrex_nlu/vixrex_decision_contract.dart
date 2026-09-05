/// Vixrex Akıllı Motor decision/action sözleşmesi.
///
/// Decision katmanı yalnız bu sonucu üretir; persistence yapmaz ve
/// "kaydedildi" başarı semantiği taşımaz.
abstract final class VixrexDecisionKind {
  static const notUnderstood = 'not_understood';
  static const needsClarification = 'needs_clarification';
  static const needsSpecialFlow = 'needs_special_flow';
  static const validatedAction = 'validated_action';
  static const validatedActionGroup = 'validated_action_group';
  static const blocked = 'blocked';
}

class VixrexValidatedAction {
  static const int currentContractVersion = 1;

  final int contractVersion;
  final String domain;
  final String actionType;
  final String fieldKey;
  final Object? normalizedValue;
  final String matchClass;

  const VixrexValidatedAction({
    this.contractVersion = currentContractVersion,
    this.domain = 'storefront',
    this.actionType = 'set_field',
    required this.fieldKey,
    required this.normalizedValue,
    required this.matchClass,
  }) : assert(
         normalizedValue == null ||
             normalizedValue is String ||
             normalizedValue is num ||
             normalizedValue is bool,
         'validated_action normalizedValue desteklenmeyen tipte.',
       );
}
