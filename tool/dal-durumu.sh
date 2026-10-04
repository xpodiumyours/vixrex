#!/usr/bin/env bash
#
# dal-durumu.sh — yerel dal envanteri ölçümü
#
# NE İŞE YARAR
# "dallar toparlandı" demeyi ölçülebilir yapar. Her yerel dalı tek tek okur:
# son commit'i kaç gün önce, origin/main'den kaç commit geride, main'de olmayan
# kaç patch'i var (git cherry), hangi durumda. Çıktı bir tablo ve özet satırıdır;
# karar (sil/merge/kapat) kullanıcıya aittir, bu script sadece sayar.
#
# NEDEN VAR (2026-10-03)
# Aynı depoda 71 yerel dal, 46 worktree birikmişti: 35 dal tamamen boş, 31
# worktree mezarlıktı, bir iş 5 ayrı worktree'e dağılmıştı. Kimsenin haberi
# yoktu çünkü hiçbir ölçüm yoktu. Kancasız kural, ölçülmeyen kuraldır —
# AGENTS.md kuralı 14'ün kanca betiği budur.
#
# KULLANIM
#   bash tool/dal-durumu.sh
#
# Eşikler (AGENTS.md kural 14):
#   SESSIZ  >= 3 gün  dokunulmamış  → taşıyıcı dal push zorunluluğu ihlali
#   ESKI    >= 15 gün dokunulmamış  → haftalık ölçümde kapatılır
#   GERIDE  >= 100 commit          → main'den kopmuş, yeniden bağlanması gerekir
#   SILINEBILIR cherry novel = 0   → iş zaten main'dedir; dalın görevi bitmiştir
#
# KAPSAMADIĞI ŞEY
# Silme ve merge işlemi yapmaz. "SILINEBILIR" etiketi bir öneridir; silme
# onayı her zaman Casper'ındır. Merge kapısı ayrıdır: bash tool/merge-hazir.sh

set -uo pipefail

cd "$(git rev-parse --show-toplevel)" || exit 1

SESSIZ_ESIK=3
ESKI_ESIK=15
GERIDE_ESIK=100

git fetch origin main --quiet 2>/dev/null \
  || echo "UYARI: origin/main tazelenemedi; ölçüm yerel kopyaya göre yapıldı."

MAIN_SHA="$(git rev-parse --short origin/main)"
MAIN_TARIH="$(git log -1 --format=%cs origin/main)"
BUGUN="$(date +%s)"

echo "origin/main: $MAIN_SHA ($MAIN_TARIH)"
echo

TOPLAM=0; SESSIZ_SAY=0; ESKI_SAY=0; GERIDE_SAY=0; SILINEBILIR_SAY=0
SATIR="$(mktemp)"

printf '%-40s %-11s %4s %6s %6s  %s\n' "DAL" "SON_COMMIT" "GUN" "GERIDE" "NOVEL" "DURUM"

while IFS=$'\t' read -r ref sha ts tarih; do
  [ "$ref" = "main" ] && continue
  TOPLAM=$((TOPLAM + 1))

  # origin/main...dal → solda main'de yalnız, sağda dalda yalnız
  read -r geride ileri <<< "$(git rev-list --left-right --count "origin/main...$ref" 2>/dev/null)"
  geride="${geride:-0}"; ileri="${ileri:-0}"

  # cherry: main'de eşdeğer patch'i OLMAYAN commit sayısı (farklı SHA olabilir)
  novel="$(git cherry origin/main "$ref" 2>/dev/null | grep -c '^+')"
  novel="${novel:-0}"

  gun=$(( (BUGUN - ${ts:-0}) / 86400 ))

  durum=""
  if [ "$novel" -eq 0 ] && [ "$ileri" -gt 0 ]; then
    durum="SILINEBILIR(patch main'de,farkli SHA)"
    SILINEBILIR_SAY=$((SILINEBILIR_SAY + 1))
  elif [ "$novel" -eq 0 ] && [ "$ileri" -eq 0 ]; then
    durum="SILINEBILIR"
    SILINEBILIR_SAY=$((SILINEBILIR_SAY + 1))
  fi
  [ "$gun" -ge "$SESSIZ_ESIK" ] && { durum="$durum SESSIZ"; SESSIZ_SAY=$((SESSIZ_SAY + 1)); }
  [ "$gun" -ge "$ESKI_ESIK" ] && { durum="$durum ESKI"; ESKI_SAY=$((ESKI_SAY + 1)); }
  [ "$geride" -ge "$GERIDE_ESIK" ] && { durum="$durum GERIDE"; GERIDE_SAY=$((GERIDE_SAY + 1)); }
  [ -z "$durum" ] && durum="tamam"

  printf '%04d\t%-40s %-11s %4d %6d %6d  %s\n' \
    "$gun" "$ref" "$tarih" "$gun" "$geride" "$novel" "$durum" >> "$SATIR"
done < <(git for-each-ref refs/heads --sort=refname \
  --format='%(refname:short)%09%(objectname:short)%09%(committerdate:unix)%09%(committerdate:short)')

sort -n "$SATIR" | cut -f2-
rm -f "$SATIR"

echo
echo "--- Worktree'ler ---"
KIRLI=0; AYRILMIS=0; PRUNE=0
wp=""; wdetached=""; wprunable=""
flush_worktree() {
  [ -z "$wp" ] && return
  etiket=""
  [ -n "$wdetached" ] && { etiket="$etiket AYRILMIS-DAL"; AYRILMIS=$((AYRILMIS + 1)); }
  [ -n "$wprunable" ] && { etiket="$etiket PRUNE($wprunable)"; PRUNE=$((PRUNE + 1)); }
  k="$(git -C "$wp" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
  if [ "${k:-0}" -gt 0 ]; then
    etiket="$etiket KIRLI($k)"
    KIRLI=$((KIRLI + 1))
  fi
  printf '  %-70s %s\n' "$wp" "${etiket:- temiz}"
}
while IFS= read -r line; do
  case "$line" in
    worktree\ *) flush_worktree; wp="${line#worktree }"; wdetached=""; wprunable="";;
    detached) wdetached=1;;
    prunable\ *) wprunable="${line#prunable }";;
    branch\ *) :;;
  esac
done < <(git worktree list --porcelain)
flush_worktree

echo
printf 'TOPLAM %d dal | silinebilir %d | sessiz(>=%dgun) %d | eski(>=%dgun) %d | %d+ geride %d | kirli worktree %d | ayrilmis %d | prune %d\n' \
  "$TOPLAM" "$SILINEBILIR_SAY" "$SESSIZ_ESIK" "$SESSIZ_SAY" \
  "$ESKI_ESIK" "$ESKI_SAY" "$GERIDE_ESIK" "$GERIDE_SAY" \
  "$KIRLI" "$AYRILMIS" "$PRUNE"
echo "Silme/merge onayı Casper'ın; kapı ayrı: bash tool/merge-hazir.sh"
