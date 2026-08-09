import hashlib
import json
import tempfile
from pathlib import Path

from evidence_test_support import EvidenceCliTestCase


class VixrexEvidenceSafetyTest(EvidenceCliTestCase):
    def test_snapshot_hash_covers_every_stable_manifest_field(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir) / "repo"
            root.mkdir()
            self.create_repo(root)
            env = self.fake_gh_env(
                Path(temp_dir), issue=self.issue(81, "Snapshot üret."), pull_requests=[]
            )

            result = self.run_cli(root, issue=81, base="HEAD", env=env)

            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            _, manifest = self.manifest(root)
            canonical = {
                key: value
                for key, value in manifest.items()
                if key not in {"generated_at_utc", "integrity"}
            }
            encoded = json.dumps(
                canonical, ensure_ascii=True, sort_keys=True, separators=(",", ":")
            ).encode("ascii")
            self.assertEqual(
                manifest["integrity"]["snapshot_sha256"],
                hashlib.sha256(encoded).hexdigest(),
            )

    def test_diff_inventory_preserves_rename_unicode_and_local_states(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir) / "repo"
            root.mkdir()
            self.create_repo(root)
            renamed_from = root / "eski ad.txt"
            tracked = root / "tracked.txt"
            renamed_from.write_text("rename me\n", encoding="utf-8")
            tracked.write_text("base\n", encoding="utf-8")
            self.git(root, "add", renamed_from.name, tracked.name)
            self.git(root, "commit", "-m", "diff base")
            base = self.git(root, "rev-parse", "HEAD")
            renamed_to = root / "yeni-şube.txt"
            self.git(root, "mv", renamed_from.name, renamed_to.name)
            self.git(root, "commit", "-m", "rename unicode")
            head = self.git(root, "rev-parse", "HEAD")
            staged = root / "staged-ç.txt"
            staged.write_text("staged\n", encoding="utf-8")
            self.git(root, "add", staged.name)
            tracked.write_text("unstaged\n", encoding="utf-8")
            untracked = root / "izlenmeyen ş.txt"
            untracked.write_text("untracked\n", encoding="utf-8")
            issue = self.issue(81, "Diff durumunu topla.")
            env = self.fake_gh_env(Path(temp_dir), issue=issue, pull_requests=[])
            result = self.run_cli(root, issue=81, base=base, env=env)

            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            _, manifest = self.manifest(root)
            self.assertEqual(manifest["git"]["head_sha"], head)
            self.assertIn(
                {"status": "R100", "paths": [renamed_from.name, renamed_to.name]},
                manifest["git"]["committed"],
            )
            self.assertIn({"status": "A", "paths": [staged.name]}, manifest["git"]["staged"])
            self.assertIn({"status": "M", "paths": [tracked.name]}, manifest["git"]["unstaged"])
            self.assertIn(untracked.name, manifest["git"]["untracked"])

    def test_head_change_during_capture_fails_without_publishing_artifact(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir) / "repo"
            root.mkdir()
            self.create_repo(root)
            env = self.fake_gh_env(
                Path(temp_dir),
                issue=self.issue(81, "Snapshot üret."),
                pull_requests=[],
                mutate_head=True,
            )
            result = self.run_cli(root, issue=81, base="HEAD", env=env)

            self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
            self.assertIn("HEAD snapshot alınırken değişti", result.stdout)
            self.assertFalse(self.evidence_paths(root))

    def test_dirty_file_content_change_during_capture_fails_without_artifact(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir) / "repo"
            root.mkdir()
            self.create_repo(root)
            mutable = root / "mutable.txt"
            mutable.write_text("base\n", encoding="utf-8")
            self.git(root, "add", mutable.name)
            self.git(root, "commit", "-m", "track mutable file")
            mutable.write_text("dirty before capture\n", encoding="utf-8")
            env = self.fake_gh_env(
                Path(temp_dir),
                issue=self.issue(81, "Snapshot üret."),
                pull_requests=[],
                mutate_worktree=True,
            )

            result = self.run_cli(root, issue=81, base="HEAD", env=env)

            self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
            self.assertIn("Worktree snapshot alınırken değişti", result.stdout)
            self.assertFalse(self.evidence_paths(root))

    def test_issue_change_during_capture_fails_without_artifact(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir) / "repo"
            root.mkdir()
            self.create_repo(root)
            env = self.fake_gh_env(
                Path(temp_dir),
                issue=self.issue(81, "Snapshot üret."),
                pull_requests=[],
                mutate_issue_on_recheck=True,
            )

            result = self.run_cli(root, issue=81, base="HEAD", env=env)

            self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
            self.assertIn("Issue #81 snapshot alınırken değişti", result.stdout)
            self.assertFalse(self.evidence_paths(root))

    def test_pr_change_during_capture_fails_without_artifact(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir) / "repo"
            root.mkdir()
            head = self.create_repo(root)
            pull_requests = [{
                "number": 82,
                "body": "Smoke başarılı.",
                "url": "https://example.test/pull/82",
                "headRefName": "main",
                "headRefOid": head,
                "baseRefName": "main",
                "baseRefOid": head,
                "state": "OPEN",
                "updatedAt": "2026-08-10T00:00:00Z",
                "changedFiles": 1,
                "files": [{"path": "README.md", "additions": 1, "deletions": 0}],
            }]
            env = self.fake_gh_env(
                Path(temp_dir),
                issue=self.issue(81, "Snapshot üret."),
                pull_requests=pull_requests,
                mutate_pr_on_recheck=True,
            )

            result = self.run_cli(root, issue=81, base="HEAD", env=env)

            self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
            self.assertIn("PR #82 snapshot alınırken değişti", result.stdout)
            self.assertFalse(self.evidence_paths(root))

    def test_claim_text_stays_unverified_and_repeated_runs_are_unique(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir) / "repo"
            root.mkdir()
            head = self.create_repo(root)
            secret = "service-role-secret-never-persist"
            issue = self.issue(81, f"SUPABASE_SERVICE_ROLE_KEY={secret}", title=secret)
            pull_requests = [{
                "number": 82,
                "title": secret,
                "body": f"42 test geçti. HEAD {head}. Kanıt `.vixrex-dev/run/evidence.json`. {secret}",
                "url": "https://example.test/pull/82",
                "headRefName": "main",
                "headRefOid": head,
                "baseRefName": "main",
                "baseRefOid": head,
                "state": "OPEN",
                "updatedAt": "2026-08-10T00:00:00Z",
                "changedFiles": 1,
                "files": [{"path": "README.md", "additions": 1, "deletions": 0}],
            }]
            env = self.fake_gh_env(Path(temp_dir), issue=issue, pull_requests=pull_requests)
            outputs = []
            for _ in range(2):
                result = self.run_cli(root, issue=81, base="HEAD", env=env)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                outputs.append(result.stdout)

            evidence_files = self.evidence_paths(root)
            self.assertEqual(len(evidence_files), 2, evidence_files)
            manifests = [json.loads(path.read_text(encoding="ascii")) for path in evidence_files]
            self.assertEqual(
                len({item["integrity"]["snapshot_sha256"] for item in manifests}), 1
            )
            for path, manifest, output in zip(evidence_files, manifests, outputs):
                combined = (
                    path.read_text(encoding="ascii")
                    + path.with_name("summary.md").read_text(encoding="utf-8")
                    + output
                )
                self.assertNotIn(secret, combined)
                self.assertEqual(manifest["result"]["status"], "unverified")
                self.assertTrue(
                    any(item["code"] == "unbound_pr_claim" for item in manifest["findings"])
                )

    @staticmethod
    def issue(number: int, body: str, *, title: str = "Evidence") -> dict[str, object]:
        return {
            "number": number,
            "title": title,
            "body": body,
            "state": "OPEN",
            "updatedAt": "2026-08-10T00:00:00Z",
            "url": f"https://example.test/issues/{number}",
            "labels": [],
            "comments": [],
        }


if __name__ == "__main__":
    import unittest

    unittest.main()
