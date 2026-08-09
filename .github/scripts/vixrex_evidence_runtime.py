"""Evidence CLI için subprocess adapterı ve çakışmasız artefakt yazıcısı."""

from __future__ import annotations

import json
import os
import secrets
import shutil
import subprocess
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


class EvidenceRuntimeError(RuntimeError):
    """Dış komut veya artefakt yazımı güvenilir biçimde tamamlanamadı."""


class SubprocessRunner:
    """Git ve GitHub CLI için shell kullanmayan production adapterı."""

    def text(self, command: list[str], *, cwd: Path) -> str:
        raw = self._run(command, cwd=cwd)
        return raw.decode("utf-8", errors="surrogateescape").rstrip("\r\n")

    def bytes(self, command: list[str], *, cwd: Path) -> bytes:
        return self._run(command, cwd=cwd)

    def _run(self, command: list[str], *, cwd: Path) -> bytes:
        executable = shutil.which(command[0])
        if executable is None:
            raise EvidenceRuntimeError(f"Komut bulunamadı: {command[0]}")
        environment = os.environ.copy()
        if command[0] == "git":
            environment["GIT_OPTIONAL_LOCKS"] = "0"
        try:
            result = subprocess.run(
                [executable, *command[1:]],
                cwd=cwd,
                capture_output=True,
                check=False,
                env=environment,
            )
        except OSError as exc:
            raise EvidenceRuntimeError(f"Komut başlatılamadı: {command[0]}") from exc
        if result.returncode != 0:
            # stderr kullanıcı/remote kontrollü içerik veya secret taşıyabilir.
            raise EvidenceRuntimeError(
                f"Komut başarısız: {command[0]} (exit {result.returncode})"
            )
        return result.stdout


def write_artifacts(
    *,
    root: Path,
    worktree_id: str,
    head_sha: str,
    manifest: dict[str, Any],
    summary: str,
) -> tuple[Path, Path]:
    """JSON ve özeti repo içindeki benzersiz dizine atomik olarak yayınlar."""

    root = root.resolve()
    parent = (root / ".vixrex-dev" / worktree_id).resolve()
    try:
        parent.relative_to(root)
    except ValueError as exc:
        raise EvidenceRuntimeError("Artefakt yolu repo dışına çıkamaz") from exc
    parent.mkdir(parents=True, exist_ok=True)

    timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S.%fZ")
    run_id = f"{timestamp}-{head_sha[:8]}-{secrets.token_hex(4)}"
    temporary = parent / f".tmp-{run_id}"
    destination = parent / run_id
    try:
        temporary.mkdir(exist_ok=False)
        manifest_temp = temporary / "evidence.json"
        summary_temp = temporary / "summary.md"
        manifest_temp.write_text(
            json.dumps(manifest, ensure_ascii=True, indent=2) + "\n",
            encoding="ascii",
        )
        summary_temp.write_bytes(summary.encode("utf-8", errors="backslashreplace"))
        temporary.rename(destination)
    except OSError as exc:
        raise EvidenceRuntimeError("Kanıt artefaktları atomik yayımlanamadı") from exc
    return destination / "evidence.json", destination / "summary.md"


__all__ = ["EvidenceRuntimeError", "SubprocessRunner", "write_artifacts"]
