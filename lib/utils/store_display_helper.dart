/// Display helpers for store metadata.
class StoreDisplayHelper {
  StoreDisplayHelper._();

  /// Returns one- or two-character initials derived from the store [name].
  ///
  /// Single-word names use the first two characters; multi-word names use the
  /// first character of each of the first two words.  Falls back to `'VX'`
  /// when [name] is blank.
  static String storeInitials(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return 'VX';
    if (words.length == 1) {
      return words.first.runes
          .take(2)
          .map(String.fromCharCode)
          .join()
          .toUpperCase();
    }
    return words
        .take(2)
        .map((w) => String.fromCharCode(w.runes.first))
        .join()
        .toUpperCase();
  }
}
