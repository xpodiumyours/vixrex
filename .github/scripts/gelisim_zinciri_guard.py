from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

REQUIRED = (
    "spec.md",
    "plan.md",
    "tasks.md",
    "checklists/requirements.md",
    "analysis.md",
    "convergence.md",
    "review.md",
    "zincir.md",
)

STAGES = (
    "Anayasa",
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

PLACEHOLDERS = (
    "[FEATURE",
    "[DATE]",
    "[###",
    "NEEDS CLARIFICATION",
    "TODO",
    "TBD",
)


def run(*args: str) -> str:
    return subprocess.check_output(args, text=True, encoding="utf-8").strip()


def fail(messages: list[str]) -> int:
    for message in messages:
        print(f"::error::{message}")
    return 1


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base", required=True)
    parser.add_argument("--head", required=True)
    args = parser.parse_args()

    changed = [
        line
        for line in run("git", "diff", "--name-only", f"{args.base}...{args.head}").splitlines()
        if line
    ]
    outside_specs = [path for path in changed if not path.startswith("specs/")]
    if not outside_specs:
        print("Yalnız iş kayıtları değişti; zincir kapısı geçti.")
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
            "Her değişiklik tam bir iş kaydıyla gelmeli; bu değişiklikte tam olarak bir specs/<iş> klasörü bekleniyor."
        ])

    feature = Path(spec_dirs[0])
    errors: list[str] = []
    for relative in REQUIRED:
        path = feature / relative
        if not path.is_file():
            errors.append(f"Eksik gelişim kaydı: {path.as_posix()}")

    if errors:
        return fail(errors)

    chain = (feature / "zincir.md").read_text(encoding="utf-8")
    for stage in STAGES:
        if f"- [x] {stage}" not in chain:
            errors.append(f"Tamamlanmamış aşama: {stage}")

    combined = "
".join(
        (feature / relative).read_text(encoding="utf-8")
        for relative in REQUIRED
    )
    for placeholder in PLACEHOLDERS:
        if placeholder.lower() in combined.lower():
            errors.append(f"Çözülmemiş taslak veya belirsizlik bulundu: {placeholder}")

    for relative in ("tasks.md", "checklists/requirements.md"):
        content = (feature / relative).read_text(encoding="utf-8")
        if re.search(r"^- \[ \]", content, flags=re.MULTILINE):
            errors.append(f"Tamamlanmamış madde var: {(feature / relative).as_posix()}")

    analysis = (feature / "analysis.md").read_text(encoding="utf-8")
    convergence = (feature / "convergence.md").read_text(encoding="utf-8")
    review = (feature / "review.md").read_text(encoding="utf-8")

    if "ÇELİŞKİ: YOK" not in analysis:
        errors.append("Analyze sonucu temiz değil.")
    if "SONUÇ: YAKINSADI" not in convergence:
        errors.append("Implement ve Converge döngüsü tamamlanmamış.")
    if "SONUÇ: İNCELEMEYE HAZIR" not in review:
        errors.append("Bağımsız inceleme sonucu hazır değil.")

    if errors:
        return fail(errors)

    print(f"Gelişim zinciri tamam: {feature.as_posix()}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
