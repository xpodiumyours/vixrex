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
    "checklists/requirements.md",
    "analysis.md",
    "convergence.md",
    "review.md",
    "zincir.md",
)
BUG_REQUIRED = (
    "root-cause.md",
    "tasks.md",
    "convergence.md",
    "review.md",
    "zincir.md",
)
FULL_STAGES = (
    "Anayasa",
    "Keşif",
    "Specify",
    "Clarify",
    "Plan",
    "Checklist",
    "Tasks",
    "Analyze",
    "Implement",
    "Converge",
    "Review / PR",
)
BUG_STAGES = (
    "Anayasa",
    "Hata tekrarlandı",
    "Sebep bulundu",
    "Tasks",
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
    r"^İŞ TÜRÜ:\s*(özellik|değişiklik|hata)\s*$",
    flags=re.MULTILINE | re.IGNORECASE,
)
MEASURED_PATTERN = re.compile(r"^ÖLÇÜLDÜ:\s*(.+)$", flags=re.MULTILINE)
KAYIT_DISI = (
    ".g.dart",
    ".lock",
    "package-lock.json",
)
KAYIT_DISI_KLASOR = (
    "-snapshots/",
    "__snapshots__/",
)


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


def kayit_disi(path: str) -> bool:
    if path.endswith(KAYIT_DISI):
        return True
    return any(mark in path for mark in KAYIT_DISI_KLASOR)


def mentioned(path: str, text: str) -> bool:
    parts = path.split("/")
    for index in range(len(parts), 0, -1):
        if "/".join(parts[:index]) in text:
            return True
    return False


def records_text(work: Path) -> str:
    return "\n".join(
        item.read_text(encoding="utf-8")
        for item in sorted(work.rglob("*.md"))
    )


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

    for relative in ("tasks.md",):
        content = (work / relative).read_text(encoding="utf-8")
        if re.search(r"^- \[ \]", content, flags=re.MULTILINE):
            errors.append(f"Tamamlanmamış görev: {(work / relative).as_posix()}")

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

    kayitlar = records_text(work)
    for path in outside_specs:
        if kayit_disi(path):
            continue
        if not mentioned(path, kayitlar):
            errors.append(f"Kayıtta geçmeyen değişiklik: {path}")

    checklist_path = work / "checklists/requirements.md"
    if not is_bug:
        checklist = checklist_path.read_text(encoding="utf-8")
        if re.search(r"^- \[ \]", checklist, flags=re.MULTILINE):
            errors.append(f"Tamamlanmamış madde: {checklist_path.as_posix()}")

        analysis = (work / "analysis.md").read_text(encoding="utf-8")
        if "ÇELİŞKİ: YOK" not in analysis:
            errors.append("Analyze sonucu temiz değil.")

    convergence = (work / "convergence.md").read_text(encoding="utf-8")
    review = (work / "review.md").read_text(encoding="utf-8")
    if "SONUÇ: YAKINSADI" not in convergence:
        errors.append("Implement ve Converge döngüsü tamamlanmamış.")
    if "SONUÇ: İNCELEMEYE HAZIR" not in review:
        errors.append("Bağımsız inceleme sonucu hazır değil.")

    if errors:
        return fail(errors)

    print(f"Gelişim zinciri tamam: {work.as_posix()} ({work_type})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
