class ArticleEntry {
  final String? id;
  final String? storeSlug;
  final String? title;
  final String? slug;
  final DateTime? createdAt;

  const ArticleEntry({
    this.id,
    this.storeSlug,
    this.title,
    this.slug,
    this.createdAt,
  });

  factory ArticleEntry.fromJson(Map<String, dynamic> json) {
    return ArticleEntry(
      id: json['id']?.toString(),
      storeSlug: (json['store_slug'] ?? json['storeSlug'])?.toString(),
      title: json['title']?.toString(),
      slug: json['slug']?.toString(),
      createdAt: DateTime.tryParse(
        (json['created_at'] ?? json['createdAt'] ?? '').toString(),
      ),
    );
  }
}
