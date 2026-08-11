#!/usr/bin/env python3
"""VixRex ajan sistemi sağlık denetimi."""

from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path


ADAPTERS = (
    "CLAUDE.md",
    "GEMINI.md",
    ".github/copilot-instructions.md",
    ".cursor/rules",
)

EXPLICIT_ONLY_SKILLS = (
    "ask-matt",
    "implement",
    "to-spec",
    "to-tickets",
    "handoff",
    "wayfinder",
)

REQUIRED_GITHUB_LABELS = (
    "needs-triage",
    "needs-info",
    "ready-for-agent",
    "ready-for-human",
    "wontfix",
    "wayfinder:map",
    "wayfinder:research",
    "wayfinder:prototype",
    "wayfinder:grilling",
    "wayfinder:task",
)

ROUTE_SECTION = "## Değişiklik riskine göre rota"
WIKILINK_PATTERN = re.compile(r"\[\[([^\]|#]+)")
SKILL_PATTERN = re.compile(r"`([a-z0-9][a-z0-9-]*)`")

LOW_CREDIT_RISK_LABELS = ("hafif", "normal", "zor bug", "yüksek risk")
LOW_CREDIT_SHARED_TOKENS = (
    "yüksek risk kazanır",
    "aynı skill ikinci kez çalışmaz",
    "bir oturum yalnız bir issue/pr üzerinde çalışır",
)



def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--root",
        type=Path,
        default=Path(__file__).resolve().parents[2],
        help="Denetlenecek depo veya fixture kökü",
    )
    parser.add_argument(
        "--github-repo",
        metavar="OWNER/REPO",
        help="GitHub etiketlerini gh CLI ile doğrula",
    )
    parser.add_argument(
        "--require-protection",
        action="store_true",
        help="main branch korumasında verify-protected-tests bağlamını da zorunlu tut",
    )
    return parser.parse_args()


def read_text(path: Path, errors: list[str], label: str | None = None) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except FileNotFoundError:
        errors.append(f"{label or path.name} bulunamadı: {path}")
    except (OSError, UnicodeError) as exc:
        errors.append(f"{label or path.name} okunamadı: {exc}")
    return ""


def verify_bootstrap_and_adapters(root: Path, errors: list[str]) -> None:
    agents = read_text(root / "AGENTS.md", errors, "AGENTS.md")
    for token in (
        "VIXREX_RULES.md",
        ".agents/skills/vixrex-router/SKILL.md",
        "GitHub issue",
    ):
        if agents and token.casefold() not in agents.casefold():
            errors.append(f"AGENTS.md başlangıcında eksik sözleşme: {token}")

    for relative in ADAPTERS:
        content = read_text(root / relative, errors, relative)
        if not content:
            continue
        if "AGENTS.md" not in content:
            errors.append(f"{relative}, tek başlangıç olan AGENTS.md dosyasına yönlendirmiyor")
        nonempty_lines = [line for line in content.splitlines() if line.strip()]
        if len(nonempty_lines) > 12:
            errors.append(f"{relative} ince adaptör değil; {len(nonempty_lines)} dolu satır içeriyor")


def verify_router(root: Path, errors: list[str]) -> None:
    router_dir = root / ".agents" / "skills" / "vixrex-router"
    skill = read_text(router_dir / "SKILL.md", errors, "vixrex-router/SKILL.md")
    metadata = read_text(
        router_dir / "agents" / "openai.yaml",
        errors,
        "vixrex-router/agents/openai.yaml",
    )

    if skill and re.search(r"disable-model-invocation\s*:\s*true", skill, re.I):
        errors.append("vixrex-router model çağrısına kapatılmış")
    if metadata and not re.search(
        r"allow_implicit_invocation\s*:\s*true", metadata, re.I
    ):
        errors.append("vixrex-router için allow_implicit_invocation: true olmalı")

    if skill:
        folded = skill.casefold()
        for token in (
            "salt-okunur",
            "kullanıcı yetkisini genişletmez",
            "commit",
            "push",
            "pr",
            "merge",
            "deploy",
        ):
            if token not in folded:
                errors.append(f"vixrex-router güvenlik sözleşmesinde eksik ifade: {token}")


def route_skill_names(route_doc: str) -> set[str]:
    if ROUTE_SECTION not in route_doc:
        return set()
    section = route_doc.split(ROUTE_SECTION, 1)[1]
    section = re.split(r"\n##\s+", section, maxsplit=1)[0]
    names: set[str] = set()
    for line in section.splitlines():
        if not line.lstrip().startswith("|"):
            continue
        names.update(SKILL_PATTERN.findall(line))
    return names


def verify_route_skills(root: Path, errors: list[str]) -> None:
    route_path = root / "docs" / "Ajan Calisma Akislari.md"
    route_doc = read_text(route_path, errors, "docs/Ajan Calisma Akislari.md")
    if not route_doc:
        return

    names = route_skill_names(route_doc)
    if not names:
        errors.append("Ajan Calisma Akislari içinde çözümlenebilir skill rotası yok")
        return

    for name in sorted(names):
        skill_path = root / ".agents" / "skills" / name / "SKILL.md"
        if not skill_path.is_file():
            errors.append(f"Rota tablosundaki skill bulunamadı: {name}")


def require_contract_tokens(
    content: str,
    tokens: tuple[str, ...],
    errors: list[str],
    label: str,
) -> None:
    folded = content.casefold()
    for token in tokens:
        if token.casefold() not in folded:
            errors.append(f"{label} düşük kredi sözleşmesinde eksik ifade: {token}")


def verify_low_credit_contract(root: Path, errors: list[str]) -> None:
    agents = read_text(root / "AGENTS.md", errors, "AGENTS.md")
    router = read_text(
        root / ".agents" / "skills" / "vixrex-router" / "SKILL.md",
        errors,
        "vixrex-router/SKILL.md",
    )
    routes = read_text(
        root / "docs" / "Ajan Calisma Akislari.md",
        errors,
        "docs/Ajan Calisma Akislari.md",
    )
    implement = read_text(
        root / ".agents" / "skills" / "implement" / "SKILL.md",
        errors,
        "implement/SKILL.md",
    )

    for label, source in (
        ("AGENTS.md", agents),
        ("vixrex-router/SKILL.md", router),
        ("docs/Ajan Calisma Akislari.md", routes),
    ):
        if source:
            require_contract_tokens(source, LOW_CREDIT_RISK_LABELS, errors, label)

    for label, source in (
        ("vixrex-router/SKILL.md", router),
        ("docs/Ajan Calisma Akislari.md", routes),
    ):
        if source:
            require_contract_tokens(source, LOW_CREDIT_SHARED_TOKENS, errors, label)

    if agents:
        require_contract_tokens(
            agents,
            (
                "yüksek risk kazanır",
                "aynı skill ikinci kez çalışmaz",
                "bir oturum yalnız bir issue/pr üzerinde çalışır",
                "etkilenen yüzeyin full suite’i en fazla bir kez",
            ),
            errors,
            "AGENTS.md",
        )
        if "commit önerilmeden önce | `code-review`" in agents.casefold():
            errors.append("AGENTS.md her commit için koşulsuz code-review zorluyor")

    if implement:
        require_contract_tokens(
            implement,
            (
                "one issue/pr only",
                "do not call the same skill twice",
                "full suite at most once",
                "existing branch",
            ),
            errors,
            "implement/SKILL.md",
        )


def verify_explicit_only_skills(root: Path, errors: list[str]) -> None:
    for name in EXPLICIT_ONLY_SKILLS:
        metadata_path = root / ".agents" / "skills" / name / "agents" / "openai.yaml"
        metadata = read_text(metadata_path, errors, f"{name}/agents/openai.yaml")
        if metadata and not re.search(
            r"allow_implicit_invocation\s*:\s*false", metadata, re.I
        ):
            errors.append(f"{name} yalnız açık çağrılmalı: allow_implicit_invocation: false eksik")


def verify_task_sources(root: Path, errors: list[str]) -> None:
    root_plan = root / "implementation_plan.md"
    if root_plan.exists():
        errors.append("Kök implementation_plan.md yasak; aktif plan GitHub Issue olmalı")

    docs = root / "docs"
    if not docs.is_dir():
        errors.append("docs klasörü bulunamadı")
        return
    for prompt in sorted(docs.rglob("prompt*.md")):
        relative = prompt.relative_to(root)
        if "arsiv" not in {part.casefold() for part in relative.parts}:
            errors.append(f"Aktif prompt belgesi GitHub Issue'ya taşınmalı: {relative.as_posix()}")


def ignored(relative: Path, filters: list[str]) -> bool:
    posix = relative.as_posix().strip("/")
    parts = {part.casefold() for part in relative.parts}
    for raw_filter in filters:
        normalized = raw_filter.replace("\\", "/").strip("/").casefold()
        if not normalized:
            continue
        if "/" not in normalized and normalized in parts:
            return True
        if posix.casefold() == normalized or posix.casefold().startswith(normalized + "/"):
            return True
    return False


def verify_start_links(root: Path, errors: list[str]) -> None:
    start_path = root / "docs" / "Vixrex Baslangic.md"
    start = read_text(start_path, errors, "docs/Vixrex Baslangic.md")
    app_json = read_text(root / ".obsidian" / "app.json", errors, ".obsidian/app.json")
    if not start or not app_json:
        return

    try:
        settings = json.loads(app_json)
    except json.JSONDecodeError as exc:
        errors.append(f".obsidian/app.json geçerli JSON değil: {exc}")
        return
    filters = settings.get("userIgnoreFilters", [])
    if not isinstance(filters, list) or not all(isinstance(item, str) for item in filters):
        errors.append(".obsidian/app.json userIgnoreFilters bir metin listesi olmalı")
        return

    by_stem: dict[str, list[Path]] = {}
    for markdown in root.rglob("*.md"):
        relative = markdown.relative_to(root)
        if ignored(relative, filters):
            continue
        by_stem.setdefault(markdown.stem.casefold(), []).append(relative)

    for raw_target in WIKILINK_PATTERN.findall(start):
        target = raw_target.strip()
        stem = Path(target).stem.casefold()
        matches = by_stem.get(stem, [])
        if not matches:
            errors.append(f"Başlangıç wikilink hedefi bulunamadı: {target}")
        elif len(matches) > 1:
            rendered = ", ".join(path.as_posix() for path in matches)
            errors.append(f"Başlangıç wikilink hedefi belirsiz: {target} -> {rendered}")


def verify_static(root: Path) -> list[str]:
    errors: list[str] = []
    verify_bootstrap_and_adapters(root, errors)
    verify_router(root, errors)
    verify_route_skills(root, errors)
    verify_low_credit_contract(root, errors)
    verify_explicit_only_skills(root, errors)
    verify_task_sources(root, errors)
    verify_start_links(root, errors)
    return errors


def run_gh(arguments: list[str], errors: list[str], purpose: str) -> str:
    executable = shutil.which("gh")
    if not executable:
        errors.append(f"GitHub {purpose} kontrolü için gh CLI bulunamadı")
        return ""
    try:
        result = subprocess.run(
            [executable, *arguments],
            capture_output=True,
            text=True,
            check=False,
        )
    except OSError as exc:
        errors.append(f"GitHub {purpose} kontrolü başlatılamadı: {exc}")
        return ""
    if result.returncode != 0:
        detail = result.stderr.strip() or result.stdout.strip() or "bilinmeyen hata"
        errors.append(f"GitHub {purpose} kontrolü başarısız: {detail}")
        return ""
    return result.stdout


def verify_github(repo: str, require_protection: bool, errors: list[str]) -> None:
    label_output = run_gh(
        ["label", "list", "--repo", repo, "--limit", "200", "--json", "name"],
        errors,
        "etiket",
    )
    if label_output:
        try:
            payload = json.loads(label_output)
            labels = {
                item["name"]
                for item in payload
                if isinstance(item, dict) and isinstance(item.get("name"), str)
            }
        except (json.JSONDecodeError, TypeError) as exc:
            errors.append(f"GitHub etiket çıktısı okunamadı: {exc}")
        else:
            missing = [name for name in REQUIRED_GITHUB_LABELS if name not in labels]
            if missing:
                errors.append(f"GitHub etiketleri eksik: {', '.join(missing)}")

    if not require_protection:
        return

    protection_output = run_gh(
        [
            "api",
            f"repos/{repo}/branches/main/protection/required_status_checks",
        ],
        errors,
        "branch protection",
    )
    if not protection_output:
        return
    try:
        payload = json.loads(protection_output)
    except json.JSONDecodeError as exc:
        errors.append(f"GitHub branch protection çıktısı okunamadı: {exc}")
        return

    contexts = {
        context
        for context in payload.get("contexts", [])
        if isinstance(context, str)
    }
    for check in payload.get("checks", []):
        if isinstance(check, dict) and isinstance(check.get("context"), str):
            contexts.add(check["context"])
    if not any(
        context == "verify-protected-tests"
        or context.endswith("/ verify-protected-tests")
        for context in contexts
    ):
        errors.append(
            "main branch protection içinde verify-protected-tests zorunlu değil"
        )


def main() -> int:
    args = parse_args()
    root = args.root.resolve()
    if not root.is_dir():
        print(f"[HATA] Kök klasör bulunamadı: {root}")
        return 1

    errors = verify_static(root)
    if args.require_protection and not args.github_repo:
        errors.append("--require-protection için --github-repo zorunludur")
    elif args.github_repo:
        verify_github(args.github_repo, args.require_protection, errors)
    if errors:
        for error in errors:
            print(f"[HATA] {error}")
        return 1

    print(f"[OK] Ajan sistemi doğrulandı: {root}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
