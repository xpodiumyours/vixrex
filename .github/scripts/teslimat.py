#!/usr/bin/env python3
"""VixRex teslimat zinciri — ajandan bağımsız merge tamamlayıcı.

NEDEN VAR (2026-09-07)
----------------------
Kök sorun kod yazmak değil, teslimat. Bir ajan (ChatGPT/Codex/Claude) PR açıp
sohbet turunu bitirdiğinde CI daha sonra tamamlanıyor ve PR'a geri dönen kimse
kalmıyor. Düzeltilmiş kod açık PR'da unutuluyor; bu sırada başka PR'lar main'e
girip onu eskitiyor. #425 tam olarak böyle oldu: Flutter borcunu kapatan
düzeltme hazırdı ama altyapı hatası yüzünden draft'ta kaldı ve main'in 5 commit
gerisine düştü.

Bu script sohbete bağlı değildir: zamanlayıcıyla ve CI bittiğinde tetiklenir.

NE YAPAR
--------
Etiketi `merge-approved` olan açık PR'lar için:
  1. Aynı anda tek teslimat olsun diye kilit uygular (en eski PR kazanır).
  2. Dal güncel main'i içeriyor mu bakar; içermiyorsa güncellemeye çalışır,
     çakışma varsa fail-closed durur.
  3. TAM HEAD SHA üzerindeki kontrolleri okur ve sınıflandırır:
     PASS / CODE_FAILURE / INFRA_FAILURE / CANCELLED / PENDING
  4. Altyapı hatası veya iptal varsa aynı SHA için yeniden çalıştırır (sınırlı).
  5. Zorunlu kapıların hepsi PASS ise squash merge eder.
  6. Merge sonrası gerçek main SHA'sını alır ve PR'a tek kalıcı durum yorumu
     yazar: `DELIVERED main@<sha>` veya `NOT DELIVERED: <sebep>`.

NE YAPMAZ
---------
GitHub'ın dal koruması bu depoda KAPALI. Ölçüldü (2026-09-07): koruma ve
ruleset uçları 403 dönüyor, mesaj "Upgrade to GitHub Pro or make this
repository public". Yani doğrudan main'e push veya elle yanlış merge bu
script tarafından ENGELLENEMEZ — yalnız rapor edilir. Gerçek kilit için
ücretli plan gerekiyor.

`tool/merge-hazir.sh` bu zincirin yerine geçmez: o yalnız push öncesi yerel
ölçümdür. Teslimatı bu script yürütür.
"""

from __future__ import annotations

import json
import os
import sys
import time
import urllib.error
import urllib.request
from typing import Any

API = "https://api.github.com"
DEPO = os.environ.get("GITHUB_REPOSITORY", "")
TOKEN = os.environ.get("GITHUB_TOKEN", "")

ONAY_ETIKETI = "merge-approved"
DURUM_ISARETI = "<!-- vixrex-teslimat-durumu -->"

# Teslimat için PASS olması gereken kontroller. Buradaki bir isim hiç
# koşmamışsa (PENDING kalıyorsa) teslimat beklemeye alınır — "koşmadı" asla
# "geçti" sayılmaz.
ZORUNLU_KAPILAR = (
    "Secret sızıntı taraması",
    "Değişiklik yüzeyi",
    "Next.js — lint, tip, test, build",
    "Flutter — analiz ve testler",
    "Şema üretim hattı — sapma kontrolü",
)

# Kod hatası SAYILMAYAN kontroller. Bunların kırmızısı altyapı kabul edilir:
# dış servis kotası, ödeme planı, geçici erişilemezlik.
ALTYAPI_ADLARI = (
    "Vercel",
    "TestSprite",
    "CodeRabbit",
    "Supabase Preview",
)

# Aynı SHA için en fazla kaç kez yeniden çalıştırılır.
AZAMI_YENIDEN_DENEME = 3


# --------------------------------------------------------------------------
# HTTP
# --------------------------------------------------------------------------

def istek(yol: str, yontem: str = "GET", govde: dict | None = None) -> Any:
    url = yol if yol.startswith("http") else f"{API}{yol}"
    veri = json.dumps(govde).encode() if govde is not None else None
    r = urllib.request.Request(url, data=veri, method=yontem)
    r.add_header("Authorization", f"Bearer {TOKEN}")
    r.add_header("Accept", "application/vnd.github+json")
    r.add_header("X-GitHub-Api-Version", "2022-11-28")
    if veri is not None:
        r.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(r) as c:
            ham = c.read()
            return json.loads(ham) if ham else {}
    except urllib.error.HTTPError as e:
        govde_metin = e.read().decode(errors="replace")
        return {"_hata": True, "_kod": e.code, "_govde": govde_metin}


def hatali(y: Any) -> bool:
    return isinstance(y, dict) and y.get("_hata") is True


# --------------------------------------------------------------------------
# Sınıflandırma
# --------------------------------------------------------------------------

def sinif(kontrol: dict) -> str:
    """Bir kontrolü PASS / PENDING / CANCELLED / INFRA_FAILURE / CODE_FAILURE."""
    durum = kontrol.get("status")
    sonuc = kontrol.get("conclusion")
    ad = kontrol.get("name", "")
    url = kontrol.get("details_url") or ""

    if durum != "completed":
        return "PENDING"
    if sonuc in ("success", "neutral", "skipped"):
        return "PASS"
    if sonuc == "cancelled":
        return "CANCELLED"

    # Buradan sonrası failure / timed_out / action_required.
    if any(a.lower() in ad.lower() for a in ALTYAPI_ADLARI):
        return "INFRA_FAILURE"
    # Vercel kota sayfasına yönlendiren hata kod hatası değildir.
    if "upgradeToPro" in url or "build-rate-limit" in url:
        return "INFRA_FAILURE"
    # Runner hiç atanmadıysa iş saniyeler içinde düşer ve adım üretmez.
    # (GitHub kotası bittiğinde ubuntu-latest işleri böyle davranıyor.)
    basla, bit = kontrol.get("started_at"), kontrol.get("completed_at")
    if basla and bit and basla == bit:
        return "INFRA_FAILURE"
    return "CODE_FAILURE"


def kontrolleri_al(sha: str) -> list[dict]:
    """Hem check-run'lar hem klasik status'lar tek listede."""
    hepsi: list[dict] = []
    y = istek(f"/repos/{DEPO}/commits/{sha}/check-runs?per_page=100")
    if not hatali(y):
        hepsi.extend(y.get("check_runs", []))
    y = istek(f"/repos/{DEPO}/commits/{sha}/status")
    if not hatali(y):
        for s in y.get("statuses", []):
            hepsi.append(
                {
                    "name": s.get("context", ""),
                    "status": "completed" if s.get("state") != "pending" else "in_progress",
                    "conclusion": {"success": "success", "failure": "failure", "error": "failure"}.get(
                        s.get("state"), s.get("state")
                    ),
                    "details_url": s.get("target_url") or "",
                    "started_at": None,
                    "completed_at": None,
                }
            )
    return hepsi


# --------------------------------------------------------------------------
# Durum yorumu
# --------------------------------------------------------------------------

def durum_yorumu_bul(pr_no: int) -> dict | None:
    y = istek(f"/repos/{DEPO}/issues/{pr_no}/comments?per_page=100")
    if hatali(y):
        return None
    for c in y:
        if DURUM_ISARETI in (c.get("body") or ""):
            return c
    return None


def durum_yaz(pr_no: int, metin: str, deneme: int | None = None) -> None:
    """PR'da TEK kalıcı durum yorumu tutar; her seferinde yenisini açmaz."""
    govde = f"{DURUM_ISARETI}\n{metin}"
    if deneme is not None:
        govde += f"\n\n<!-- yeniden-deneme:{deneme} -->"
    mevcut = durum_yorumu_bul(pr_no)
    if mevcut:
        if (mevcut.get("body") or "").split("<!-- yeniden-deneme")[0].strip() == govde.split(
            "<!-- yeniden-deneme"
        )[0].strip():
            return  # aynı durum, gürültü yapma
        istek(f"/repos/{DEPO}/issues/comments/{mevcut['id']}", "PATCH", {"body": govde})
    else:
        istek(f"/repos/{DEPO}/issues/{pr_no}/comments", "POST", {"body": govde})


def deneme_sayisi(pr_no: int) -> int:
    c = durum_yorumu_bul(pr_no)
    if not c:
        return 0
    govde = c.get("body") or ""
    if "<!-- yeniden-deneme:" not in govde:
        return 0
    try:
        return int(govde.split("<!-- yeniden-deneme:")[1].split("-->")[0].strip())
    except (IndexError, ValueError):
        return 0


# --------------------------------------------------------------------------
# Teslimat
# --------------------------------------------------------------------------

def yeniden_calistir(kontroller: list[dict]) -> bool:
    """Altyapı/iptal yüzünden düşen işleri AYNI SHA için yeniden başlatır."""
    kosu_kimlikleri = set()
    for k in kontroller:
        if sinif(k) not in ("INFRA_FAILURE", "CANCELLED"):
            continue
        url = k.get("details_url") or ""
        if "/actions/runs/" not in url:
            continue  # dış servis; yeniden çalıştıramayız
        try:
            kosu_kimlikleri.add(url.split("/actions/runs/")[1].split("/")[0])
        except IndexError:
            continue
    baslatildi = False
    for kimlik in kosu_kimlikleri:
        y = istek(f"/repos/{DEPO}/actions/runs/{kimlik}/rerun-failed-jobs", "POST")
        if not hatali(y):
            baslatildi = True
    return baslatildi


def bir_pr_teslim_et(pr: dict) -> str:
    no = pr["number"]
    sha = pr["head"]["sha"]

    # 1) Güncel main içeriliyor mu — GitHub'ın kendi karşılaştırması.
    kars = istek(f"/repos/{DEPO}/compare/main...{sha}")
    if hatali(kars):
        durum_yaz(no, f"**NOT DELIVERED:** main karşılaştırması okunamadı (HTTP {kars['_kod']}).")
        return "HATA"
    if kars.get("behind_by", 0) > 0:
        guncelle = istek(f"/repos/{DEPO}/pulls/{no}/update-branch", "PUT", {"expected_head_sha": sha})
        if hatali(guncelle):
            durum_yaz(
                no,
                f"**NOT DELIVERED:** dal main'in {kars['behind_by']} commit'i gerisinde ve "
                f"otomatik güncelleme başarısız (çakışma olabilir). Elle hizalanması gerekiyor.",
            )
            return "GERIDE"
        durum_yaz(
            no,
            f"**NOT DELIVERED (henüz):** dal main'in {kars['behind_by']} commit'i gerisindeydi, "
            f"güncellendi. Yeni SHA üzerinde kapılar baştan koşacak.",
        )
        return "GUNCELLENDI"

    # 2) TAM HEAD SHA üzerindeki kontroller.
    kontroller = kontrolleri_al(sha)
    if not kontroller:
        durum_yaz(no, f"**NOT DELIVERED:** `{sha[:8]}` üzerinde hiç kontrol yok — CI tetiklenmemiş.")
        return "KONTROL_YOK"

    siniflar = {k.get("name", ""): sinif(k) for k in kontroller}

    kod_hatasi = [a for a, s in siniflar.items() if s == "CODE_FAILURE"]
    if kod_hatasi:
        durum_yaz(no, "**NOT DELIVERED: CODE_FAILURE** — " + ", ".join(sorted(kod_hatasi)))
        return "CODE_FAILURE"

    altyapi = [a for a, s in siniflar.items() if s in ("INFRA_FAILURE", "CANCELLED")]
    eksik = [a for a in ZORUNLU_KAPILAR if siniflar.get(a) == "PENDING"]

    if altyapi:
        deneme = deneme_sayisi(no)
        if deneme < AZAMI_YENIDEN_DENEME and yeniden_calistir(kontroller):
            durum_yaz(
                no,
                "**NOT DELIVERED (henüz): INFRA_FAILURE** — "
                + ", ".join(sorted(altyapi))
                + f". Aynı SHA (`{sha[:8]}`) için yeniden çalıştırıldı "
                f"({deneme + 1}/{AZAMI_YENIDEN_DENEME}).",
                deneme=deneme + 1,
            )
            return "YENIDEN"
        durum_yaz(
            no,
            "**NOT DELIVERED: INFRA_FAILURE** — "
            + ", ".join(sorted(altyapi))
            + ". Yeniden çalıştırma hakkı bitti ya da dış servis. Bu bir kod hatası DEĞİL; "
            "insan kararı gerekiyor.",
        )
        return "INFRA_FAILURE"

    if eksik:
        durum_yaz(no, "**NOT DELIVERED (henüz):** zorunlu kapılar sürüyor — " + ", ".join(eksik))
        return "BEKLIYOR"

    kosmayan = [a for a in ZORUNLU_KAPILAR if a not in siniflar]
    if kosmayan:
        durum_yaz(
            no,
            "**NOT DELIVERED:** zorunlu kapılar bu SHA'da hiç koşmadı — "
            + ", ".join(kosmayan)
            + ". Koşmamak geçmek değildir.",
        )
        return "KOSMADI"

    # 3) Merge. expected_head_sha, ölçülen SHA'dan başkasının inmesini engeller.
    sonuc = istek(
        f"/repos/{DEPO}/pulls/{no}/merge",
        "PUT",
        {
            "merge_method": "squash",
            "sha": sha,
            "commit_title": f"{pr['title']} (#{no})",
        },
    )
    if hatali(sonuc):
        durum_yaz(no, f"**NOT DELIVERED:** merge reddedildi (HTTP {sonuc['_kod']}). {sonuc['_govde'][:300]}")
        return "MERGE_RET"

    # 4) Merge sonrası gerçek main SHA'sı.
    time.sleep(3)
    ana = istek(f"/repos/{DEPO}/commits/main")
    ana_sha = ana.get("sha", "?") if not hatali(ana) else "?"
    durum_yaz(
        no,
        f"**DELIVERED main@{ana_sha[:12]}**\n\n"
        f"Ölçülen ve teslim edilen SHA: `{sha[:12]}`. "
        f"Zorunlu kapıların hepsi bu SHA üzerinde PASS idi.\n\n"
        f"Main üzerindeki doğrulama koşusu ayrıca çalışır; kırmızıya dönerse revert gerekir.",
    )
    istek(f"/repos/{DEPO}/issues/{no}/labels/{ONAY_ETIKETI}", "DELETE")
    return "DELIVERED"


def main() -> int:
    if not DEPO or not TOKEN:
        print("GITHUB_REPOSITORY ve GITHUB_TOKEN gerekli", file=sys.stderr)
        return 2

    prler = istek(f"/repos/{DEPO}/pulls?state=open&per_page=100&sort=created&direction=asc")
    if hatali(prler):
        print(f"PR listesi alınamadı: {prler}", file=sys.stderr)
        return 1

    adaylar = [
        p
        for p in prler
        if any(e.get("name") == ONAY_ETIKETI for e in p.get("labels", []))
        and not p.get("draft", False)
    ]

    if not adaylar:
        print("Onaylı teslimat yok.")
        return 0

    # TESLIMAT KILIDI: aynı anda tek teslimat. En eski onaylı PR sırayı alır;
    # diğerleri sessizce geride kalmasın diye açıkça beklemeye yazılır.
    aktif, bekleyenler = adaylar[0], adaylar[1:]
    for p in bekleyenler:
        durum_yaz(
            p["number"],
            f"**NOT DELIVERED: DELIVERY_LOCK** — önce #{aktif['number']} teslim edilecek. "
            f"Bu PR sıradadır, unutulmadı.",
        )

    print(f"#{aktif['number']} teslim ediliyor...")
    sonuc = bir_pr_teslim_et(aktif)
    print(f"#{aktif['number']}: {sonuc}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
