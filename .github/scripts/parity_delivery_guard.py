#!/usr/bin/env python3
"""Teslimattan önce Flutter → Next Parity check'inin tamamlanmasını zorunlu kıl.

Başarısız bir parite check'ini burada PASS saymayız; tamamlanmışsa kararın
sınıflandırmasını `teslimat.py` yapar. Bu bekçi yalnız eksik/PENDING check varken
teslimat scriptinin erken merge etmesini engeller.
"""

from __future__ import annotations

import json
import os
import sys
import urllib.error
import urllib.request
from typing import Any


API = "https://api.github.com"
DEPO = os.environ.get("GITHUB_REPOSITORY", "")
TOKEN = os.environ.get("GITHUB_TOKEN", "")
ONAY_ETIKETI = "merge-approved"
PARITE_KAPISI = "Flutter → Next Parity"


def istek(yol: str) -> Any:
    r = urllib.request.Request(f"{API}{yol}")
    r.add_header("Authorization", f"Bearer {TOKEN}")
    r.add_header("Accept", "application/vnd.github+json")
    r.add_header("X-GitHub-Api-Version", "2022-11-28")
    try:
        with urllib.request.urlopen(r) as cevap:
            return json.loads(cevap.read())
    except urllib.error.HTTPError as exc:
        govde = exc.read().decode(errors="replace")
        raise RuntimeError(f"GitHub API {exc.code}: {govde[:300]}") from exc


def main() -> int:
    if not DEPO or not TOKEN:
        print("GITHUB_REPOSITORY ve GITHUB_TOKEN gerekli", file=sys.stderr)
        return 2

    try:
        prler = istek(
            f"/repos/{DEPO}/pulls?state=open&per_page=100&sort=created&direction=asc"
        )
        adaylar = [
            pr
            for pr in prler
            if any(e.get("name") == ONAY_ETIKETI for e in pr.get("labels", []))
            and not pr.get("draft", False)
        ]
        if not adaylar:
            print("Onaylı teslimat yok; parite bekçisi geçiyor.")
            return 0

        aktif = adaylar[0]
        sha = aktif["head"]["sha"]
        cevap = istek(f"/repos/{DEPO}/commits/{sha}/check-runs?per_page=100")
        eslesen = [
            check
            for check in cevap.get("check_runs", [])
            if check.get("name") == PARITE_KAPISI
        ]
    except RuntimeError as exc:
        print(f"::error::Parite teslimat bekçisi: {exc}", file=sys.stderr)
        return 1

    if not eslesen:
        print(
            f"::error::#{aktif['number']} `{sha[:12]}` üzerinde "
            f"{PARITE_KAPISI!r} hiç koşmadı. Teslimat durduruldu.",
            file=sys.stderr,
        )
        return 1

    son = max(eslesen, key=lambda check: int(check.get("id", 0)))
    if son.get("status") != "completed":
        print(
            f"::error::#{aktif['number']} {PARITE_KAPISI} henüz tamamlanmadı "
            f"(status={son.get('status')}). Teslimat durduruldu.",
            file=sys.stderr,
        )
        return 1

    print(
        f"#{aktif['number']} {PARITE_KAPISI} tamamlandı: "
        f"conclusion={son.get('conclusion')}. Nihai sınıflandırmayı teslimat.py yapacak."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
