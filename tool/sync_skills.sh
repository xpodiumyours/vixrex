#!/usr/bin/env bash
# sync_skills — skill aynalayıcı
# KANONİK: .agents/skills/ (Codex, Cursor, Freebuff ve diger Agent Skills aracı okur)
# AYNA:    .claude/skills/ (Claude Code YALNIZCA bu dizini okur)
# Kullanım: bash tool/sync_skills
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/.agents/skills"
DST="$ROOT/.claude/skills"
mkdir -p "$DST"
for existing in "$DST"/*/; do
  name="$(basename "$existing")"
  if [ ! -d "$SRC/$name" ]; then
    echo "AYNA temizligi: $name"
    rm -rf "$existing"
  fi
done
for skill in "$SRC"/*/; do
  name="$(basename "$skill")"
  rm -rf "$DST/$name"
  cp -r "$skill" "$DST/$name"
done
echo "Senkron tamam."
