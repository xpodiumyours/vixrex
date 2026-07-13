class LegalDocumentSection {
  final String title;
  final String body;

  const LegalDocumentSection({required this.title, required this.body});

  factory LegalDocumentSection.fromJson(Map<String, dynamic> json) {
    return LegalDocumentSection(
      title: _normalizeBrandDisplay((json['title'] ?? '').toString().trim()),
      body: _normalizeBrandDisplay((json['body'] ?? '').toString().trim()),
    );
  }
}

class LegalDocument {
  final String type;
  final String version;
  final String title;
  final String subtitle;
  final String contentHash;
  final DateTime? effectiveAt;
  final List<LegalDocumentSection> sections;

  const LegalDocument({
    required this.type,
    required this.version,
    required this.title,
    required this.subtitle,
    required this.contentHash,
    required this.sections,
    this.effectiveAt,
  });

  factory LegalDocument.fromJson(Map<String, dynamic> json) {
    final rawSections = json['sections'];
    final sections =
        rawSections is List
            ? rawSections
                .whereType<Map>()
                .map(
                  (item) => LegalDocumentSection.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .where(
                  (section) =>
                      section.title.isNotEmpty && section.body.isNotEmpty,
                )
                .toList(growable: false)
            : const <LegalDocumentSection>[];

    return LegalDocument(
      type: (json['document_type'] ?? '').toString().trim(),
      version: (json['version'] ?? '').toString().trim(),
      title: _normalizeBrandDisplay((json['title'] ?? '').toString().trim()),
      subtitle: _normalizeBrandDisplay(
        (json['subtitle'] ?? '').toString().trim(),
      ),
      contentHash: (json['content_hash'] ?? '').toString().trim(),
      effectiveAt: DateTime.tryParse((json['effective_at'] ?? '').toString()),
      sections: sections,
    );
  }

  /// Version zorunlu. content_hash DB'de boş gelebilir; sections okuma UI'sı içindir.
  bool get isUsable => type.isNotEmpty && version.isNotEmpty;
}

String _normalizeBrandDisplay(String value) {
  return value.replaceAll('VixRex', 'Vixrex').replaceAll('VitrinX', 'Vixrex');
}

class PublishingLegalDocuments {
  final LegalDocument privacy;
  final LegalDocument terms;
  final LegalDocument consent;

  const PublishingLegalDocuments({
    required this.privacy,
    required this.terms,
    required this.consent,
  });

  bool get isComplete => privacy.isUsable && terms.isUsable && consent.isUsable;
}
