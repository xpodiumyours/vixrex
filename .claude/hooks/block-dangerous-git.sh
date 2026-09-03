#!/bin/bash

INPUT=$(cat)
# jq is not guaranteed to be installed (it isn't, on this machine) — use node,
# which this repo already depends on, to pull tool_input.command out of the
# hook's JSON payload instead. Falling back to jq if node is ever missing.
if command -v node >/dev/null 2>&1; then
  COMMAND=$(printf '%s' "$INPUT" | node -e '
    let d = "";
    process.stdin.on("data", c => d += c);
    process.stdin.on("end", () => {
      try {
        const j = JSON.parse(d);
        process.stdout.write(j?.tool_input?.command || "");
      } catch (e) {}
    });
  ')
elif command -v jq >/dev/null 2>&1; then
  COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command')
else
  # Neither available — fail closed on git/gh commands rather than silently
  # letting everything through unchecked.
  echo "BLOCKED: neither node nor jq is available to parse the hook payload, refusing to risk letting a dangerous command through unchecked. Ask the user to install one." >&2
  exit 2
fi

DANGEROUS_PATTERNS=(
  "git push"
  "git reset --hard"
  "git clean -fd"
  "git clean -f"
  "git branch -D"
  "git checkout \."
  "git restore \."
  "push --force"
  "reset --hard"
  "gh pr merge"
)

for pattern in "${DANGEROUS_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qE "$pattern"; then
    echo "BLOCKED: '$COMMAND' matches dangerous pattern '$pattern'. The user has prevented you from doing this." >&2
    exit 2
  fi
done

exit 0
