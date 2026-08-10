"""VixRex yerel geliştirme çalışma zamanı — sahip modül.

Issue #83 (T1): ajanın izole bir yerel ortamda, tek komutla, benzersiz bir
vitrin fixture'ıyla çalışabilmesini sağlayan araç. Dış arayüz `up`, `status`,
`down` fiillerinden ibarettir; Docker/Supabase CLI/dosya sistemi ayrıntıları
bu modülün içinde kalır.

Bu dosya T1'in ilk dilimini taşır: `assert_local_target`. Geri kalan
`up`/`status`/`down` davranışı sonraki kırmızı→yeşil dilimlerde eklenir —
henüz burada yoktur, spekülatif iskelet bilerek yazılmadı.
"""

from __future__ import annotations

from typing import Mapping


class RemoteTargetError(RuntimeError):
    """Ortamda uzak/production Supabase hedefine işaret eden değişken var."""


# Bu değişkenlerden biri ortamda TANIMLI ve BOŞ DEĞİLSE, çağıran taraf
# `supabase` CLI'ı linked/remote modda kullanmayı düşünüyor demektir —
# bu araç yalnız `--workdir` ile açıkça izole edilmiş yerel yığına dokunur.
_REMOTE_ENV_MARKERS = (
    "SUPABASE_ACCESS_TOKEN",
    "SUPABASE_DB_URL",
    "SUPABASE_PROJECT_REF",
    "SUPABASE_SERVICE_ROLE_KEY",
)


def assert_local_target(env: Mapping[str, str]) -> None:
    """Ortam uzak bir Supabase hedefine işaret ediyorsa `RemoteTargetError` fırlatır.

    Hiçbir süreç başlatılmadan, `up()`'ın ilk adımı olarak çağrılır.
    Hata mesajı yalnız değişken ADINI taşır — değerini asla (VIXREX_RULES §3.7).
    """
    found = [name for name in _REMOTE_ENV_MARKERS if env.get(name)]
    if found:
        raise RemoteTargetError(
            "Uzak/production Supabase hedefi görüldü: "
            + ", ".join(found)
            + " — bu araç yalnız izole yerel ortamda çalışır. "
            "Bu değişkenleri geçici olarak temizleyip tekrar dene."
        )
