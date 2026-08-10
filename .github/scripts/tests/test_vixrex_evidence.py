import json
import subprocess
import sys
import tempfile
from pathlib import Path

from evidence_test_support import EVIDENCE_CLI, EvidenceCliTestCase


class VixrexEvidenceProvenanceTest(EvidenceCliTestCase):
    def test_stale_issue_path_and_unbound_pr_claim_are_visible(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir) / "repo"
            root.mkdir()
            head = self.create_repo(root)
            env = self.fake_gh_env(Path(temp_dir), head_sha=head)
            result = self.run_cli(root, issue=39, base="HEAD", env=env)

            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            evidence, manifest = self.manifest(root)
            self.assertEqual(manifest["git"]["head_sha"], head)
            self.assertEqual(manifest["issue"]["number"], 39)
            self.assertEqual(len(manifest["issue"]["body_sha256"]), 64)
            findings = {item["code"]: item for item in manifest["findings"]}
            self.assertEqual(findings["missing_referenced_path"]["status"], "contradicted")
            self.assertIn("implementation_plan.md", findings["missing_referenced_path"]["detail"])
            self.assertEqual(findings["unbound_pr_claim"]["status"], "unverified")
            self.assertEqual(
                sum(item["code"] == "unbound_pr_claim" for item in manifest["findings"]),
                1,
            )
            self.assertEqual(len(manifest["pull_requests"]), 1)
            self.assertEqual(manifest["pull_requests"][0]["head_oid"], head)
            self.assertEqual(manifest["pull_requests"][0]["changed_file_count"], 1)
            self.assertEqual(
                manifest["pull_requests"][0]["changed_files"],
                [{
                    "path": "public_web/src/example.ts",
                    "additions": 3,
                    "deletions": 1,
                }],
            )
            sources = {item["id"]: item for item in manifest["sources"]}
            self.assertEqual(sources["git:snapshot"]["kind"], "repo-diff")
            self.assertEqual(sources["issue:39"]["kind"], "issue-intent")
            self.assertEqual(sources["pr:74"]["kind"], "narrative-claim")
            self.assertTrue(all(item["retrieval"] == "success" for item in sources.values()))
            self.assertEqual(manifest["result"]["status"], "contradicted")
            self.assertEqual(manifest["result"]["would_exit"], 1)
            self.assertEqual(manifest["result"]["effective_exit"], 0)
            self.assertIn("[REPORT-ONLY][CONTRADICTED]", result.stdout)
            self.assertNotIn("[OK]", result.stdout)
            self.assertIn(
                "missing_referenced_path",
                evidence.with_name("summary.md").read_text(encoding="utf-8"),
            )

    def test_public_interface_does_not_accept_arbitrary_root_or_output(self) -> None:
        result = subprocess.run(
            [sys.executable, str(EVIDENCE_CLI), "--help"],
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertNotIn("--root", result.stdout)
        self.assertNotIn("--output-dir", result.stdout)

    def test_closed_issue_keeps_unchecked_tasks_and_comment_provenance_visible(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir) / "repo"
            root.mkdir()
            self.create_repo(root)
            issue = {
                "number": 76,
                "title": "Ajan sistemi",
                "body": "## Kapsam\n\n- [ ] Kanıt doktorunu ekle.",
                "state": "CLOSED",
                "updatedAt": "2026-08-09T20:33:05Z",
                "url": "https://example.test/issues/76",
                "labels": [{"name": "wayfinder:task"}],
                "comments": [{
                    "author": {"login": "casper"},
                    "body": "Canlı ortam ayrıca doğrulanmadı.",
                    "createdAt": "2026-08-09T20:30:00Z",
                    "updatedAt": "2026-08-09T20:30:00Z",
                    "url": "https://example.test/issues/76#comment-1",
                }],
            }
            env = self.fake_gh_env(Path(temp_dir), issue=issue, pull_requests=[])
            result = self.run_cli(root, issue=76, base="HEAD", env=env)

            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            _, manifest = self.manifest(root)
            self.assertEqual(manifest["issue"]["comment_count"], 1)
            self.assertEqual(len(manifest["issue"]["comments"][0]["body_sha256"]), 64)
            self.assertNotIn("Canlı ortam ayrıca doğrulanmadı.", json.dumps(manifest))
            self.assertIn(
                "closed_issue_with_unchecked_tasks",
                {item["code"] for item in manifest["findings"]},
            )

    def test_planned_outputs_and_red_fixtures_are_not_current_path_claims(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir) / "repo"
            root.mkdir()
            self.create_repo(root)
            issue = {
                "number": 81,
                "title": "Evidence",
                "body": (
                    "## Allowed files\n\n- `docs/agents/future.md`\n\n"
                    "## Red evidence\n\nFixture `implementation_plan.md` eksik olur.\n\n"
                    "## Acceptance\n\n`future.json` üretilecek.\n\n"
                    "## Kararlar\n\nKökte `legacy.md` tutulmaz.\n\n"
                    "## Kabul ölçütleri\n\n`python tools/check.py` çalışır.\n\n"
                    "## Further Notes\n\nMevcut `README.md` okunur."
                ),
                "state": "OPEN",
                "updatedAt": "2026-08-10T00:00:00Z",
                "url": "https://example.test/issues/81",
                "labels": [],
                "comments": [],
            }
            env = self.fake_gh_env(Path(temp_dir), issue=issue, pull_requests=[])
            result = self.run_cli(root, issue=81, base="HEAD", env=env)

            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            _, manifest = self.manifest(root)
            self.assertFalse(
                any(item["code"] == "missing_referenced_path" for item in manifest["findings"])
            )
            self.assertEqual(manifest["issue"]["referenced_paths"], ["README.md"])

    def test_equivalent_verification_claims_cannot_escape_unverified(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir) / "repo"
            root.mkdir()
            head = self.create_repo(root)
            issue = {
                "number": 81,
                "body": "Kanıtlı başlangıç üret.",
                "state": "OPEN",
                "updatedAt": "2026-08-10T00:00:00Z",
                "url": "https://example.test/issues/81",
                "labels": [],
                "comments": [],
            }
            claims = (
                "Uygulama çalışıyor.",
                "CI yeşil.",
                "Smoke başarılı.",
                "All tests passed.",
            )
            pull_requests = [{
                "number": 90 + index,
                "body": claim,
                "url": f"https://example.test/pull/{90 + index}",
                "headRefName": "main",
                "headRefOid": head,
                "baseRefName": "main",
                "baseRefOid": head,
                "state": "OPEN",
                "updatedAt": "2026-08-10T00:00:00Z",
                "changedFiles": 1,
                "files": [{
                    "path": f"claim-{index}.md",
                    "additions": 1,
                    "deletions": 0,
                }],
            } for index, claim in enumerate(claims)]
            env = self.fake_gh_env(
                Path(temp_dir), issue=issue, pull_requests=pull_requests
            )

            result = self.run_cli(root, issue=81, base="HEAD", env=env)

            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            _, manifest = self.manifest(root)
            findings = [
                item for item in manifest["findings"]
                if item["code"] == "unbound_pr_claim"
            ]
            self.assertEqual(len(findings), len(claims))
            self.assertEqual(manifest["result"]["status"], "unverified")


if __name__ == "__main__":
    import unittest

    unittest.main()
