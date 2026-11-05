import os, json, hashlib, pathlib, sys, urllib.request, urllib.error

BASE = "https://openrouter.ai/api/v1"
KOK = pathlib.Path(__file__).resolve().parent.parent

def anahtar():
    k = os.environ.get("OPENROUTER_MANAGEMENT_API_KEY", "")
    if k:
        return k
    for ad in ("public_web/.env", "public_web/.env.local"):
        p = KOK / ad
        if p.exists():
            for satir in p.read_text(encoding="utf-8").splitlines():
                if satir.startswith("OPENROUTER_MANAGEMENT_API_KEY="):
                    return satir.split("=", 1)[1].strip().strip('"')
    return ""

def get(path, key):
    req = urllib.request.Request(BASE + path, headers={"Authorization": "Bearer " + key, "User-Agent": "Mozilla/5.0"})
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            return r.status, json.loads(r.read().decode("utf-8", "ignore"))
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode("utf-8", "ignore")[:200]
    except Exception as e:
        return "ERR", str(e)[:120]

def sistem_ozet(veri):
    if not isinstance(veri, dict):
        return {}
    sistem = veri.get("system_prompt") or ""
    cfg = veri.get("config") if isinstance(veri.get("config"), dict) else {}
    tools = cfg.get("tools") or []
    tnames = sorted({(t.get("type") or (t.get("function") or {}).get("name") or "?") for t in tools if isinstance(t, dict)})
    rf = cfg.get("response_format")
    return {
        "model": cfg.get("model"),
        "response_format_type": rf.get("type") if isinstance(rf, dict) else None,
        "tools": tnames,
        "require_parameters": bool((cfg.get("provider") or {}).get("require_parameters")),
        "system_prompt_sha256": hashlib.sha256(sistem.encode("utf-8")).hexdigest(),
    }

def calisan_surumler(slug, key):
    # OpenRouter @preset/slug çağrısında designated değil, latest sürüm çalışır.
    sonuc = []
    offset = 0
    while True:
        st, data = get(f"/presets/{slug}/versions?limit=100&offset={offset}", key)
        if st != 200:
            return st, []
        kayitlar = data.get("data", data) if isinstance(data, dict) else data
        if not isinstance(kayitlar, list):
            return "ERR", []
        sonuc.extend(v for v in kayitlar if isinstance(v, dict))
        if len(kayitlar) < 100:
            return 200, sonuc
        offset += len(kayitlar)


def en_guncel_surum(kayitlar):
    try:
        return max(kayitlar, key=lambda v: int(v.get("version") or 0))
    except (ValueError, TypeError):
        return None


def main():
    key = anahtar()
    if not key:
        print("OPENROUTER_MANAGEMENT_API_KEY bulunamadi (ortam veya public_web/.env[.local])")
        return 2
    manifest_path = KOK / "openrouter" / "preset-sozlesmesi.json"
    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    except Exception as e:
        print("sozlesme okunamadi:", e)
        return 2
    st, data = get("/presets", key)
    if st != 200:
        print("presets:", st, data)
        return 2
    presets = data.get("data", data) if isinstance(data, dict) else data
    by_slug = {p.get("slug"): p for p in presets if isinstance(p, dict)}
    farkli = 0
    for beklenen in manifest.get("presets", []):
        slug = beklenen["slug"]
        p = by_slug.get(slug)
        if not p:
            print(slug + ": FARK (canlida yok)")
            farkli += 1
            continue
        st, surumler = calisan_surumler(slug, key)
        if st != 200:
            print(slug + ": FARK (surumler okunamadi: " + str(st) + ")")
            farkli += 1
            continue
        vv = en_guncel_surum(surumler)
        if not vv:
            print(slug + ": FARK (calisan latest surum bulunamadi)")
            farkli += 1
            continue
        vn = int(vv.get("version") or 0)
        canli = sistem_ozet(vv)
        alanlar = ["model", "response_format_type", "tools", "require_parameters", "system_prompt_sha256"]
        fark_list = [a for a in alanlar if canli.get(a) != beklenen.get(a)]
        if vv.get("id") != beklenen.get("designated_version_id") or vn != beklenen.get("designated_version"):
            fark_list.append("calisan latest surum")
        if fark_list:
            print(slug + " (v" + str(vn) + "): FARK -> " + ", ".join(fark_list))
            farkli += 1
        else:
            print(slug + " (latest v" + str(vn) + "): OK")
    print("SONUC:", "ESLESME" if farkli == 0 else "FARK VAR")
    return 0 if farkli == 0 else 1

if __name__ == "__main__":
    sys.exit(main())
