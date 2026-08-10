#!/usr/bin/env python3
"""Bir VixRex görevi için salt-okunur, SHA bağlı başlangıç kanıtı üretir."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from vixrex_evidence_core import (
    EvidenceError,
    EvidenceRequest,
    collect_snapshot,
)
from vixrex_evidence_analysis import render_summary
from vixrex_evidence_runtime import (
    EvidenceRuntimeError,
    SubprocessRunner,
    write_artifacts,
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--issue", type=int, required=True, help="GitHub Issue numarası")
    parser.add_argument("--base", default="origin/main", help="Diff ve merge-base referansı")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        manifest = collect_snapshot(
            EvidenceRequest(
            root=Path.cwd(),
            issue_number=args.issue,
            base_ref=args.base,
            ),
            SubprocessRunner(),
        )
        manifest_path, summary_path = write_artifacts(
            root=Path(manifest["worktree"]["path"]),
            worktree_id=manifest["worktree"]["id"],
            head_sha=manifest["git"]["head_sha"],
            manifest=manifest,
            summary=render_summary(manifest),
        )
    except (EvidenceError, EvidenceRuntimeError, OSError) as exc:
        print(f"[HATA] Kanıt manifesti üretilemedi: {exc}")
        return 1

    result = manifest["result"]
    print(
        f"[REPORT-ONLY][{result['status'].upper()}] "
        f"enforce edilse exit {result['would_exit']} olurdu"
    )
    for item in manifest["findings"]:
        prefix = "BİLGİ" if item["severity"] == "info" else "UYARI"
        print(f"[{prefix}] {item['code']}: {item['detail']}")
    print(f"[ARTEFAKT] Kanıt manifesti: {manifest_path}")
    print(f"[ARTEFAKT] Okunabilir özet: {summary_path}")
    return int(result["effective_exit"])


if __name__ == "__main__":
    sys.exit(main())
