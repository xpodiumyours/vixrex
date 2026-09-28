export interface BlogSeoInput {
  title: string;
  summary: string;
  content: string;
  topic: string;
  city: string;
  hasCover: boolean;
}

export interface BlogSeoResult {
  score: number;
  recommendations: string[];
}

export const BLOG_YAYIN_ESIGI = 60;
export const BLOG_BASLIK_EN_AZ = 30;
export const BLOG_BASLIK_EN_FAZLA = 60;
export const BLOG_OZET_EN_AZ = 80;
export const BLOG_OZET_EN_FAZLA = 160;
export const BLOG_EN_AZ_KELIME = 300;

export function blogKelimeSayisi(metin: string): number {
  const temiz = metin.trim();
  return temiz ? temiz.split(/\s+/).length : 0;
}

/**
 * Yayın için yapısal asgari: başlık/özet aralığı ve en az 300 kelime.
 * Kalan ölçütler (kapak, hedef kelime, hedef şehir) puanı yükseltir ama
 * yayını engellemez — bunlar sıralama iyileştirmesi, yazının var olması
 * değil.
 */
export function blogYayinEngelleri(input: BlogSeoInput): string[] {
  const engeller: string[] = [];
  const title = input.title.trim();
  const summary = input.summary.trim();
  const kelime = blogKelimeSayisi(input.content);

  if (!title) {
    engeller.push("Başlık zorunludur.");
  } else if (title.length < BLOG_BASLIK_EN_AZ || title.length > BLOG_BASLIK_EN_FAZLA) {
    engeller.push(
      `Başlık ${BLOG_BASLIK_EN_AZ}-${BLOG_BASLIK_EN_FAZLA} karakter olmalı (şu an ${title.length}).`
    );
  }

  if (!summary) {
    engeller.push("Özet (meta açıklaması) zorunludur.");
  } else if (summary.length < BLOG_OZET_EN_AZ || summary.length > BLOG_OZET_EN_FAZLA) {
    engeller.push(
      `Özet ${BLOG_OZET_EN_AZ}-${BLOG_OZET_EN_FAZLA} karakter olmalı (şu an ${summary.length}).`
    );
  }

  if (kelime < BLOG_EN_AZ_KELIME) {
    engeller.push(
      `İçerik en az ${BLOG_EN_AZ_KELIME} kelime olmalı (şu an ${kelime}).`
    );
  }

  return engeller;
}

/** Flutter SeoAnalysisService ile aynı blog ölçütlerini uygular. */
export function blogSeoAnalizi(input: BlogSeoInput): BlogSeoResult {
  let score = 0;
  const recommendations: string[] = [];
  const title = input.title.trim();
  const summary = input.summary.trim();
  const content = input.content.trim();
  const topic = input.topic.trim().toLocaleLowerCase("tr-TR");
  const city = input.city.trim().toLocaleLowerCase("tr-TR");

  if (!title) {
    recommendations.push("Başlık ekleyin (Tavsiye: 30-60 karakter)");
  } else if (title.length < 30 || title.length > 60) {
    score += 10;
    recommendations.push("Başlığı 30-60 karakter aralığına getirin.");
  } else {
    score += 20;
  }

  if (!summary) {
    recommendations.push("Kısa özet yazın (Tavsiye: 80-160 karakter)");
  } else if (summary.length < 80 || summary.length > 160) {
    score += 10;
    recommendations.push("Özeti 80-160 karakter aralığına getirin.");
  } else {
    score += 20;
  }

  const wordCount = blogKelimeSayisi(content);
  if (wordCount === 0) {
    recommendations.push("İçerik metni yazın (En az 300 kelime)");
  } else if (wordCount < 150) {
    score += 5;
    recommendations.push(`İçerik çok kısa (${wordCount} kelime).`);
  } else if (wordCount < 300) {
    score += 12;
    recommendations.push(`İçeriği 300 kelimeye tamamlayın (${wordCount} kelime).`);
  } else {
    score += 20;
  }

  if (input.hasCover) {
    score += 15;
  } else {
    recommendations.push("Yazıya bir kapak fotoğrafı ekleyin.");
  }

  const searchText = `${title} ${content}`.toLocaleLowerCase("tr-TR");
  if (!topic) {
    recommendations.push("Hedef anahtar kelime belirleyin.");
  } else if (searchText.includes(topic)) {
    score += 10;
  } else {
    recommendations.push(`Hedef kelimeyi (“${topic}”) başlıkta veya içerikte kullanın.`);
  }

  if (city) {
    if (searchText.includes(city)) {
      score += 10;
    } else {
      recommendations.push(`Hedef şehri (“${city}”) başlıkta veya içerikte kullanın.`);
    }
  }

  return { score, recommendations };
}
