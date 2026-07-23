class LegalConfig {
  const LegalConfig._();

  static const String appName = 'Vixrex';
  static const String ownerName = String.fromEnvironment(
    'LEGAL_DATA_CONTROLLER_TITLE',
    defaultValue: 'Aksakal Ticaret',
  );
  static const String companyName = ownerName;
  static const String productOwnershipText = '$appName, $ownerName ürünüdür.';
  static const String dataControllerAddress = String.fromEnvironment(
    'LEGAL_DATA_CONTROLLER_ADDRESS',
    defaultValue: 'Ümraniye Esenevler Mahallesi Lokman Hekim Caddesi No 18, İstanbul',
  );
  static const String mersisNumber = String.fromEnvironment(
    'LEGAL_MERSIS_NUMBER',
    defaultValue: '',
  );
  static const String taxNumber = String.fromEnvironment(
    'LEGAL_TAX_NUMBER',
    defaultValue: '0340472476',
  );
  static const String privacyEmail = String.fromEnvironment(
    'LEGAL_PRIVACY_EMAIL',
    defaultValue: 'vixrex.app@gmail.com',
  );
  static const String publicSiteUrl = String.fromEnvironment(
    'PUBLIC_SITE_URL',
    defaultValue: 'https://vixrex-public.vercel.app',
  );

  static const String privacyPath = '/privacy';
  static const String termsPath = '/terms';
  static const String consentPath = '/consent';
  static const String dataDeletionPath = '/data-deletion';

  static String get privacyUrl => '$publicSiteUrl$privacyPath';
  static String get termsUrl => '$publicSiteUrl$termsPath';
  static String get consentUrl => '$publicSiteUrl$consentPath';
  static String get dataDeletionUrl => '$publicSiteUrl$dataDeletionPath';

  static bool get hasCompleteDataControllerIdentity =>
      ownerName.trim().isNotEmpty &&
      dataControllerAddress.trim().isNotEmpty &&
      privacyEmail.trim().isNotEmpty;
}
