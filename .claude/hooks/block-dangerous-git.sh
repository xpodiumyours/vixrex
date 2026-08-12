#!/bin/bash
# VIXREX_RULES.md §10 "Git ve Deploy" kararını kod seviyesinde uygular:
# "Force push ve `git reset --hard` kullanılmaz."
#
# Sadece geri dönüşü olmayan/veri kaybettiren komutlar engellenir. Sıradan
# `git push` engellenmez — VIXREX_RULES zaten push'u "kullanıcının açık
# isteğiyle" şartına bağlıyor ve bu proje günlük olarak PR'larla çalışıyor;
# her push'u burada da bloklamak normal akışı durdurur, yalnız gerçekten
# tehlikeli olanı durdurmak amaç.
#
# 2026-08-12: bu depoda ajanların kurallara uyup uymadığını kullanıcı kod
# okuyarak fark edemiyor (Casper kodu okumuyor, konuşarak yönetiyor) — bu
# hook en azından geri dönüşü olmayan komutları teknik olarak imkansız
# kılıyor, "ajan okur uyar" varsayımına bırakmıyor.

INPUT=$(cat)

# jq bu makinede (Casper'ın Windows/Git Bash ortamı, doğrulandı 2026-08-12)
# kurulu değil — jq'ya bağlı kalırsak ayrıştırma sessizce başarısız olur ve
# COMMAND boş kalıp her şeye izin verilir (tam da önlemeye çalıştığımız şey).
# Bu yüzden python/node/regex ile aşamalı çözülüyor, jq'ya bağımlı değil.
extract_command() {
  if command -v python >/dev/null 2>&1; then
    printf '%s' "$INPUT" | python -c "import sys,json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('command', ''))
except Exception:
    print('')" 2>/dev/null
  elif command -v python3 >/dev/null 2>&1; then
    printf '%s' "$INPUT" | python3 -c "import sys,json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('command', ''))
except Exception:
    print('')" 2>/dev/null
  elif command -v node >/dev/null 2>&1; then
    printf '%s' "$INPUT" | node -e "
let d='';
process.stdin.on('data', c => d += c);
process.stdin.on('end', () => {
  try {
    const j = JSON.parse(d);
    console.log((j.tool_input && j.tool_input.command) || '');
  } catch (e) {
    console.log('');
  }
});" 2>/dev/null
  else
    # Son çare: jq/python/node hiçbiri yoksa bile basit regex ile dene —
    # tehlikeli komut hiç kontrol edilmeden geçmesin.
    printf '%s' "$INPUT" \
      | grep -oE '"command"[[:space:]]*:[[:space:]]*"([^"\\]|\\.)*"' \
      | head -1 \
      | sed -E 's/.*"command"[[:space:]]*:[[:space:]]*"(.*)"/\1/'
  fi
}

COMMAND=$(extract_command)

if [ -z "$COMMAND" ]; then
  exit 0
fi

DANGEROUS_PATTERNS=(
  "push[^&|]*--force"
  "push[^&|]*-f\b"
  "reset[[:space:]]+--hard"
  "clean[[:space:]]+-fd"
  "clean[[:space:]]+-f\b"
  "branch[[:space:]]+-D"
  "checkout[[:space:]]+\."
  "restore[[:space:]]+\."
)

for pattern in "${DANGEROUS_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qE "$pattern"; then
    echo "BLOCKED: '$COMMAND' tehlikeli kalıpla eşleşti: '$pattern'. Bu proje force push, reset --hard, clean -f, branch -D ve checkout/restore . komutlarını yasaklıyor (VIXREX_RULES.md §10). Kullanıcının açık isteği ve onayı olmadan bu komut çalıştırılamaz." >&2
    exit 2
  fi
done

exit 0
