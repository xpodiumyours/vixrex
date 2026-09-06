enum VixrexBlogIntent {
  blogYazisiBul,
  blogYazisiOner,
  blogYazisiTaslakEkle,
  blogTaslaklariniListele,
  blogTaslakDuzenle,
  blogYayinla,
}

enum VixrexAssistantDomain { storefront, blog, ambiguous }

class VixrexAssistantDomainDecision {
  final VixrexAssistantDomain domain;
  final VixrexBlogIntent? intent;
  final String query;

  const VixrexAssistantDomainDecision({
    required this.domain,
    this.intent,
    this.query = '',
  });
}

String _normalize(String input) {
  return input
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('ş', 's')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c')
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

bool _hasAny(String text, List<String> tokens) =>
    tokens.any((token) => text.contains(token));

String _queryFrom(String text) {
  const stop = <String>{
    'blog',
    'bloga',
    'blogda',
    'blogdan',
    'bloguna',
    'blogunda',
    'vitrin',
    'vitrinin',
    'vitrine',
    'vitrinime',
    'yazi',
    'yazisi',
    'yazisini',
    'yazilar',
    'yazilarimi',
    'makale',
    'rehber',
    'taslak',
    'taslagi',
    'taslagini',
    'taslaklar',
    'taslaklarimi',
    'ekle',
    'aktar',
    'cek',
    'olustur',
    'bul',
    'ara',
    'goster',
    'listele',
    'oner',
    'duzenle',
    'degistir',
    'yayinla',
    'yayina',
    'al',
    'bana',
    'bir',
  };
  return text
      .split(' ')
      .where((token) => token.length > 1 && !stop.contains(token))
      .join(' ')
      .trim();
}

/// Blog domain yalnız açık içerik komutlarıyla seçilir.
/// "blog başlığını değiştir" gibi 46-alan storefront komutları burada
/// yakalanmaz.
VixrexAssistantDomainDecision routeVixrexAssistantDomain(String input) {
  final text = _normalize(input);
  if (text.isEmpty) {
    return const VixrexAssistantDomainDecision(
      domain: VixrexAssistantDomain.storefront,
    );
  }

  final mentionsBlog = text.contains('blog');
  final mentionsContent = _hasAny(text, ['yazi', 'makale', 'rehber', 'taslak']);
  if (!mentionsBlog || !mentionsContent) {
    return const VixrexAssistantDomainDecision(
      domain: VixrexAssistantDomain.storefront,
    );
  }

  final matches = <VixrexBlogIntent>[];
  if (
      text.contains('taslak') &&
      _hasAny(text, ['listele', 'goster', 'neler', 'hangileri'])) {
    matches.add(VixrexBlogIntent.blogTaslaklariniListele);
  }
  if (_hasAny(text, ['yayinla', 'yayina al'])) {
    matches.add(VixrexBlogIntent.blogYayinla);
  }
  if (
      _hasAny(text, ['duzenle', 'degistir']) &&
      _hasAny(text, ['yazi', 'taslak', 'makale'])) {
    matches.add(VixrexBlogIntent.blogTaslakDuzenle);
  }
  if (
      _hasAny(text, ['ekle', 'aktar', 'cek', 'taslak olustur', 'taslak ekle']) &&
      _hasAny(text, ['yazi', 'makale', 'rehber'])) {
    matches.add(VixrexBlogIntent.blogYazisiTaslakEkle);
  }
  if (text.contains('oner')) {
    matches.add(VixrexBlogIntent.blogYazisiOner);
  }
  if (_hasAny(text, ['bul', 'ara'])) {
    matches.add(VixrexBlogIntent.blogYazisiBul);
  }

  final unique = matches.toSet().toList();
  final query = _queryFrom(text);
  if (unique.length > 1) {
    return VixrexAssistantDomainDecision(
      domain: VixrexAssistantDomain.ambiguous,
      query: query,
    );
  }
  if (unique.length == 1) {
    return VixrexAssistantDomainDecision(
      domain: VixrexAssistantDomain.blog,
      intent: unique.first,
      query: query,
    );
  }
  return const VixrexAssistantDomainDecision(
    domain: VixrexAssistantDomain.storefront,
  );
}

String vixrexBlogIntentWireName(VixrexBlogIntent intent) {
  switch (intent) {
    case VixrexBlogIntent.blogYazisiBul:
      return 'blog_yazisi_bul';
    case VixrexBlogIntent.blogYazisiOner:
      return 'blog_yazisi_oner';
    case VixrexBlogIntent.blogYazisiTaslakEkle:
      return 'blog_yazisi_taslak_ekle';
    case VixrexBlogIntent.blogTaslaklariniListele:
      return 'blog_taslaklarini_listele';
    case VixrexBlogIntent.blogTaslakDuzenle:
      return 'blog_taslak_duzenle';
    case VixrexBlogIntent.blogYayinla:
      return 'blog_yayinla';
  }
}
