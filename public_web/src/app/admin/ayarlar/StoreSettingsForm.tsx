'use client';

import { useState } from 'react';
import { createClient } from '@/lib/supabase/client';

interface Store {
  id: string;
  name: string;
  slug: string;
  description: string | null;
  corporate_bio: string | null;
  whatsapp: string | null;
  instagram: string | null;
  website: string | null;
  address: string | null;
  working_hours: string | null;
  theme: string | null;
  is_published: boolean;
}

interface StoreSettingsFormProps {
  store: Store;
}

export default function StoreSettingsForm({ store }: StoreSettingsFormProps) {
  const [name, setName] = useState(store.name);
  const [description, setDescription] = useState(store.description || '');
  const [corporateBio, setCorporateBio] = useState(store.corporate_bio || '');
  const [whatsapp, setWhatsapp] = useState(store.whatsapp || '');
  const [instagram, setInstagram] = useState(store.instagram || '');
  const [website, setWebsite] = useState(store.website || '');
  const [address, setAddress] = useState(store.address || '');
  const [workingHours, setWorkingHours] = useState(store.working_hours || '');
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const supabase = createClient();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    setSuccess(false);

    const { error } = await supabase
      .from('stores')
      .update({
        name,
        description: description || null,
        corporate_bio: corporateBio || null,
        whatsapp: whatsapp || null,
        instagram: instagram || null,
        website: website || null,
        address: address || null,
        working_hours: workingHours || null,
      })
      .eq('id', store.id);

    if (error) {
      setError(error.message);
    } else {
      setSuccess(true);
      setTimeout(() => setSuccess(false), 3000);
    }
    setLoading(false);
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      {/* Başlık */}
      <div className="bg-[#0E1B2E] rounded-xl border border-[#25415F] p-6">
        <h2 className="text-lg font-semibold text-white mb-4">Mağaza Bilgileri</h2>

        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-[#8899AA] mb-2">
              Mağaza Adı
            </label>
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="w-full px-4 py-3 bg-[#071322] border border-[#25415F] rounded-lg text-white placeholder-[#5A6B7D] focus:outline-none focus:border-[#38A0E4] transition-colors"
              required
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-[#8899AA] mb-2">
              Kısa Açıklama
            </label>
            <textarea
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              rows={2}
              className="w-full px-4 py-3 bg-[#071322] border border-[#25415F] rounded-lg text-white placeholder-[#5A6B7D] focus:outline-none focus:border-[#38A0E4] transition-colors resize-none"
              placeholder="İşletmenizi kısaca tanıtın"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-[#8899AA] mb-2">
              Kurumsal Tanıtım
            </label>
            <textarea
              value={corporateBio}
              onChange={(e) => setCorporateBio(e.target.value)}
              rows={4}
              className="w-full px-4 py-3 bg-[#071322] border border-[#25415F] rounded-lg text-white placeholder-[#5A6B7D] focus:outline-none focus:border-[#38A0E4] transition-colors resize-none"
              placeholder="İşletmenizin detaylı tanıtımı"
            />
          </div>
        </div>
      </div>

      {/* İletişim */}
      <div className="bg-[#0E1B2E] rounded-xl border border-[#25415F] p-6">
        <h2 className="text-lg font-semibold text-white mb-4">İletişim Bilgileri</h2>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-[#8899AA] mb-2">
              WhatsApp Numarası
            </label>
            <input
              type="tel"
              value={whatsapp}
              onChange={(e) => setWhatsapp(e.target.value)}
              className="w-full px-4 py-3 bg-[#071322] border border-[#25415F] rounded-lg text-white placeholder-[#5A6B7D] focus:outline-none focus:border-[#38A0E4] transition-colors"
              placeholder="0555 123 45 67"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-[#8899AA] mb-2">
              Instagram
            </label>
            <input
              type="text"
              value={instagram}
              onChange={(e) => setInstagram(e.target.value)}
              className="w-full px-4 py-3 bg-[#071322] border border-[#25415F] rounded-lg text-white placeholder-[#5A6B7D] focus:outline-none focus:border-[#38A0E4] transition-colors"
              placeholder="kullanici_adi"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-[#8899AA] mb-2">
              Web Sitesi
            </label>
            <input
              type="url"
              value={website}
              onChange={(e) => setWebsite(e.target.value)}
              className="w-full px-4 py-3 bg-[#071322] border border-[#25415F] rounded-lg text-white placeholder-[#5A6B7D] focus:outline-none focus:border-[#38A0E4] transition-colors"
              placeholder="https://ornek.com"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-[#8899AA] mb-2">
              Çalışma Saatleri
            </label>
            <input
              type="text"
              value={workingHours}
              onChange={(e) => setWorkingHours(e.target.value)}
              className="w-full px-4 py-3 bg-[#071322] border border-[#25415F] rounded-lg text-white placeholder-[#5A6B7D] focus:outline-none focus:border-[#38A0E4] transition-colors"
              placeholder="09:00 - 18:00"
            />
          </div>
        </div>

        <div className="mt-4">
          <label className="block text-sm font-medium text-[#8899AA] mb-2">
            Adres
          </label>
          <textarea
            value={address}
            onChange={(e) => setAddress(e.target.value)}
            rows={2}
            className="w-full px-4 py-3 bg-[#071322] border border-[#25415F] rounded-lg text-white placeholder-[#5A6B7D] focus:outline-none focus:border-[#38A0E4] transition-colors resize-none"
            placeholder="İşletme adresiniz"
          />
        </div>
      </div>

      {/* Durum */}
      <div className="bg-[#0E1B2E] rounded-xl border border-[#25415F] p-6">
        <h2 className="text-lg font-semibold text-white mb-4">Yayın Durumu</h2>
        <div className="flex items-center gap-3">
          <div className={`w-3 h-3 rounded-full ${store.is_published ? 'bg-green-500' : 'bg-yellow-500'}`} />
          <span className="text-white">
            {store.is_published ? 'Vitrininiz yayında' : 'Vitriniz taslakta'}
          </span>
        </div>
        <p className="text-[#8899AA] text-sm mt-2">
          {store.is_published
            ? 'Müşterileriniz vitrininizi görebilir.'
            : 'Vitrinizi yayına almak için Flutter uygulamasını kullanın.'}
        </p>
      </div>

      {/* Messages */}
      {error && (
        <div className="p-3 bg-red-500/10 border border-red-500/30 rounded-lg text-red-400 text-sm">
          {error}
        </div>
      )}
      {success && (
        <div className="p-3 bg-green-500/10 border border-green-500/30 rounded-lg text-green-400 text-sm">
          Değişiklikler kaydedildi.
        </div>
      )}

      {/* Submit */}
      <button
        type="submit"
        disabled={loading}
        className="w-full py-3 bg-[#38A0E4] hover:bg-[#2D8BC9] disabled:opacity-50 text-white font-semibold rounded-lg transition-colors"
      >
        {loading ? 'Kaydediliyor...' : 'Değişiklikleri Kaydet'}
      </button>
    </form>
  );
}
