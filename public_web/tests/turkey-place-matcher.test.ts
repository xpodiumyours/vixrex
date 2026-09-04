import { describe, expect, it } from "vitest";
import { ilIlceCikar } from "../src/lib/turkeyPlaceMatcher";

describe("ilIlceCikar — serbest metinden il/ilçe çıkarımı", () => {
  it("net bir ilçe bulunca ilgili ili de döner", () => {
    expect(ilIlceCikar("Kadıköy'de bir kuaförüm var.")).toEqual({
      il: "İstanbul",
      ilce: "Kadıköy",
    });
  });

  it("yalnız il geçiyorsa ilçe null döner", () => {
    expect(ilIlceCikar("Ankara'da hizmet veriyoruz.")).toEqual({ il: "Ankara", ilce: null });
  });

  it("hiç yer adı yoksa null döner", () => {
    expect(ilIlceCikar("Kaliteli ürünler satıyoruz.")).toBeNull();
  });

  it("işletme adındaki çıplak ilçe kelimesini konum sanmaz", () => {
    expect(ilIlceCikar("Konak kafe 05421802573")).toBeNull();
  });

  it("aynı ilçe açık konum ekiyle yazılırsa yine doğru çözülür", () => {
    expect(ilIlceCikar("Konak'ta bir kafe işletiyorum")).toEqual({
      il: "İzmir",
      ilce: "Konak",
    });
  });

  it("il ve ilçe birlikte açıkça yazılırsa çıplak ilçe adı da doğrulanır", () => {
    expect(ilIlceCikar("İzmir Konak şubemiz")).toEqual({
      il: "İzmir",
      ilce: "Konak",
    });
  });

  it("gerçek belirsizlik — 'Kemer' hem Antalya hem Burdur'da, il belirtilmezse tahmin etmez", () => {
    expect(ilIlceCikar("Kemer'de küçük bir kırtasiyem var.")).toBeNull();
  });

  it("belirsiz ilçe, il de metinde geçince doğru çözülür", () => {
    expect(ilIlceCikar("Antalya Kemer'de küçük bir kırtasiyem var.")).toEqual({
      il: "Antalya",
      ilce: "Kemer",
    });
    expect(ilIlceCikar("Burdur'un Kemer ilçesinde çiftliğimiz var.")).toEqual({
      il: "Burdur",
      ilce: "Kemer",
    });
  });

  it("kelime sınırı korunur — bitişik bir kelimenin parçası yanlışlıkla eşleşmez", () => {
    // "Kaş" bir ilçe adı (Antalya) — "kaşarcı" gibi bitişik bir kelimenin
    // içinde geçse bile kelime sınırı sayesinde yanlış eşleşme olmamalı.
    expect(ilIlceCikar("Kaşarcıdan taze peynir alıyoruz.")).toBeNull();
  });

  it("il kanonik isimle döner, kullanıcı yazımından bağımsız (büyük/küçük harf, aksan)", () => {
    expect(ilIlceCikar("cekmekoy'de butik isletiyorum")).toEqual({
      il: "İstanbul",
      ilce: "Çekmeköy",
    });
  });

  it("kesme işaretsiz bitişik ek (örn. 'çekmeköyde') kelime sınırını bozduğu için eşleşmez — hassasiyet tercih edilir, tahmin yok", () => {
    // Kasıtlı tasarım: sağ kelime sınırını gevşetmek "kaşarcı" gibi yanlış
    // pozitifleri geri getirirdi (bkz. yukarıdaki test). Kesme işaretsiz
    // bitişik ekler yakalanamaz ama zararsızca boş döner — esnaf sonra
    // normal soru akışında elle girer.
    expect(ilIlceCikar("cekmekoyde butik isletiyorum")).toBeNull();
  });
});
