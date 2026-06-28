class LegalDocumentSection {
  final String title;
  final String body;

  const LegalDocumentSection({required this.title, required this.body});

  factory LegalDocumentSection.fromJson(Map<String, dynamic> json) {
    return LegalDocumentSection(
      title: (json['title'] ?? '').toString().trim(),
      body: (json['body'] ?? '').toString().trim(),
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
      title: (json['title'] ?? '').toString().trim(),
      subtitle: (json['subtitle'] ?? '').toString().trim(),
      contentHash: (json['content_hash'] ?? '').toString().trim(),
      effectiveAt: DateTime.tryParse((json['effective_at'] ?? '').toString()),
      sections: sections,
    );
  }

  bool get isUsable =>
      type.isNotEmpty &&
      version.isNotEmpty &&
      contentHash.isNotEmpty &&
      sections.isNotEmpty;
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
