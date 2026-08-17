#!/usr/bin/env python3
"""PR base bekçisi.

NEDEN VAR
AGENTS.md Git değişmezleri: "Yeni bir PR açılırken base'in `main` olduğu
açıkça doğrulanır (`gh pr create --base main`)". 2026-08-15 dersi:
#170→#171→#172→#173 birbirinin üzerine zincirlendi ve hiçbiri main'e
ulaşmadı — zincirin en ucu main'e ulaşana kadar iş bitmiş sayılmaz. Kural
yalnız metindi; bu betik onu koda bağlar.

NE YAPAR
  - PR'ın base dalını okur (BASE_REF ortam değişkeni).
  - Base `main` ise geçer.
  - Base `main` değilse kırmızı: ya base main yapılır (gh pr edit --base
    main), ya da bilinçli bir zincirleme ise PR açıklamasına
    `Zincir: <base-dal>` satırı eklenir (zincirin en ucu main'e ulaşana
    kadar iş bitmiş sayılmaz).
"""

import os
import re
import sys

ZINCIR_DESENI = re.compile(r"zincir\s*:\s*\S", re.IGNORECASE)

import sys

if sys.stdout and hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

def main() -> None:
    base = os.environ.get("BASE_REF", "")
    if not base:
        print("::warning::BASE_REF tanımlı değil — kontrol atlanıyor.")
        return

    if base == "main":
        print("[OK] PR base'i main.")
        return

    pr_metni = (
        os.environ.get("PR_TITLE", "") + "\n" + os.environ.get("PR_BODY", "")
    )
    if ZINCIR_DESENI.search(pr_metni):
        print(
            f"[OK] Base '{base}' main değil ama açıklamada 'Zincir:' satırı "
            "var — bilinçli zincirleme kabul edildi. Unutma: zincirin en ucu "
            "main'e ulaşana kadar iş bitmiş sayılmaz."
        )
        return

    print(
        f"::error::PR base'i '{base}', main değil. AGENTS.md kuralı: yeni PR "
        "base'i main olmalı. `gh pr edit <PR> --base main` ile düzelt veya "
        "bilinçli zincirleme ise açıklamaya 'Zincir: <base-dal>' satırı ekle "
        "(2026-08-15 dersi: #170→#173 zincirlendi, hiçbiri main'e ulaşmadı)."
    )
    sys.exit(1)


if __name__ == "__main__":
    main()
