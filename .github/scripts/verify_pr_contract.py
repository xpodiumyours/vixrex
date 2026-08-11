#!/usr/bin/env python3
"""GitHub pull request gövdesinin VixRex kanıt sözleşmesine uyduğunu doğrular."""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from pathlib import Path


REQUIRED_SECTIONS = (
    "Bağlı Issue",
    "Kullanılan Skill Akışı",
    "Kırmızı Kanıt",
    "Yeşil Kanıt",
    "Kapsam Dışı",
    "Geri Dönüş",
)

HEADING_PATTERN = re.compile(r"^##\s+(.+?)\s*$", re.MULTILINE)
HTML_COMMENT_PATTERN = re.compile(r"<!--.*?-->", re.DOTALL)
ISSUE_LINK_PATTERN = re.compile(
    r"\b(?:fix(?:e[sd])?|close[sd]?|resolve[sd]?)\s+#\d+\b",
    re.IGNORECASE,
)
PLACEHOLDER_PATTERN = re.compile(
    r"\b(?:TODO|TBD|DOLDUR|PLACEHOLDER|SONRA\s+EKLENECEK)\b|<[^>]+>",
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--event",
        type=Path,
        help="GitHub pull_request event JSON yolu; yoksa GITHUB_EVENT_PATH kullanılır",
    )
    return parser.parse_args()


def normalize_heading(value: str) -> str:
    return " ".join(value.split()).casefold()


def parse_sections(body: str) -> tuple[dict[str, str], list[str]]:
    matches = list(HEADING_PATTERN.finditer(body))
    sections: dict[str, str] = {}
    duplicates: list[str] = []
    for index, match in enumerate(matches):
        heading = normalize_heading(match.group(1))
        end = matches[index + 1].start() if index + 1 < len(matches) else len(body)
        content = body[match.end() : end].strip()
        if heading in sections:
            duplicates.append(match.group(1).strip())
        else:
            sections[heading] = content
    return sections, duplicates


def meaningful(content: str) -> str:
    without_comments = HTML_COMMENT_PATTERN.sub("", content)
    lines = [
        line.strip()
        for line in without_comments.splitlines()
        if line.strip() and line.strip() not in {"-", "*", "[ ]", "- [ ]"}
    ]
    return "\n".join(lines).strip()


def verify_body(body: str) -> list[str]:
    errors: list[str] = []
    sections, duplicates = parse_sections(body)
    for duplicate in duplicates:
        errors.append(f"Başlık birden fazla kez kullanılmış: {duplicate}")

    values: dict[str, str] = {}
    for heading in REQUIRED_SECTIONS:
        key = normalize_heading(heading)
        if key not in sections:
            errors.append(f"Zorunlu PR başlığı eksik: {heading}")
            continue
        value = meaningful(sections[key])
        values[heading] = value
        if not value or PLACEHOLDER_PATTERN.search(value):
            errors.append(f"{heading} alanı boş veya placeholder bırakılamaz")

    issue = values.get("Bağlı Issue", "")
    if issue and not ISSUE_LINK_PATTERN.search(issue):
        errors.append("Bağlı Issue alanı `Fixes #<issue>` biçiminde gerçek bağlantı içermeli")

    skill_flow = values.get("Kullanılan Skill Akışı", "")
    if skill_flow and "vixrex-router" not in skill_flow.casefold():
        errors.append("Kullanılan Skill Akışı vixrex-router ile başlayan gerçek rotayı içermeli")

    return errors


def event_path_from(args: argparse.Namespace) -> Path | None:
    if args.event:
        return args.event
    value = os.environ.get("GITHUB_EVENT_PATH")
    return Path(value) if value else None


def main() -> int:
    args = parse_args()
    event_path = event_path_from(args)
    if event_path is None:
        print("[HATA] --event veya GITHUB_EVENT_PATH gerekli")
        return 1

    try:
        event = json.loads(event_path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        print(f"[HATA] PR event dosyası bulunamadı: {event_path}")
        return 1
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        print(f"[HATA] PR event dosyası okunamadı: {exc}")
        return 1

    pull_request = event.get("pull_request")
    if not isinstance(pull_request, dict):
        print("[HATA] Event içinde pull_request nesnesi yok")
        return 1
    body = pull_request.get("body")
    if not isinstance(body, str) or not body.strip():
        print("[HATA] Pull request gövdesi boş")
        return 1

    errors = verify_body(body)
    if errors:
        for error in errors:
            print(f"[HATA] {error}")
        return 1

    print("[OK] PR sözleşmesi doğrulandı")
    return 0


if __name__ == "__main__":
    sys.exit(main())
