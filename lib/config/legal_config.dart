class LegalConfig {
  const LegalConfig._();

  static const String appName = 'VitrinX';
  static const String ownerName = 'Xpodiumyours';
  static const String companyName = ownerName;
  static const String productOwnershipText = '$appName, $ownerName ürünüdür.';
  static const String privacyEmail = String.fromEnvironment(
    'LEGAL_PRIVACY_EMAIL',
    defaultValue: 'privacy@vitrinx.app',
  );
  static const String publicSiteUrl = String.fromEnvironment(
    'PUBLIC_SITE_URL',
    defaultValue: 'https://vitrinx.app',
  );

  static const String privacyPath = '/privacy';
  static const String termsPath = '/terms';
  static const String dataDeletionPath = '/data-deletion';

  static String get privacyUrl => '$publicSiteUrl$privacyPath';
  static String get termsUrl => '$publicSiteUrl$termsPath';
  static String get dataDeletionUrl => '$publicSiteUrl$dataDeletionPath';
}
