import type { Mesaj } from "../hooks/useOwnerChat";

interface Props {
  mesaj: Mesaj;
}

// Faz A parite (Tek Asistan planı, G3.1): Flutter'ın `ChatBubble`'ıyla aynı
// dile geçti — 14px (text-sm) her iki tarafta eşit, kullanıcı balonundan
// renk kaldırıldı (gradyan yalnız yayınlama düğmesinde kalır). Ayrım artık
// köşe yönünden geliyor: bot sol-alt köşesi kırık, kullanıcı sağ-alt.
export function ChatBubble({ mesaj }: Props) {
  const botMu = mesaj.kimden === "asistan";
  return (
    <div
      className={`max-w-[85%] border border-white/10 px-3.5 py-3 text-sm leading-relaxed text-slate-200 ${
        botMu
          ? "rounded-t-xl rounded-br-xl rounded-bl-[4px] bg-white/[0.06]"
          : "ml-auto rounded-t-xl rounded-bl-xl rounded-br-[4px] bg-[#0B1120]"
      }`}
    >
      {mesaj.metin}
    </div>
  );
}
