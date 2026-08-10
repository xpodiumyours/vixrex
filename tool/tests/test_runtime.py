"""Issue #83 (T1) — dilim 1: uzak/production Supabase hedefi koruması.

`vixrex_local.runtime.assert_local_target`, aracın ambient ortamda uzak bir
Supabase hedefine işaret eden değişkenler görürse hiçbir süreç başlatmadan
durmasını sağlar. Bu betik yalnız yerel Docker/Supabase yığınına dokunmalı;
kazayla production'a bağlanmak riski buradan kapatılır.
"""

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from vixrex_local.runtime import RemoteTargetError, assert_local_target


class AssertLocalTargetTest(unittest.TestCase):
    def test_clean_env_passes(self):
        assert_local_target({})

    def test_unrelated_env_passes(self):
        assert_local_target({"PATH": "/usr/bin", "HOME": "/home/user"})

    def test_access_token_blocks(self):
        with self.assertRaises(RemoteTargetError):
            assert_local_target({"SUPABASE_ACCESS_TOKEN": "sbp_xxx"})

    def test_db_url_blocks(self):
        with self.assertRaises(RemoteTargetError):
            assert_local_target({"SUPABASE_DB_URL": "postgres://prod-host/db"})

    def test_project_ref_blocks(self):
        with self.assertRaises(RemoteTargetError):
            assert_local_target({"SUPABASE_PROJECT_REF": "abcdefghij"})

    def test_service_role_key_blocks(self):
        with self.assertRaises(RemoteTargetError):
            assert_local_target({"SUPABASE_SERVICE_ROLE_KEY": "eyJ.example"})

    def test_blank_value_does_not_block(self):
        # Değişken tanımlı ama boş — çoğu shell/CI'da "ayarlanmamış" ile
        # eşdeğer davranılır; yanlış pozitif üretmemeli.
        assert_local_target({"SUPABASE_DB_URL": ""})

    def test_multiple_markers_all_named(self):
        try:
            assert_local_target(
                {
                    "SUPABASE_ACCESS_TOKEN": "sbp_xxx",
                    "SUPABASE_DB_URL": "postgres://prod-host/db",
                }
            )
        except RemoteTargetError as exc:
            message = str(exc)
            self.assertIn("SUPABASE_ACCESS_TOKEN", message)
            self.assertIn("SUPABASE_DB_URL", message)
        else:
            self.fail("RemoteTargetError bekleniyordu")

    def test_error_message_never_leaks_value(self):
        # VIXREX_RULES §3.7 — sır/kişisel veri koda, loga veya mesaja yazılmaz.
        secret = "postgres://prod-host.example.com/very-secret-db"
        try:
            assert_local_target({"SUPABASE_DB_URL": secret})
        except RemoteTargetError as exc:
            message = str(exc)
            self.assertIn("SUPABASE_DB_URL", message)
            self.assertNotIn(secret, message)
            self.assertNotIn("prod-host.example.com", message)
        else:
            self.fail("RemoteTargetError bekleniyordu")


if __name__ == "__main__":
    unittest.main()
