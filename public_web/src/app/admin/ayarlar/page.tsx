import { createClient } from '@/lib/supabase/server';
import StoreSettingsForm from './StoreSettingsForm';

export default async function AdminSettings() {
  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  const { data: store } = await supabase
    .from('stores')
    .select('*')
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
    <div className="max-w-4xl mx-auto">
      <h1 className="text-2xl font-bold text-white mb-8">Mağaza Ayarları</h1>
      <StoreSettingsForm store={store} />
    </div>
  );
}
