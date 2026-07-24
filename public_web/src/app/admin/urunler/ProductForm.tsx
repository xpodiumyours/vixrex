'use client';

import { useState } from 'react';
import { createClient } from '@/lib/supabase/client';

interface Product {
  id: string;
  name: string;
  slug: string;
  description: string | null;
  price_amount: number | null;
  price_text: string | null;
  image_urls: string[];
  stock_status: string | null;
  is_visible: boolean;
  category_id: string | null;
}

interface Category {
  id: string;
  name: string;
}

interface ProductFormProps {
  product: Product | null;
  categories: Category[];
  storeId: string;
  onSave: (product: Product) => void;
  onCancel: () => void;
}

export default function ProductForm({
  product,
  categories,
  storeId,
  onSave,
  onCancel,
}: ProductFormProps) {
  const [name, setName] = useState(product?.name || '');
  const [description, setDescription] = useState(product?.description || '');
  const [price, setPrice] = useState(product?.price_amount?.toString() || '');
  const [priceText, setPriceText] = useState(product?.price_text || '');
  const [categoryId, setCategoryId] = useState(product?.category_id || '');
  const [stockStatus, setStockStatus] = useState(product?.stock_status || 'Mevcut');
  const [imageUrl, setImageUrl] = useState(product?.image_urls?.[0] || '');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const supabase = createClient();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    // Slug üret
    const slug = name
      .toLowerCase()
      .replace(/[^a-z0-9\s-]/g, '')
      .replace(/\s+/g, '-')
      .replace(/-+/g, '-')
      .trim();

    const productData = {
      store_id: storeId,
      name,
      slug,
      description: description || null,
      price_amount: price ? parseFloat(price) : null,
      price_text: priceText || null,
      image_urls: imageUrl ? [imageUrl] : [],
      category_id: categoryId || null,
      stock_status: stockStatus,
      is_visible: true,
      is_active: true,
      source_type: 'manual',
      sort_order: 0,
    };

    let result;

    if (product) {
      // Güncelle
      result = await supabase
        .from('products')
        .update({
          name: productData.name,
          slug: productData.slug,
          description: productData.description,
          price_amount: productData.price_amount,
          price_text: productData.price_text,
          image_urls: productData.image_urls,
          category_id: productData.category_id,
          stock_status: productData.stock_status,
        })
        .eq('id', product.id)
        .select()
        .single();
    } else {
      // Yeni ekle
      result = await supabase
        .from('products')
        .insert(productData)
        .select()
        .single();
    }

    if (result.error) {
      setError(result.error.message);
      setLoading(false);
      return;
    }

    onSave(result.data as Product);
  };

  return (
    <div className="bg-[#0E1B2E] rounded-xl border border-[#25415F] p-6">
      <h2 className="text-xl font-semibold text-white mb-6">
        {product ? 'Ürün Düzenle' : 'Yeni Ürün Ekle'}
      </h2>

      {error && (
        <div className="mb-4 p-3 bg-red-500/10 border border-red-500/30 rounded-lg text-red-400 text-sm">
          {error}
        </div>
      )}

      <form onSubmit={handleSubmit} className="space-y-4">
        {/* Product Name */}
        <div>
          <label className="block text-sm font-medium text-[#8899AA] mb-2">
            Ürün Adı *
          </label>
          <input
            type="text"
            value={name}
            onChange={(e) => setName(e.target.value)}
            className="w-full px-4 py-3 bg-[#071322] border border-[#25415F] rounded-lg text-white placeholder-[#5A6B7D] focus:outline-none focus:border-[#38A0E4] transition-colors"
            placeholder="Ürün adını girin"
            required
          />
        </div>

        {/* Description */}
        <div>
          <label className="block text-sm font-medium text-[#8899AA] mb-2">
            Açıklama
          </label>
          <textarea
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            rows={3}
            className="w-full px-4 py-3 bg-[#071322] border border-[#25415F] rounded-lg text-white placeholder-[#5A6B7D] focus:outline-none focus:border-[#38A0E4] transition-colors resize-none"
            placeholder="Ürün açıklaması"
          />
        </div>

        {/* Price */}
        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-[#8899AA] mb-2">
              Fiyat (₺)
            </label>
            <input
              type="number"
              step="0.01"
              value={price}
              onChange={(e) => setPrice(e.target.value)}
              className="w-full px-4 py-3 bg-[#071322] border border-[#25415F] rounded-lg text-white placeholder-[#5A6B7D] focus:outline-none focus:border-[#38A0E4] transition-colors"
              placeholder="0.00"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-[#8899AA] mb-2">
              Fiyat Metni
            </label>
            <input
              type="text"
              value={priceText}
              onChange={(e) => setPriceText(e.target.value)}
              className="w-full px-4 py-3 bg-[#071322] border border-[#25415F] rounded-lg text-white placeholder-[#5A6B7D] focus:outline-none focus:border-[#38A0E4] transition-colors"
              placeholder="Ör: 99.90"
            />
          </div>
        </div>

        {/* Category */}
        <div>
          <label className="block text-sm font-medium text-[#8899AA] mb-2">
            Kategori
          </label>
          <select
            value={categoryId}
            onChange={(e) => setCategoryId(e.target.value)}
            className="w-full px-4 py-3 bg-[#071322] border border-[#25415F] rounded-lg text-white focus:outline-none focus:border-[#38A0E4] transition-colors"
          >
            <option value="">Kategori seçin</option>
            {categories.map((cat) => (
              <option key={cat.id} value={cat.id}>
                {cat.name}
              </option>
            ))}
          </select>
        </div>

        {/* Stock Status */}
        <div>
          <label className="block text-sm font-medium text-[#8899AA] mb-2">
            Stok Durumu
          </label>
          <select
            value={stockStatus}
            onChange={(e) => setStockStatus(e.target.value)}
            className="w-full px-4 py-3 bg-[#071322] border border-[#25415F] rounded-lg text-white focus:outline-none focus:border-[#38A0E4] transition-colors"
          >
            <option value="Mevcut">Mevcut</option>
            <option value="Tükendi">Tükendi</option>
            <option value="Son birkaç adet">Son birkaç adet</option>
          </select>
        </div>

        {/* Image URL */}
        <div>
          <label className="block text-sm font-medium text-[#8899AA] mb-2">
            Görsel URL
          </label>
          <input
            type="url"
            value={imageUrl}
            onChange={(e) => setImageUrl(e.target.value)}
            className="w-full px-4 py-3 bg-[#071322] border border-[#25415F] rounded-lg text-white placeholder-[#5A6B7D] focus:outline-none focus:border-[#38A0E4] transition-colors"
            placeholder="https://ornek.com/gorsel.jpg"
          />
          {imageUrl && (
            <div className="mt-2 w-20 h-20 rounded-lg overflow-hidden bg-[#071322]">
              <img
                src={imageUrl}
                alt="Önizleme"
                className="w-full h-full object-cover"
                onError={(e) => {
                  (e.target as HTMLImageElement).style.display = 'none';
                }}
              />
            </div>
          )}
        </div>

        {/* Actions */}
        <div className="flex gap-3 pt-4">
          <button
            type="submit"
            disabled={loading || !name.trim()}
            className="flex-1 py-3 bg-[#38A0E4] hover:bg-[#2D8BC9] disabled:opacity-50 disabled:cursor-not-allowed text-white font-semibold rounded-lg transition-colors"
          >
            {loading ? 'Kaydediliyor...' : product ? 'Güncelle' : 'Ekle'}
          </button>
          <button
            type="button"
            onClick={onCancel}
            className="px-6 py-3 bg-[#071322] hover:bg-[#25415F] text-[#8899AA] font-medium rounded-lg transition-colors"
          >
            İptal
          </button>
        </div>
      </form>
    </div>
  );
}
