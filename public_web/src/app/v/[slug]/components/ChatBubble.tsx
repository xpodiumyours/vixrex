import type { Mesaj } from "../hooks/useOwnerChat";

interface Props {
  mesaj: Mesaj;
}

export function ChatBubble({ mesaj }: Props) {
  return (
    <div
      className={`max-w-[85%] rounded-xl px-3 py-2 text-xs leading-relaxed ${
        mesaj.kimden === "asistan"
          ? "bg-white/[0.06] text-slate-200"
          : "ml-auto bg-blue-600 text-white"
      }`}
    >
      {mesaj.metin}
    </div>
  );
}
