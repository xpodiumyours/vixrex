import { describe, expect, it } from "vitest";
import { mergeOwnerChatHistory, type OwnerChatMergeMessage } from "@/lib/ownerChatMerge";

type TestMesaj = OwnerChatMergeMessage & { id: number };
const mesaj = (seq: number, metin = "evet", clientMessageId: string | null = `client-${seq}`): TestMesaj => ({
  id: seq,
  kimden: "kullanici",
  metin,
  serverSeq: seq,
  clientMessageId,
});
const kimlikVer = (mesaj: TestMesaj) => ({ ...mesaj, id: 10_000 + mesaj.serverSeq! });

describe("owner sohbet geçmişi birleştirme", () => {
  it("500 yerel mesaj 20'lik RPC penceresiyle budanmaz", () => {
    const onceki = Array.from({ length: 500 }, (_, index) => mesaj(index + 1, `mesaj-${index + 1}`));
    const gelen = onceki.slice(-20).map((item) => ({ ...item }));
    const sonuc = mergeOwnerChatHistory(onceki, gelen, kimlikVer);
    expect(sonuc).toHaveLength(500);
    expect(sonuc[0].serverSeq).toBe(1);
    expect(sonuc.at(-1)?.serverSeq).toBe(500);
  });

  it("aynı metinli ama farklı kalıcı kimlikli yeni mesajı kaybetmez", () => {
    const onceki = [mesaj(1, "evet")];
    const gelen = [mesaj(1, "evet"), mesaj(2, "evet")];
    const sonuc = mergeOwnerChatHistory(onceki, gelen, kimlikVer);
    expect(sonuc).toHaveLength(2);
    expect(sonuc[1].serverSeq).toBe(2);
    expect(sonuc[1].metin).toBe("evet");
  });

  it("kimliksiz yerel mesajla sunucu kaydını bir kez eşler, ikinci oluşumu korur", () => {
    const yerel: TestMesaj = { id: 1, kimden: "kullanici", metin: "evet" };
    const gelen = [mesaj(1, "evet"), mesaj(2, "evet")];
    const sonuc = mergeOwnerChatHistory([yerel], gelen, kimlikVer);
    expect(sonuc).toHaveLength(2);
    expect(sonuc[1].serverSeq).toBe(2);
  });

  it("aynı kalıcı mesajı sonraki poll'da tekrar eklemez", () => {
    const onceki = [mesaj(1, "bir"), mesaj(2, "iki"), mesaj(3, "üç")];
    const gelen = [mesaj(2, "iki"), mesaj(3, "üç")];
    expect(mergeOwnerChatHistory(onceki, gelen, kimlikVer)).toHaveLength(3);
  });
});
