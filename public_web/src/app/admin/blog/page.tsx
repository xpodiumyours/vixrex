import { createClient } from '@/lib/supabase/server';
import Link from 'next/link';

export default async function AdminBlog() {
  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  const { data: store } = await supabase
    .from('stores')
    .select('id, slug')
    .eq('user_id', user?.id)
    .single();

  if (!store) {
    return (
      <div className="text-center py-12">
        <p className="text-[#8899AA]">Mağaza bulunamadı.</p>
      </div>
    );
  }

  const { data: articles } = await supabase
    .from('store_articles')
    .select('*')
    .eq('store_id', store.id)
    .order('created_at', { ascending: false });

  return (
    <div className="max-w-6xl mx-auto">
      <div className="flex items-center justify-between mb-8">
        <h1 className="text-2xl font-bold text-white">Blog Yönetimi</h1>
        <span className="text-[#8899AA] text-sm">
          {articles?.length || 0} yazı
        </span>
      </div>

      {articles && articles.length > 0 ? (
        <div className="space-y-3">
          {articles.map((article: { id: string; title: string; created_at: string; status: string }) => (
            <div
              key={article.id}
              className="bg-[#0E1B2E] rounded-xl border border-[#25415F] p-4 flex items-center gap-4"
            >
              <div className="flex-1 min-w-0">
                <h3 className="text-white font-medium truncate">{article.title}</h3>
                <p className="text-[#8899AA] text-sm">
                  {new Date(article.created_at).toLocaleDateString('tr-TR')}
                </p>
              </div>
              <span
                className={`px-3 py-1 rounded-full text-xs font-medium ${
                  article.status === 'published'
                    ? 'bg-green-500/20 text-green-400'
                    : article.status === 'review'
                    ? 'bg-yellow-500/20 text-yellow-400'
                    : 'bg-[#5A6B7D]/20 text-[#8899AA]'
                }`}
              >
                {article.status === 'published'
                  ? 'Yayında'
                  : article.status === 'review'
                  ? 'İncelemede'
                  : 'Taslak'}
              </span>
            </div>
          ))}
        </div>
      ) : (
        <div className="text-center py-12 bg-[#0E1B2E] rounded-xl border border-[#25415F]">
          <svg className="w-12 h-12 mx-auto text-[#5A6B7D] mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 20H5a2 2 0 01-2-2V6a2 2 0 012-2h10a2 2 0 012 2v1m2 13a2 2 0 01-2-2V7m2 13a2 2 0 002-2V9a2 2 0 00-2-2h-2m-4-3H9M7 16h6M7 8h6v4H7V8z" />
          </svg>
          <p className="text-[#8899AA]">Henüz yazı yazılmamış.</p>
          <p className="text-[#5A6B7D] text-sm mt-2">
            Blog yazıları için Flutter uygulamasını kullanın.
          </p>
        </div>
      )}
    </div>
  );
}
