'use client';

import { useState, useEffect } from 'react';
import { createClient } from '@/lib/supabase/client';

interface StoreSnapshot {
  hasCover: boolean;
  hasDescription: boolean;
  hasProducts: boolean;
  hasGallery: boolean;
  hasWhatsapp: boolean;
  isPublished: boolean;
}

interface QualityItem {
  id: string;
  label: string;
  points: number;
  completed: boolean;
  action: string;
}

interface VixRexAssistantProps {
  storeId: string;
  storeSlug: string;
}

export default function VixRexAssistant({ storeId, storeSlug }: VixRexAssistantProps) {
  const [snapshot, setSnapshot] = useState<StoreSnapshot | null>(null);
  const [loading, setLoading] = useState(true);
  const supabase = createClient();

  useEffect(() => {
    loadSnapshot();
  }, [storeId]);

  const loadSnapshot = async () => {
    const { data: store } = await supabase
      .from('stores')
      .select('shelf_image_url, description, whatsapp, is_published')
      .eq('id', storeId)
      .single();

    const { count: productCount } = await supabase
      .from('products')
      .select('*', { count: 'exact', head: true })
      .eq('store_id', storeId)
      .eq('is_active', true);

    const galleryCount = store?.shelf_image_url ? 1 : 0;

    setSnapshot({
      hasCover: !!store?.shelf_image_url,
      hasDescription: !!store?.description && store.description.length > 10,
      hasProducts: (productCount || 0) > 0,
      hasGallery: galleryCount > 0,
      hasWhatsapp: !!store?.whatsapp,
      isPublished: store?.is_published || false,
    });
    setLoading(false);
  };

  const qualityItems: QualityItem[] = snapshot
    ? [
        {
          id: 'cover',
          label: 'Kapak fotoğrafı',
          points: 15,
          completed: snapshot.hasCover,
          action: '/admin/ayarlar',
        },
        {
          id: 'description',
          label: 'İşletme açıklaması',
          points: 15,
          completed: snapshot.hasDescription,
          action: '/admin/ayarlar',
        },
        {
          id: 'products',
          label: 'En az 3 ürün ekle',
          points: 25,
          completed: snapshot.hasProducts,
          action: '/admin/urunler',
        },
        {
          id: 'gallery',
          label: 'Galeri fotoğrafı',
          points: 15,
          completed: snapshot.hasGallery,
          action: '/admin/galeri',
        },
        {
          id: 'whatsapp',
          label: 'WhatsApp numarası',
          points: 15,
          completed: snapshot.hasWhatsapp,
          action: '/admin/ayarlar',
        },
        {
          id: 'publish',
          label: 'Vitrini yayınla',
          points: 15,
          completed: snapshot.isPublished,
          action: '#',
        },
      ]
    : [];

  const score = qualityItems.reduce((sum, item) => sum + (item.completed ? item.points : 0), 0);
  const nextImprovement = qualityItems.find((item) => !item.completed);

  if (loading) {
    return (
      <div className="bg-[#0E1B2E] rounded-xl border border-[#25415F] p-6">
        <div className="animate-pulse">
          <div className="h-6 bg-[#25415F] rounded w-1/3 mb-4" />
          <div className="space-y-3">
            {[1, 2, 3].map((i) => (
              <div key={i} className="h-10 bg-[#25415F] rounded" />
            ))}
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="bg-[#0E1B2E] rounded-xl border border-[#25415F] p-6">
      {/* Header */}
      <div className="flex items-center gap-3 mb-6">
        <div className="w-12 h-12 rounded-full bg-gradient-to-br from-[#38A0E4] to-[#10D8D8] flex items-center justify-center">
          <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" />
          </svg>
        </div>
        <div>
          <h3 className="text-white font-semibold">VixRex Asistanı</h3>
          <p className="text-[#8899AA] text-sm">Vitrininizi geliştirmek için ipuçları</p>
        </div>
      </div>

      {/* Score */}
      <div className="mb-6">
        <div className="flex items-center justify-between mb-2">
          <span className="text-[#8899AA] text-sm">Vitrin Kalitesi</span>
          <span className="text-white font-bold text-lg">{score}/100</span>
        </div>
        <div className="w-full h-2 bg-[#071322] rounded-full overflow-hidden">
          <div
            className="h-full bg-gradient-to-r from-[#38A0E4] to-[#10D8D8] transition-all duration-500"
            style={{ width: `${score}%` }}
          />
        </div>
      </div>

      {/* Next Improvement */}
      {nextImprovement && (
        <div className="mb-6 p-4 bg-[#38A0E4]/10 border border-[#38A0E4]/30 rounded-lg">
          <p className="text-[#38A0E4] text-sm font-medium mb-1">Sıradaki adım:</p>
          <p className="text-white">{nextImprovement.label}</p>
          <a
            href={nextImprovement.action}
            className="inline-block mt-2 text-[#38A0E4] text-sm hover:underline"
          >
            Şimdi yap →
          </a>
        </div>
      )}

      {/* Quality Checklist */}
      <div className="space-y-3">
        {qualityItems.map((item) => (
          <div
            key={item.id}
            className="flex items-center gap-3 p-3 rounded-lg bg-[#071322]"
          >
            <div
              className={`w-5 h-5 rounded-full flex items-center justify-center ${
                item.completed
                  ? 'bg-green-500/20 text-green-400'
                  : 'bg-[#25415F] text-[#5A6B7D]'
              }`}
            >
              {item.completed ? (
                <svg className="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7" />
                </svg>
              ) : (
                <div className="w-2 h-2 rounded-full bg-current" />
              )}
            </div>
            <span
              className={`flex-1 text-sm ${
                item.completed ? 'text-[#8899AA]' : 'text-white'
              }`}
            >
              {item.label}
            </span>
            <span className="text-[#5A6B7D] text-xs">+{item.points}</span>
          </div>
        ))}
      </div>

      {/* Quick Actions */}
      <div className="mt-6 pt-6 border-t border-[#25415F]">
        <p className="text-[#8899AA] text-sm mb-3">Hızlı İşlemler</p>
        <div className="grid grid-cols-2 gap-2">
          <a
            href={`/v/${storeSlug}`}
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center justify-center gap-2 py-2 px-3 bg-[#071322] hover:bg-[#25415F] rounded-lg text-[#8899AA] hover:text-white text-sm transition-colors"
          >
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
            </svg>
            Vitrini Gör
          </a>
          <a
            href={`/admin/urunler`}
            className="flex items-center justify-center gap-2 py-2 px-3 bg-[#071322] hover:bg-[#25415F] rounded-lg text-[#8899AA] hover:text-white text-sm transition-colors"
          >
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
            </svg>
            Ürün Ekle
          </a>
        </div>
      </div>
    </div>
  );
}
