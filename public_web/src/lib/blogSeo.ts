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

  const wordCount = content ? content.split(/\s+/).length : 0;
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
