#!/bin/bash
#
# Git güvenlik kancası — VixRex
#
# 2026-09-07'de daraltıldı. Eski hâli düz gönderme komutunu ve PR birleştirmeyi
# TAMAMEN engelliyordu; Casper'ın istediği bu değildi ("sormadan merge yapma"
# demişti, "hiç yapma" değil). Sonuç: her PR'da komutlar terminale kopyalanıyor,
# gereksiz tur dönüyordu.
#
# Üç seviye var:
#   1) ENGELLE  — geri dönüşü olmayan, yazılmış işi yok eden komutlar.
#   2) SOR      — main'i değiştiren komutlar; Casper onaylarsa çalışır.
#   3) SERBEST  — geri kalan her şey (özellik dalına gönderme dahil).
#
# NOT: Bu dosyanın kendisi metin içinde yasaklı kalıpları barındırdığı için
# kabuktan `cat > ...` ile yazılamaz — kanca kendi güncellenmesini engeller.
# Düzenlerken dosya yazma aracını kullan.

INPUT=$(cat)
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
  echo "BLOCKED: hook yükünü çözecek node veya jq yok; riske girmemek için reddedildi." >&2
  exit 2
fi

# --- 1) ENGELLE: yazılmış işi yok edenler -----------------------------------
YIKICI=(
  "reset --hard"
  "git clean -fd"
  "git clean -f"
  "git branch -D"
  "git checkout \."
  "git restore \."
  "push .*--force"
  "push .*--delete"
  "push .*:refs/"
)
for kalip in "${YIKICI[@]}"; do
  if echo "$COMMAND" | grep -qE "$kalip"; then
    echo "BLOCKED: '$COMMAND' yikici kalibina uyuyor ('$kalip'). Bu komut kapali; gerekiyorsa Casper kendisi calistirir." >&2
    exit 2
  fi
done

# --- 2) SOR: main'i degistirenler -------------------------------------------
ONAY_GEREKTIREN=(
  "gh pr merge"
  "git merge"
  "push[^|;]*origin[[:space:]]+main"
  "push[^|;]*origin[[:space:]]+HEAD:main"
)
for kalip in "${ONAY_GEREKTIREN[@]}"; do
  if echo "$COMMAND" | grep -qE "$kalip"; then
    printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"main dalini degistiren komut. Onayin gerekiyor."}}'
    exit 0
  fi
done

exit 0
