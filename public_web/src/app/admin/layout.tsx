import { createClient } from '@/lib/supabase/server';
import AdminSidebar from './AdminSidebar';

export default async function AdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  // Middleware zaten auth kontrolünü yapıyor.
  // Layout'da tekrar redirect yapmıyoruz (login sayfasında sonsuz döngü olur).

  let user = null;
  let store = null;

  try {
    const supabase = await createClient();
    const { data: { user: authUser } } = await supabase.auth.getUser();
    user = authUser;

    if (user) {
      const { data: storeData } = await supabase
        .from('stores')
        .select('id, name, slug, logo_url')
        .eq('user_id', user.id)
        .single();
      store = storeData;
    }
  } catch {
    // Supabase bağlantısı başarısız olabilir, devam et
  }

  // Login sayfasında sidebar gösterme
  const isLoginPage = !user;

  if (isLoginPage) {
    return <>{children}</>;
  }

  return (
    <div className="min-h-screen flex bg-[#071322]">
      <AdminSidebar
        storeName={(store as unknown as Record<string, unknown>)?.name as string || 'Mağaza'}
        storeSlug={(store as unknown as Record<string, unknown>)?.slug as string || ''}
        storeLogo={(store as unknown as Record<string, unknown>)?.logo_url as string | null}
        userEmail={(user as unknown as Record<string, unknown>)?.email as string || ''}
      />
      <main className="flex-1 ml-64 p-8">
        {children}
      </main>
    </div>
  );
}
