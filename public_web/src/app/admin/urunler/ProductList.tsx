'use client';

import { useState } from 'react';
import { createClient } from '@/lib/supabase/client';
import ProductForm from './ProductForm';

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

interface ProductListProps {
  products: Product[];
  categories: Category[];
  storeId: string;
}

export default function ProductList({ products: initialProducts, categories, storeId }: ProductListProps) {
  const [products, setProducts] = useState<Product[]>(initialProducts);
  const [showForm, setShowForm] = useState(false);
  const [editingProduct, setEditingProduct] = useState<Product | null>(null);
  const [loading, setLoading] = useState<string | null>(null);
  const supabase = createClient();

  const handleEdit = (product: Product) => {
    setEditingProduct(product);
    setShowForm(true);
  };

  const handleDelete = async (productId: string) => {
    if (!confirm('Bu ürünü silmek istediğinize emin misiniz?')) return;

    setLoading(productId);
    const { error } = await supabase
      .from('products')
      .update({ is_active: false })
      .eq('id', productId);

    if (!error) {
      setProducts(products.filter(p => p.id !== productId));
    }
    setLoading(null);
  };

  const handleToggleVisibility = async (product: Product) => {
    setLoading(product.id);
    const newVisibility = !product.is_visible;
    const { error } = await supabase
      .from('products')
      .update({ is_visible: newVisibility })
      .eq('id', product.id);

    if (!error) {
      setProducts(products.map(p =>
        p.id === product.id ? { ...p, is_visible: newVisibility } : p
      ));
    }
    setLoading(null);
  };

  const handleSave = (savedProduct: Product) => {
    if (editingProduct) {
      setProducts(products.map(p => p.id === savedProduct.id ? savedProduct : p));
    } else {
      setProducts([savedProduct, ...products]);
    }
    setShowForm(false);
    setEditingProduct(null);
  };

  if (showForm) {
    return (
      <ProductForm
        product={editingProduct}
        categories={categories}
        storeId={storeId}
        onSave={handleSave}
        onCancel={() => {
          setShowForm(false);
          setEditingProduct(null);
        }}
      />
    );
  }

  return (
    <div>
      {/* Add Product Button */}
      <button
        onClick={() => setShowForm(true)}
        className="mb-6 px-4 py-2 bg-[#38A0E4] hover:bg-[#2D8BC9] text-white font-medium rounded-lg transition-colors flex items-center gap-2"
      >
        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
        </svg>
        Yeni Ürün Ekle
      </button>

      {/* Product List */}
      {products.length === 0 ? (
        <div className="text-center py-12 bg-[#0E1B2E] rounded-xl border border-[#25415F]">
          <svg className="w-12 h-12 mx-auto text-[#5A6B7D] mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4" />
          </svg>
          <p className="text-[#8899AA]">Henüz ürün eklenmemiş.</p>
        </div>
      ) : (
        <div className="space-y-3">
          {products.map((product) => (
            <div
              key={product.id}
              className="bg-[#0E1B2E] rounded-xl border border-[#25415F] p-4 flex items-center gap-4"
            >
              {/* Product Image */}
              <div className="w-16 h-16 rounded-lg bg-[#071322] overflow-hidden flex-shrink-0">
                {product.image_urls?.[0] ? (
                  <img
                    src={product.image_urls[0]}
                    alt={product.name}
                    className="w-full h-full object-cover"
                  />
                ) : (
                  <div className="w-full h-full flex items-center justify-center">
                    <svg className="w-6 h-6 text-[#5A6B7D]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                    </svg>
                  </div>
                )}
              </div>

              {/* Product Info */}
              <div className="flex-1 min-w-0">
                <h3 className="text-white font-medium truncate">{product.name}</h3>
                <p className="text-[#8899AA] text-sm">
                  {product.price_amount ? `${product.price_amount} ₺` : product.price_text || 'Fiyat yok'}
                </p>
              </div>

              {/* Visibility Toggle */}
              <button
                onClick={() => handleToggleVisibility(product)}
                disabled={loading === product.id}
                className={`px-3 py-1 rounded-full text-xs font-medium transition-colors ${
                  product.is_visible
                    ? 'bg-green-500/20 text-green-400 hover:bg-green-500/30'
                    : 'bg-[#5A6B7D]/20 text-[#8899AA] hover:bg-[#5A6B7D]/30'
                }`}
              >
                {product.is_visible ? 'Görünür' : 'Gizli'}
              </button>

              {/* Actions */}
              <div className="flex items-center gap-2">
                <button
                  onClick={() => handleEdit(product)}
                  className="p-2 rounded-lg text-[#8899AA] hover:bg-[#071322] hover:text-white transition-colors"
                >
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                  </svg>
                </button>
                <button
                  onClick={() => handleDelete(product.id)}
                  disabled={loading === product.id}
                  className="p-2 rounded-lg text-[#8899AA] hover:bg-red-500/10 hover:text-red-400 transition-colors"
                >
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                  </svg>
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
