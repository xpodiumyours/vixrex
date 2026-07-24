'use client';

import { useState } from 'react';
import { createClient } from '@/lib/supabase/client';

interface GalleryItem {
  imageUrl: string;
  title?: string;
  description?: string;
}

interface GalleryManagerProps {
  storeId: string;
  initialItems: GalleryItem[];
}

export default function GalleryManager({ storeId, initialItems }: GalleryManagerProps) {
  const [items, setItems] = useState<GalleryItem[]>(initialItems);
  const [newImageUrl, setNewImageUrl] = useState('');
  const [newTitle, setNewTitle] = useState('');
  const [loading, setLoading] = useState(false);
  const supabase = createClient();

  const handleAdd = async () => {
    if (!newImageUrl.trim()) return;

    setLoading(true);
    const newItem: GalleryItem = {
      imageUrl: newImageUrl.trim(),
      title: newTitle.trim() || undefined,
    };

    const updatedItems = [...items, newItem];

    const { error } = await supabase
      .from('stores')
      .update({ gallery_items: updatedItems })
      .eq('id', storeId);

    if (!error) {
      setItems(updatedItems);
      setNewImageUrl('');
      setNewTitle('');
    }
    setLoading(false);
  };

  const handleRemove = async (index: number) => {
    if (!confirm('Bu fotoğrafı silmek istediğinize emin misiniz?')) return;

    setLoading(true);
    const updatedItems = items.filter((_, i) => i !== index);

    const { error } = await supabase
      .from('stores')
      .update({ gallery_items: updatedItems })
      .eq('id', storeId);

    if (!error) {
      setItems(updatedItems);
    }
    setLoading(false);
  };

  return (
    <div>
      {/* Add Image Form */}
      <div className="bg-[#0E1B2E] rounded-xl border border-[#25415F] p-6 mb-6">
        <h2 className="text-lg font-semibold text-white mb-4">Fotoğraf Ekle</h2>
        <div className="flex gap-4">
          <input
            type="url"
            value={newImageUrl}
            onChange={(e) => setNewImageUrl(e.target.value)}
            className="flex-1 px-4 py-3 bg-[#071322] border border-[#25415F] rounded-lg text-white placeholder-[#5A6B7D] focus:outline-none focus:border-[#38A0E4] transition-colors"
            placeholder="Fotoğraf URL'si"
          />
          <input
            type="text"
            value={newTitle}
            onChange={(e) => setNewTitle(e.target.value)}
            className="w-48 px-4 py-3 bg-[#071322] border border-[#25415F] rounded-lg text-white placeholder-[#5A6B7D] focus:outline-none focus:border-[#38A0E4] transition-colors"
            placeholder="Başlık (isteğe bağlı)"
          />
          <button
            onClick={handleAdd}
            disabled={loading || !newImageUrl.trim()}
            className="px-6 py-3 bg-[#38A0E4] hover:bg-[#2D8BC9] disabled:opacity-50 text-white font-medium rounded-lg transition-colors"
          >
            Ekle
          </button>
        </div>
      </div>

      {/* Gallery Grid */}
      {items.length === 0 ? (
        <div className="text-center py-12 bg-[#0E1B2E] rounded-xl border border-[#25415F]">
          <svg className="w-12 h-12 mx-auto text-[#5A6B7D] mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
          </svg>
          <p className="text-[#8899AA]">Henüz fotoğraf eklenmemiş.</p>
        </div>
      ) : (
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
          {items.map((item, index) => (
            <div
              key={index}
              className="relative group bg-[#0E1B2E] rounded-xl border border-[#25415F] overflow-hidden"
            >
              <div className="aspect-square">
                <img
                  src={item.imageUrl}
                  alt={item.title || `Fotoğraf ${index + 1}`}
                  className="w-full h-full object-cover"
                />
              </div>
              {item.title && (
                <div className="p-3">
                  <p className="text-white text-sm font-medium truncate">{item.title}</p>
                </div>
              )}
              <button
                onClick={() => handleRemove(index)}
                disabled={loading}
                className="absolute top-2 right-2 p-2 bg-red-500/80 hover:bg-red-500 text-white rounded-lg opacity-0 group-hover:opacity-100 transition-opacity"
              >
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
