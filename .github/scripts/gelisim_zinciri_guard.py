from __future__ import annotations

import argparse
import re
import subprocess
from pathlib import Path

FULL_REQUIRED = (
    "kesif.md",
    "spec.md",
    "plan.md",
    "tasks.md",
    "zincir.md",
)
BUG_REQUIRED = (
    "root-cause.md",
    "tasks.md",
    "zincir.md",
)
FULL_STAGES = (
    "Anayasa",
    "Keşif",
    "Specify",
    "Plan",
    "Tasks",
    "Implement",
    "Converge",
    "Review / PR",
)
BUG_STAGES = (
    "Anayasa",
    "Hata tekrarlandı",
    "Sebep bulundu",
    "Implement",
    "Converge",
    "Review / PR",
)
KESIF_MARKERS = (
    "İSTEK:",
    "BAŞLANGIÇ:",
    "BİTİŞ:",
    "GÖRÜNEN:",
    "GÖRÜNÜM:",
    "ESNAF:",
    "VIXREX:",
    "TÜKETİCİ:",
    "KORUNACAK:",
    "KAPSAM DIŞI:",
    "KARAR SORUSU:",
)
PLACEHOLDERS = (
    "[FEATURE",
    "[DATE]",
    "[###",
    "NEEDS CLARIFICATION",
    "TODO",
    "TBD",
)
TYPE_PATTERN = re.compile(
    r"^İŞ TÜRÜ:[ \\t]*(özellik|değişiklik|hata)[ \\t]*$",
    flags=re.MULTILINE | re.IGNORECASE,
)
MEASURED_PATTERN = re.compile(r"^ÖLÇÜLDÜ:[ \t]*(.+)$", flags=re.MULTILINE)
KANIT_PATTERN = re.compile(r"^KANIT[ \t]+([^:\n]+):[ \t]*(.*)$", flags=re.MULTILINE)
BAKIM_DOSYALARI = (
    "package.json",
    "package-lock.json",
    "pubspec.lock",
    "yarn.lock",
    ".g.dart",
)
KAYIT_DISI = (
    ".g.dart",
    ".lock",
    "package-lock.json",
)
KAYIT_DISI_KLASOR = (
    "-snapshots/",
    "__snapshots__/",
)
VERI_KLASORU = "supabase/migrations/"


def run(*args: str) -> str:
    return subprocess.check_output(args, text=True, encoding="utf-8").strip()


def fail(messages: list[str]) -> int:
    for message in messages:
        print(f"::error::{message}")
    return 1


def changed_paths(base: str, head: str) -> list[str]:
    return [
        line
        for line in run("git", "diff", "--name-only", f"{base}...{head}").splitlines()
        if line
    ]


def marker_value(text: str, marker: str) -> str:
    for line in text.splitlines():
        stripped = line.strip().lstrip("-* ").strip()
        if stripped.startswith(marker):
            return stripped[len(marker):].strip(" *`")
    return ""


def measured_paths(text: str) -> list[str]:
    bulunan = []
    for raw in MEASURED_PATTERN.findall(text):
        token = raw.strip().split(" ")[0].strip("`,;*")
        if token:
            bulunan.append(token)
    return bulunan


def path_exists(token: str) -> bool:
    if Path(token).exists():
        return True
    if ":" in token:
        return Path(token.split(":")[0]).exists()
    return False


def bakim_degisikligi(paths: list[str]) -> bool:
    return all(path.endswith(BAKIM_DOSYALARI) for path in paths)


def kayit_disi(path: str) -> bool:
    if path.endswith(KAYIT_DISI):
        return True
    return any(mark in path for mark in KAYIT_DISI_KLASOR)


def mentioned(path: str, text: str) -> bool:
    if path in text:
        return True
    parent = "/".join(path.split("/")[:-1])
    return parent.count("/") >= 1 and parent in text


def records_text(work: Path) -> str:
    return "\n".join(
        item.read_text(encoding="utf-8")
        for item in sorted(work.rglob("*.md"))
    )


def kapi_kanitlari(chain: str) -> dict[str, str]:
    return {
        ad.strip().lower(): kanit.strip()
        for ad, kanit in KANIT_PATTERN.findall(chain)
    }


def acilan_kapilar(chain: str) -> list[str]:
    ham = marker_value(chain, "KAPILAR:")
    if not ham or ham.lower() == "yok":
        return []
    return [parca.strip().lower() for parca in ham.split(",") if parca.strip()]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base", required=True)
    parser.add_argument("--head", required=True)
    args = parser.parse_args()

    changed = changed_paths(args.base, args.head)
    outside_specs = [path for path in changed if not path.startswith("specs/")]
    if not outside_specs:
        print("Yalnız araştırma veya iş kayıtları değişti; ürün kodu etkilenmedi.")
        return 0

    if bakim_degisikligi(outside_specs):
        print("Bakım değişikliği (bağımlılık ve üretilen dosyalar); iş kaydı gerekmez.")
        return 0

    spec_dirs = sorted(
        {
            "/".join(path.split("/")[:2])
            for path in changed
            if path.startswith("specs/") and len(path.split("/")) >= 3
        }
    )
    if len(spec_dirs) != 1:
        return fail([
            "Ürün değişikliği tam olarak bir specs/<iş> kaydıyla gelmeli."
        ])

    work = Path(spec_dirs[0])
    chain_path = work / "zincir.md"
    if not chain_path.is_file():
        return fail([f"Eksik gelişim kaydı: {chain_path.as_posix()}"])

    chain = chain_path.read_text(encoding="utf-8")
    type_match = TYPE_PATTERN.search(chain)
    if not type_match:
        return fail([
            "zincir.md içinde İŞ TÜRÜ: özellik, değişiklik veya hata yazılmalı."
        ])

    work_type = type_match.group(1).lower()
    is_bug = work_type == "hata"
    required = BUG_REQUIRED if is_bug else FULL_REQUIRED
    stages = BUG_STAGES if is_bug else FULL_STAGES
    errors: list[str] = []

    for relative in required:
        path = work / relative
        if not path.is_file():
            errors.append(f"Eksik gelişim kaydı: {path.as_posix()}")

    if errors:
        return fail(errors)

    for stage in stages:
        if f"- [x] {stage}" not in chain:
            errors.append(f"Tamamlanmamış aşama: {stage}")

    combined = "\n".join(
        (work / relative).read_text(encoding="utf-8")
        for relative in required
    )
    for placeholder in PLACEHOLDERS:
        if placeholder.lower() in combined.lower():
            errors.append(f"Çözülmemiş taslak veya belirsizlik: {placeholder}")

    tasks_path = work / "tasks.md"
    if re.search(r"^- \[ \]", tasks_path.read_text(encoding="utf-8"), flags=re.MULTILINE):
        errors.append(f"Tamamlanmamış görev: {tasks_path.as_posix()}")

    if is_bug:
        cause = (work / "root-cause.md").read_text(encoding="utf-8")
        olculen = measured_paths(cause)
        if not olculen:
            errors.append(
                "root-cause.md içinde en az bir 'ÖLÇÜLDÜ: <dosya yolu> — <bulgu>' satırı olmalı."
            )
        for token in olculen:
            if not path_exists(token):
                errors.append(f"Kanıt olarak gösterilen yol depoda yok: {token}")
    else:
        kesif = (work / "kesif.md").read_text(encoding="utf-8")
        for marker in KESIF_MARKERS:
            if not marker_value(kesif, marker):
                errors.append(f"Keşif kaydında boş veya eksik satır: {marker}")
        olculen = measured_paths(kesif)
        if len(olculen) < 2:
            errors.append(
                "kesif.md bugünkü hâli ölçmeli: en az iki 'ÖLÇÜLDÜ: <dosya yolu> — <bulgu>' satırı."
            )
        for token in olculen:
            if not path_exists(token):
                errors.append(f"Keşifte gösterilen yol depoda yok: {token}")
        if marker_value(kesif, "ONAY:").lower() != "alındı":
            errors.append(
                "Keşif onaylanmadan uygulama gelemez: kesif.md içinde 'ONAY: alındı' yazmalı."
            )

    kapilar = acilan_kapilar(chain)
    kanitlar = kapi_kanitlari(chain)
    if any(path.startswith(VERI_KLASORU) for path in outside_specs) and "veri" not in kapilar:
        errors.append(
            "Veritabanı değişti: zincir.md içinde 'KAPILAR: veri' açılmalı ve kanıtı yazılmalı."
        )
    for kapi in kapilar:
        if not kanitlar.get(kapi):
            errors.append(f"Açılan kapının kanıtı boş: KANIT {kapi}:")

    kayitlar = records_text(work)
    for path in outside_specs:
        if kayit_disi(path):
            continue
        if not mentioned(path, kayitlar):
            errors.append(f"Kayıtta geçmeyen değişiklik: {path}")

    if marker_value(chain, "YAKINSAMA:").lower() != "tamam":
        errors.append("zincir.md içinde 'YAKINSAMA: tamam' yazmalı.")
    if marker_value(chain, "İNCELEME:").lower() != "hazır":
        errors.append("zincir.md içinde 'İNCELEME: hazır' yazmalı.")

    if errors:
        return fail(errors)

    acik = ", ".join(kapilar) if kapilar else "yok"
    print(f"Gelişim zinciri tamam: {work.as_posix()} ({work_type}) | açılan kapılar: {acik}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
