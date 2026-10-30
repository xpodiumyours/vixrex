export interface YazmaSonucu {
  tuketiciDogrulandi?: boolean;
  toplam: number;
  yayinda: number;
  taslak: number;
  hatali: number;
  satirlar: Array<{ sira: number; ad: string; durum: string; sebep?: string; id?: string; gorsel?: string | null }>;
}

export interface FaturaSonucKarti {
  sira: number;
  ad: string;
  fiyat: string;
  gorsel: string | null;
}

interface FaturaIslemSonucuProps {
  sonuc: YazmaSonucu;
  kartlar: FaturaSonucKarti[];
  storeSlug: string;
  hata: string | null;
  yukleniyor: boolean;
  baglantiKopyalandi: boolean;
  onYayinla: () => void;
  onPaylas: () => void;
  onKartlaraDon: () => void;
  onYeniFatura: () => void;
  onClose?: () => void;
}

export function FaturaIslemSonucu({ sonuc, kartlar, storeSlug, hata, yukleniyor, baglantiKopyalandi,
  onYayinla, onPaylas, onKartlaraDon, onYeniFatura, onClose }: FaturaIslemSonucuProps) {
  const yayinlanabilirTaslak = sonuc.satirlar.filter((satir) => satir.durum === "taslak" && satir.id).length;
  return (
    <>
      {kartlar.length > 0 && (
        <section className="fatura-vitrin-hazir">
          <h4>Yayınlanan ürünler</h4>
          <ul className="fatura-vitrin-izgara">
            {kartlar.map((kart) => (
              <li key={kart.sira}>
                {kart.gorsel ? <img src={kart.gorsel} alt={kart.ad} loading="lazy" />
                  : <div className="fatura-kart-gorselsiz">Görsel hazırlanıyor</div>}
                <span>{kart.ad}</span>
                {kart.fiyat && <strong>{kart.fiyat} TL</strong>}
              </li>
            ))}
          </ul>
          <div className="fatura-araclar">
            <a className="fatura-birincil" href={`/v/${encodeURIComponent(storeSlug)}`} target="_blank" rel="noreferrer">Vitrini aç</a>
            <button type="button" onClick={onPaylas} disabled={yukleniyor}>
              {baglantiKopyalandi ? "Bağlantı kopyalandı" : "Vitrini paylaş"}
            </button>
          </div>
        </section>
      )}
      <ul className="fatura-ozet" role="status">
        {sonuc.yayinda > 0 && <li><strong>{sonuc.yayinda}</strong> ürün {sonuc.tuketiciDogrulandi
          ? "vitrinde görünüyor" : "için yayın kaydı alındı; tüketici görünümü doğrulanamadı"}</li>}
        {sonuc.taslak > 0 && <li><strong>{sonuc.taslak}</strong> ürün taslak — yayınlamadan görünmez</li>}
        {sonuc.hatali > 0 && <li><strong>{sonuc.hatali}</strong> satır eklenemedi</li>}
      </ul>
      <ul className="fatura-satir-ozet">
        {sonuc.satirlar.filter((satir) => satir.durum !== "yayinda").map((satir) => (
          <li key={satir.sira}>{satir.ad} — {satir.sebep ?? satir.durum}</li>
        ))}
      </ul>
      {hata && <p className="fatura-hata" role="alert">{hata}</p>}
      <div className="fatura-sonuc-islemleri">
        {yayinlanabilirTaslak > 0 && (
          <button type="button" className="fatura-birincil" onClick={onYayinla} disabled={yukleniyor}>
            {yukleniyor ? "Yayınlanıyor…" : `${yayinlanabilirTaslak} ürünü yayınla`}
          </button>
        )}
        <button type="button" className="fatura-ikincil" onClick={onKartlaraDon} disabled={yukleniyor}>Kartları düzenle</button>
        <button type="button" className="fatura-ikincil" onClick={onYeniFatura} disabled={yukleniyor}>Başka fatura ekle</button>
        {onClose && <button type="button" className="fatura-ikincil" onClick={onClose} disabled={yukleniyor}>Kapat</button>}
      </div>
    </>
  );
}
