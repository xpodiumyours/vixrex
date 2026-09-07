#!/usr/bin/env python3
"""Classify changed repository paths for CI and Vercel build routing."""

from __future__ import annotations

import argparse
import os
import subprocess
import sys
from pathlib import Path


SURFACES = ("flutter", "schema", "public_web")

CI_CONTROL_PATHS = {
    ".github/workflows/ci.yml",
    ".github/workflows/parity.yml",
    ".github/workflows/teslimat.yml",
    ".github/scripts/changed_surfaces.py",
    ".github/scripts/parity_guard.py",
    ".github/scripts/parity_delivery_guard.py",
    ".github/scripts/teslimat.py",
    ".github/scripts/tests/test_changed_surfaces.py",
    ".github/scripts/tests/test_parity_guard.py",
    ".github/parity/contracts.json",
    "public_web/e2e/flutter-next-parity.spec.ts",
}

NEUTRAL_PREFIXES = (
    ".agents/",
    ".cursor/",
    ".github/",
    ".obsidian/",
    ".scratch/",
    "design_mockups/",
    "docs/",
    "sablonlar/",
    "scratch/",
)

NEUTRAL_FILES = {
    ".gitattributes",
    ".gitignore",
    "AGENTS.md",
    "CLAUDE.md",
    "CONTEXT.md",
    "GEMINI.md",
    "LICENSE",
    "README.md",
    "VIXREX_RULES.md",
}

FLUTTER_PREFIXES = (
    "android/",
    "assets/",
    "integration_test/",
    "ios/",
    "lib/",
    "linux/",
    "macos/",
    "test/",
    "web/",
    "windows/",
)

FLUTTER_FILES = {
    "analysis_options.yaml",
    "dart_defines.example.json",
    "l10n.yaml",
    "pubspec.lock",
    "pubspec.yaml",
    "vercel-build.sh",
    "vercel.json",
}

SCHEMA_FILES = {
    "lib/config/vitrin_alanlari.g.dart",
    "public_web/src/lib/vitrinFieldSchema.ts",
    "shared/vitrin_alanlari.json",
    "tool/alan_semasi_uret.dart",
    "tool/sema_disa_aktar.ts",
}

SCHEMA_DEPENDENCIES = {
    "pubspec.lock",
    "pubspec.yaml",
    "public_web/package-lock.json",
    "public_web/package.json",
}

# Flutter Web'in ürün/akış referansı olduğu ve Next.js tarafının onu birebir
# izlemesi gereken yüzeyler. Bu yollar değiştiğinde yalnız Next testleri değil,
# Flutter oracle testleri de zorunlu olarak çalışır.
PARITY_TARGET_PATHS = {
    "public_web/src/components/landing/LandingApkAssistant.tsx",
}


def normalize(path: str) -> str:
    return path.replace("\\", "/").removeprefix("./").strip("/")


def is_parity_target(path: str) -> bool:
    return normalize(path) in PARITY_TARGET_PATHS


def classify_paths(paths: list[str]) -> dict[str, bool]:
    """Return affected surfaces; unknown production paths conservatively affect all."""
    result = {surface: False for surface in SURFACES}

    for raw_path in paths:
        path = normalize(raw_path)
        if not path:
            continue

        if path in CI_CONTROL_PATHS or path.startswith("supabase/"):
            return {surface: True for surface in SURFACES}

        matched = False

        if is_parity_target(path):
            # Next.js'in Flutter referansına bağlı yüzeyinde değişiklik varsa
            # Flutter testlerini atlamak yasak: iki yüzey birlikte ölçülür.
            result["flutter"] = True
            result["public_web"] = True
            matched = True

        if path.startswith(FLUTTER_PREFIXES) or path in FLUTTER_FILES:
            result["flutter"] = True
            matched = True

        if path.startswith("public_web/"):
            result["public_web"] = True
            matched = True

        if path in SCHEMA_FILES or path in SCHEMA_DEPENDENCIES:
            result["schema"] = True
            matched = True

        if path.startswith(("shared/", "tool/")):
            return {surface: True for surface in SURFACES}

        if matched:
            continue

        if (
            path in NEUTRAL_FILES
            or path.endswith(".md")
            or path.startswith(NEUTRAL_PREFIXES)
        ):
            continue

        return {surface: True for surface in SURFACES}

    return result


def parity_affected(paths: list[str]) -> bool:
    return any(is_parity_target(path) for path in paths)


def repository_root() -> Path:
    result = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        capture_output=True,
        text=True,
        check=True,
    )
    return Path(result.stdout.strip())


def changed_files(base: str, head: str) -> list[str]:
    if not base or set(base) == {"0"}:
        raise ValueError("geçerli bir base SHA bulunamadı")
    root = repository_root()
    result = subprocess.run(
        ["git", "diff", "--name-only", base, head, "--"],
        cwd=root,
        capture_output=True,
        text=True,
        check=True,
    )
    return [line for line in result.stdout.splitlines() if line.strip()]


def print_ci_outputs(base: str, head: str) -> int:
    try:
        paths = changed_files(base, head)
        affected = classify_paths(paths)
        parity = parity_affected(paths)
    except (OSError, subprocess.CalledProcessError, ValueError) as exc:
        print(
            f"::warning::Yüzey sınıflandırması başarısız; tüm işler çalışacak: {exc}",
            file=sys.stderr,
        )
        affected = {surface: True for surface in SURFACES}
        parity = True

    for surface in SURFACES:
        print(f"{surface}={'true' if affected[surface] else 'false'}")
    print(f"parity={'true' if parity else 'false'}")
    return 0


def vercel_ignore_exit(surface: str, paths: list[str]) -> int:
    """Vercel contract: 0 skips the build; 1 continues it."""
    return 1 if classify_paths(paths)[surface] else 0


def check_vercel(surface: str) -> int:
    base = os.environ.get("VERCEL_GIT_PREVIOUS_SHA", "HEAD^1")
    head = os.environ.get("VERCEL_GIT_COMMIT_SHA", "HEAD")
    try:
        paths = changed_files(base, head)
    except (OSError, subprocess.CalledProcessError, ValueError) as exc:
        print(
            f"Yüzey sınıflandırması başarısız; build güvenli biçimde çalışacak: {exc}",
            file=sys.stderr,
        )
        return 1

    exit_code = vercel_ignore_exit(surface, paths)
    action = "build" if exit_code else "skip"
    print(f"Vercel yüzeyi: {surface}; karar: {action}")
    return exit_code


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base", help="CI diff başlangıç SHA'sı")
    parser.add_argument("--head", default="HEAD", help="CI diff bitiş SHA'sı")
    parser.add_argument("--vercel-surface", choices=("flutter", "public_web"))
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.vercel_surface:
        return check_vercel(args.vercel_surface)
    if not args.base:
        print("--base veya --vercel-surface zorunludur", file=sys.stderr)
        return 2
    return print_ci_outputs(args.base, args.head)


if __name__ == "__main__":
    raise SystemExit(main())
