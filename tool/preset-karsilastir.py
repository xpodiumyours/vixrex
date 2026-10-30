import json, urllib.request, hashlib, pathlib

KOK = pathlib.Path(__file__).resolve().parent.parent
ANAHTAR = ""
for satir in (KOK / "public_web" / ".env").read_text(encoding="utf-8").splitlines():
    if satir.startswith("OPENROUTER_MANAGEMENT_API_KEY="):
        ANAHTAR = satir.split("=", 1)[1].strip()
        break
TEMEL = "https://openrouter.ai/api/v1"

def istek(yol):
    ist = urllib.request.Request(TEMEL + yol, headers={"Authorization": "Bearer " + ANAHTAR})
    try:
        with urllib.request.urlopen(ist, timeout=30) as y:
            return json.loads(y.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        return {"error": {"message": e.read().decode("utf-8")[:120]}}

def govde_ozet(metin):
    return hashlib.sha256(metin.encode("utf-8")).hexdigest()[:12]

depo = {}
for ad, dosya in [("okuma", "openrouter/preset-okuma.json"), ("kart", "openrouter/preset-kart.json")]:
    govde = json.loads((KOK / dosya).read_text(encoding="utf-8"))
    sistem = next((m["content"] for m in govde["messages"] if m.get("role") == "system"), "")
    depo[ad] = {"sistem": sistem, "ozet": govde_ozet(sistem), "model": govde.get("model")}

print("DEPO:")
for ad, d in depo.items():
    print(f"  {ad}: ozet={d['ozet']} model={d['model']} uzunluk={len(d['sistem'])}")

liste = istek("/presets")
kayitlar = liste.get("data", liste) if isinstance(liste, dict) else liste
print("\nPRESETLER:")
for p in kayitlar:
    slug = p["slug"]
    en_son, en_buyuk = None, 0
    for v in range(1, 31):
        y = istek(f"/presets/{slug}/versions/{v}")
        veri = y.get("data") if isinstance(y, dict) else None
        if isinstance(veri, dict) and isinstance(veri.get("version"), int):
            en_son, en_buyuk = veri, veri["version"]
    if not en_son:
        print(f"  {slug}: SURUM OKUNAMADI")
        continue
    sistem = en_son.get("system_prompt") or ""
    ozet = govde_ozet(sistem)
    eslesme = ""
    for ad, d in depo.items():
        if ozet == d["ozet"]:
            eslesme = f" == DEPO/{ad} (birebir)"
    print(f"  {slug}: v{en_buyuk} ozet={ozet} uzunluk={len(sistem)}{eslesme}")
    print(f"    baslik: {sistem[:70]!r}")
