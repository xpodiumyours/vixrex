import { createClient } from '@/lib/supabase/server';
import Link from 'next/link';
import VixRexAssistant from './VixRexAssistant';

export default async function AdminDashboard() {
  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  // Mağaza bilgilerini al
  const { data: store } = await supabase
    .from('stores')
    .select('*')
    .eq('user_id', user?.id)
    .single();

  // Ürün sayısını al
  const { count: productCount } = await supabase
    .from('products')
    .select('*', { count: 'exact', head: true })
    .eq('store_id', store?.id)
    .eq('is_active', true);

  // Galeri sayısını al
  const galleryCount = store?.gallery_items?.length || 0;

  // Blog sayısını al
  const { count: articleCount } = await supabase
    .from('store_articles')
    .select('*', { count: 'exact', head: true })
    .eq('store_id', store?.id);

  return (
    <div className="max-w-7xl mx-auto">
      <h1 className="text-2xl font-bold text-white mb-8">Genel Bakış</h1>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Main Content */}
        <div className="lg:col-span-2 space-y-6">
      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <StatCard
          label="Ürün Sayısı"
          value={productCount || 0}
          icon={
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4" />
            </svg>
          }
          color="blue"
        />
        <StatCard
          label="Galeri Fotoğrafı"
          value={galleryCount}
          icon={
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
            </svg>
          }
          color="purple"
        />
        <StatCard
          label="Blog Yazısı"
          value={articleCount || 0}
          icon={
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 20H5a2 2 0 01-2-2V6a2 2 0 012-2h10a2 2 0 012 2v1m2 13a2 2 0 01-2-2V7m2 13a2 2 0 002-2V9a2 2 0 00-2-2h-2m-4-3H9M7 16h6M7 8h6v4H7V8z" />
            </svg>
          }
          color="green"
        />
        <StatCard
          label="Durum"
          value={store?.is_published ? 'Yayında' : 'Taslak'}
          icon={
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          }
          color={store?.is_published ? 'green' : 'yellow'}
        />
      </div>

      {/* Quick Actions */}
      <h2 className="text-lg font-semibold text-white mb-4">Hızlı İşlemler</h2>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        <QuickAction
          href="/admin/urunler"
          label="Ürün Yönetimi"
          description="Ürünlerinizi ekleyin, düzenleyin veya silin"
          icon={
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
            </svg>
          }
        />
        <QuickAction
          href="/admin/galeri"
          label="Galeri Yönetimi"
          description="Fotoğraflarınızı yönetin"
          icon={
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
            </svg>
          }
        />
        <QuickAction
          href="/admin/blog"
          label="Blog Yönetimi"
          description="Makalelerinizi yazın ve yayınlayın"
          icon={
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
            </svg>
          }
        />
        <QuickAction
          href={`/v/${store?.slug}`}
          label="Vitrini Görüntüle"
          description="Müşterilerinizin gördüğü vitrini inceleyin"
          icon={
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
            </svg>
          }
          external
        />
        <QuickAction
          href="/admin/ayarlar"
          label="Mağaza Ayarları"
          description="Mağaza bilgilerinizi güncelleyin"
          icon={
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
            </svg>
          }
        />
      </div>
        </div>

        {/* Sidebar - VixRex Assistant */}
        <div className="lg:col-span-1">
          <VixRexAssistant
            storeId={store?.id || ''}
            storeSlug={store?.slug || ''}
          />
        </div>
      </div>
    </div>
  );
}

function StatCard({
  label,
  value,
  icon,
  color,
}: {
  label: string;
  value: number | string;
  icon: React.ReactNode;
  color: 'blue' | 'purple' | 'green' | 'yellow';
}) {
  const colorMap = {
    blue: 'bg-[#38A0E4]/10 text-[#38A0E4]',
    purple: 'bg-purple-500/10 text-purple-400',
    green: 'bg-green-500/10 text-green-400',
    yellow: 'bg-yellow-500/10 text-yellow-400',
  };

  return (
    <div className="bg-[#0E1B2E] rounded-xl p-6 border border-[#25415F]">
      <div className="flex items-center justify-between mb-4">
        <div className={`p-3 rounded-lg ${colorMap[color]}`}>
          {icon}
        </div>
      </div>
      <p className="text-2xl font-bold text-white">{value}</p>
      <p className="text-[#8899AA] text-sm mt-1">{label}</p>
    </div>
  );
}

function QuickAction({
  href,
  label,
  description,
  icon,
  external,
}: {
  href: string;
  label: string;
  description: string;
  icon: React.ReactNode;
  external?: boolean;
}) {
  const content = (
    <div className="bg-[#0E1B2E] rounded-xl p-6 border border-[#25415F] hover:border-[#38A0E4]/50 transition-colors group">
      <div className="flex items-start gap-4">
        <div className="p-3 rounded-lg bg-[#38A0E4]/10 text-[#38A0E4] group-hover:bg-[#38A0E4]/20 transition-colors">
          {icon}
        </div>
        <div className="flex-1">
          <h3 className="text-white font-semibold group-hover:text-[#38A0E4] transition-colors">
            {label}
          </h3>
          <p className="text-[#8899AA] text-sm mt-1">{description}</p>
        </div>
        <svg
          className="w-5 h-5 text-[#5A6B7D] group-hover:text-[#38A0E4] transition-colors"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
        </svg>
      </div>
    </div>
  );

  if (external) {
    return (
      <a href={href} target="_blank" rel="noopener noreferrer">
        {content}
      </a>
    );
  }

  return <Link href={href}>{content}</Link>;
}
