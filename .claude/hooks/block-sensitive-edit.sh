#!/bin/bash
# Hard-blocks Edit/Write on files where an unapproved change has already
# caused real damage once (see CLAUDE.md "Calisma kurali - ONCE SOR", and
# memory/once-sor-onay-bekle.md: 2026-09-03, ~%40 of a week's tokens burned
# in one session after a silent, unapproved edit here broke prod).
#
# This does NOT try to be tamper-proof against a Claude session with Bash
# access editing this hook or .claude/settings.json — it can't be. What it
# does is make "just edit it and move on" mechanically impossible for a
# well-behaved session: no unlock flag, no bypass token. To touch one of
# these files, either the human makes the edit directly, or the human
# explicitly asks Claude to edit *this hook* to lift the block for that one
# file — a separate, visible action, never bundled into the same turn as
# the underlying fix.

INPUT=$(cat)

if command -v node >/dev/null 2>&1; then
  FILE_PATH=$(printf '%s' "$INPUT" | node -e '
    let d = "";
    process.stdin.on("data", c => d += c);
    process.stdin.on("end", () => {
      try {
        const j = JSON.parse(d);
        process.stdout.write(j?.tool_input?.file_path || "");
      } catch (e) {}
    });
  ')
elif command -v jq >/dev/null 2>&1; then
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path')
else
  echo "BLOCKED: neither node nor jq is available to parse the hook payload, refusing to risk letting a sensitive-file edit through unchecked. Ask the user to install one." >&2
  exit 2
fi

SENSITIVE_PATTERNS=(
  "vixrexNluPipeline\.ts"
  "useOwnerActions\.ts"
  "VitrinProfileView\.tsx"
)

for pattern in "${SENSITIVE_PATTERNS[@]}"; do
  if echo "$FILE_PATH" | grep -qE "$pattern"; then
    echo "BLOCKED: '$FILE_PATH' is on the sensitive-file list (akilli motor / storefront layout — see CLAUDE.md 'ONCE SOR'). Do not edit it. Stop, explain the diagnosis and the proposed fix to Casper in chat, and wait for an explicit yes. Only Casper (or Claude acting on Casper's explicit, separate instruction to edit THIS hook) can lift this block." >&2
    exit 2
  fi
done

exit 0
