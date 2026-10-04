export interface SiparisKalemi {
  productName: string;
  quantity: number;
  unitPriceKurus: number;
}

export interface SiparisOzetiGirdi {
  storeName: string;
  customerName: string;
  customerPhone: string;
  customerNote?: string;
  fulfillment: "pickup" | "delivery";
  paymentMethod: "cash" | "online";
  items: SiparisKalemi[];
  amountKurus: number;
}

export function kurusMetni(kurus: number): string {
  const tam = Math.floor(kurus / 100);
  const kurusKisim = kurus % 100;
  return kurusKisim === 0
    ? `${tam} TL`
    : `${tam},${kurusKisim.toString().padStart(2, "0")} TL`;
}

export function siparisOzetiMetni(girdi: SiparisOzetiGirdi): string {
  const satirlar = girdi.items.map(
    (kalem) =>
      `- ${kalem.productName} x${kalem.quantity} = ${kurusMetni(kalem.unitPriceKurus * kalem.quantity)}`,
  );
  const teslim = girdi.fulfillment === "delivery" ? "Kurye ile teslim" : "Gel-al";
  const odeme = girdi.paymentMethod === "online" ? "Online ödeme" : "Kapıda ödeme";
  return [
    `Merhaba, ${girdi.storeName} için sipariş vermek istiyorum.`,
    `Müşteri: ${girdi.customerName} (${girdi.customerPhone})`,
    ...satirlar,
    `Teslim: ${teslim}`,
    `Ödeme: ${odeme}`,
    `Toplam: ${kurusMetni(girdi.amountKurus)}`,
    ...(girdi.customerNote ? [`Not: ${girdi.customerNote}`] : []),
  ].join("\n");
}

export function whatsappRakamlari(whatsapp: string): string {
  return whatsapp.replace(/[^\d]/g, "");
}

export function whatsappBaglantisi(whatsapp: string, metin: string): string | null {
  const rakam = whatsappRakamlari(whatsapp);
  if (rakam.length < 10) return null;
  return `https://wa.me/${rakam}?text=${encodeURIComponent(metin)}`;
}
