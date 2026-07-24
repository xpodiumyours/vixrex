import { createClient } from '@/lib/supabase/server';
import ProductList from './ProductList';

export default async function AdminProducts() {
  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  // Mağazayı bul
  const { data: store } = await supabase
    .from('stores')
    .select('id')
    .eq('user_id', user?.id)
    .single();

  if (!store) {
    return (
      <div className="text-center py-12">
        <p className="text-[#8899AA]">Mağaza bulunamadı.</p>
      </div>
    );
  }

  // Ürünleri al
  const { data: products } = await supabase
    .from('products')
    .select('*')
    .eq('store_id', store.id)
    .eq('is_active', true)
    .order('sort_order');

  // Kategorileri al
  const { data: categories } = await supabase
    .from('product_categories')
    .select('*')
    .eq('store_id', store.id)
    .eq('is_active', true)
    .order('sort_order');

  return (
    <div className="max-w-6xl mx-auto">
      <div className="flex items-center justify-between mb-8">
        <h1 className="text-2xl font-bold text-white">Ürün Yönetimi</h1>
        <span className="text-[#8899AA] text-sm">
          {products?.length || 0} ürün
        </span>
      </div>

      <ProductList
        products={products || []}
        categories={categories || []}
        storeId={store.id}
      />
    </div>
  );
}
