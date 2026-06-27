abstract final class InstagramSyncConfig {
  static const bool enabled = bool.fromEnvironment(
    'INSTAGRAM_SYNC_ENABLED',
    defaultValue: false,
  );
}
