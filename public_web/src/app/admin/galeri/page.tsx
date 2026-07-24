import { createClient } from '@/lib/supabase/server';
import GalleryManager from './GalleryManager';

export default async function AdminGallery() {
  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  const { data: store } = await supabase
    .from('stores')
    .select('id, gallery_items')
    .eq('user_id', user?.id)
    .single();

  if (!store) {
    return (
      <div className="text-center py-12">
        <p className="text-[#8899AA]">Mağaza bulunamadı.</p>
      </div>
    );
  }

  return (
    <div className="max-w-6xl mx-auto">
      <h1 className="text-2xl font-bold text-white mb-8">Galeri Yönetimi</h1>
      <GalleryManager
        storeId={store.id}
        initialItems={store.gallery_items || []}
      />
    </div>
  );
}
