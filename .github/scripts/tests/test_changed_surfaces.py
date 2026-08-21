import importlib.util
import unittest
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[1] / "changed_surfaces.py"
SPEC = importlib.util.spec_from_file_location("changed_surfaces", SCRIPT)
assert SPEC and SPEC.loader
changed_surfaces = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(changed_surfaces)


class ChangedSurfacesTest(unittest.TestCase):
    def test_agent_and_documentation_changes_are_neutral(self) -> None:
        affected = changed_surfaces.classify_paths(
            [
                "AGENTS.md",
                "SECURITY.md",
                ".agents/skills/implement/SKILL.md",
                "docs/adr/001.md",
            ]
        )
        self.assertEqual(
            affected,
            {"flutter": False, "schema": False, "public_web": False},
        )

    def test_flutter_change_only_selects_flutter(self) -> None:
        affected = changed_surfaces.classify_paths(["lib/screens/home.dart"])
        self.assertEqual(
            affected,
            {"flutter": True, "schema": False, "public_web": False},
        )

    def test_next_change_only_selects_public_web(self) -> None:
        affected = changed_surfaces.classify_paths(["public_web/src/app/page.tsx"])
        self.assertEqual(
            affected,
            {"flutter": False, "schema": False, "public_web": True},
        )

    def test_schema_source_selects_next_and_schema_pipeline(self) -> None:
        affected = changed_surfaces.classify_paths(
            ["public_web/src/lib/vitrinFieldSchema.ts"]
        )
        self.assertEqual(
            affected,
            {"flutter": False, "schema": True, "public_web": True},
        )

    def test_dependency_files_select_their_surface_and_schema_pipeline(self) -> None:
        affected = changed_surfaces.classify_paths(
            ["pubspec.lock", "public_web/package-lock.json"]
        )
        self.assertEqual(
            affected,
            {"flutter": True, "schema": True, "public_web": True},
        )

    def test_shared_and_tool_changes_select_both_clients_and_schema(self) -> None:
        for path in (
            "shared/business_categories.json",
            "tool/business_categories_uret.dart",
        ):
            with self.subTest(path=path):
                self.assertEqual(
                    changed_surfaces.classify_paths([path]),
                    {"flutter": True, "schema": True, "public_web": True},
                )

    def test_ci_router_supabase_and_unknown_paths_fail_open(self) -> None:
        for path in (
            ".github/workflows/ci.yml",
            "supabase/migrations/20260811_change.sql",
            "unclassified-runtime-config.yaml",
        ):
            with self.subTest(path=path):
                self.assertEqual(
                    changed_surfaces.classify_paths([path]),
                    {"flutter": True, "schema": True, "public_web": True},
                )

    def test_vercel_exit_contract(self) -> None:
        self.assertEqual(
            changed_surfaces.vercel_ignore_exit("flutter", ["docs/README.md"]), 0
        )
        self.assertEqual(
            changed_surfaces.vercel_ignore_exit("flutter", ["lib/main.dart"]), 1
        )
        self.assertEqual(
            changed_surfaces.vercel_ignore_exit(
                "public_web", ["public_web/src/app/page.tsx"]
            ),
            1,
        )


if __name__ == "__main__":
    unittest.main()
