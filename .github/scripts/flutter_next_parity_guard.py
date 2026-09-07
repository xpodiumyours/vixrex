#!/usr/bin/env python3
"""Flutter Web -> Next.js parite kapısı.

Bu kapının amacı yorum yapmak değil, referansı mekanik olarak sabitlemektir:
- Flutter Web referansı git tree/blob SHA'larıyla kilitlidir.
- Next.js uygulama değişikliği ile Flutter/shared/test/parite kapısı aynı PR'da
  değiştirilemez (ilk kurulum PR'ı hariç).
- Ortak karşılama sözleşmesi Flutter referansından türetilen contract ile
  shared katalogda birebir eşit olmalıdır.
- Doğrulanamayan durum PASS sayılmaz; script non-zero ile kapanır.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LOCK_PATH = ROOT / "parity" / "flutter_reference.lock.json"
CONTRACT_PATH = ROOT / "parity" / "flutter_next_contract.json"

REFERENCE_PREFIXES = (
    "lib/",
    "test/",
    "integration_test/",
    "web/",
    "assets/",
    "shared/",
    "tool/",
)
REFERENCE_FILES = {
    "pubspec.yaml",
    "pubspec.lock",
}
GATE_FILES = {
    "parity/flutter_reference.lock.json",
    "parity/flutter_next_contract.json",
    ".github/scripts/flutter_next_parity_guard.py",
    ".github/scripts/tests/test_flutter_next_parity_guard.py",
    ".github/workflows/ci.yml",
    ".github/scripts/teslimat.py",
}


def normalize(path: str) -> str:
    return path.replace("\\", "/").removeprefix("./").strip("/")


def git(*args: str, check: bool = True) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", *args],
        cwd=ROOT,
        text=True,
        capture_output=True,
        check=check,
    )


def changed_files(base: str, head: str) -> list[str]:
    if not base or set(base) == {"0"}:
        raise ValueError("geçerli base SHA gerekli")
    result = git("diff", "--name-only", base, head, "--")
    return [normalize(line) for line in result.stdout.splitlines() if line.strip()]


def base_has_lock(base: str) -> bool:
    result = git("cat-file", "-e", f"{base}:parity/flutter_reference.lock.json", check=False)
    return result.returncode == 0


def is_reference_path(path: str) -> bool:
    path = normalize(path)
    return path in REFERENCE_FILES or path.startswith(REFERENCE_PREFIXES)


def mixed_change_violations(paths: list[str], *, enforce: bool) -> list[str]:
    """Next uygulaması ile referans/kapı aynı PR'da değişmesin.

    İlk kurulumda base dalında lock dosyası yoktur; bootstrap PR'ı bu kuralın
    tek istisnasıdır. Lock main'e girdikten sonra istisna otomatik kapanır.
    """
    if not enforce:
        return []
    normalized = [normalize(path) for path in paths]
    next_changed = any(path.startswith("public_web/") for path in normalized)
    if not next_changed:
        return []
    return sorted(
        path
        for path in normalized
        if is_reference_path(path) or path in GATE_FILES
    )


def load_json(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def object_sha(path: str) -> str:
    result = git("rev-parse", f"HEAD:{path}")
    return result.stdout.strip()


def verify_reference_lock(errors: list[str]) -> None:
    if not LOCK_PATH.exists():
        errors.append("Flutter referans lock dosyası yok")
        return
    lock = load_json(LOCK_PATH)
    objects = lock.get("git_objects")
    if not isinstance(objects, dict) or not objects:
        errors.append("Flutter referans lock dosyasında git_objects boş")
        return
    for path, expected in objects.items():
        try:
            actual = object_sha(str(path))
        except subprocess.CalledProcessError:
            errors.append(f"Flutter referans yolu bulunamadı: {path}")
            continue
        if actual != expected:
            errors.append(
                f"Flutter referansı değişmiş: {path} ({expected[:12]} -> {actual[:12]}). "
                "Next parite PR'ında referans değiştirilemez; referans güncellemesini ayrı PR yap."
            )


def contract_options() -> list[dict]:
    contract = load_json(CONTRACT_PATH)
    if contract.get("reference") != "Flutter Web":
        raise ValueError("contract.reference tam olarak 'Flutter Web' olmalı")
    differences = contract.get("allowlisted_differences")
    if not isinstance(differences, list):
        raise ValueError("allowlisted_differences liste olmalı")
    flow = contract.get("flows", {}).get("onboarding.welcome", {})
    options = flow.get("quick_options")
    if not isinstance(options, list) or not options:
        raise ValueError("onboarding.welcome.quick_options boş")
    return options


def verify_contract_against_flutter(errors: list[str]) -> None:
    try:
        options = contract_options()
    except (OSError, json.JSONDecodeError, ValueError) as exc:
        errors.append(f"Parite contract okunamadı: {exc}")
        return

    expected = [(str(item.get("id")), str(item.get("label"))) for item in options]
    shared = load_json(ROOT / "shared" / "vixrex_mesajlar.json")
    shared_options = shared.get("hizliSecenekler")
    actual = []
    if isinstance(shared_options, list):
        actual = [(str(item.get("id")), str(item.get("etiket"))) for item in shared_options]
    if actual != expected:
        errors.append(f"Shared hızlı seçenekler Flutter contract ile eşit değil: {actual!r} != {expected!r}")

    expected_actions = {
        "hazir_vitrin_sec": "template_intent",
        "sifirdan_olustur": "name",
        "bakiniyorum": "stay_welcome",
    }
    actual_actions = {str(item.get("id")): str(item.get("action")) for item in options}
    if actual_actions != expected_actions:
        errors.append(f"Karşılama aksiyon sözleşmesi beklenen Flutter davranışı değil: {actual_actions!r}")

    flutter_test = (ROOT / "test" / "onboarding_niyet_akis_test.dart").read_text(encoding="utf-8")
    for _, label in expected:
        needle = f"expect(find.text('{label}'), findsOneWidget)"
        if needle not in flutter_test:
            errors.append(f"Flutter oracle testinde hızlı seçenek doğrulaması yok: {label}")

    controller = (ROOT / "lib" / "controllers" / "vixrex_onboarding_controller.dart").read_text(encoding="utf-8")
    required_controller_fragments = (
        "void chooseReadyTemplate()",
        "_step = VixRexOnboardingStep.templateNiyet",
        "Future<void> chooseScratch()",
        "_step = VixRexOnboardingStep.name",
        "void declineWelcome()",
        "_onUserMessage('Şimdilik bakınıyorum')",
        "_onBotMessage('Tamam. Hazır olunca buradayım.')",
        "_step = VixRexOnboardingStep.welcome",
    )
    for fragment in required_controller_fragments:
        if fragment not in controller:
            errors.append(f"Flutter controller sözleşmesi doğrulanamadı: {fragment}")


def verify_next_contract_wiring(errors: list[str]) -> None:
    """E2E'nin yanında ucuz fail-fast kontrolü; tek başına parite kanıtı değildir."""
    apk = (ROOT / "public_web" / "src" / "components" / "landing" / "LandingApkAssistant.tsx").read_text(encoding="utf-8")
    sohbet = (ROOT / "public_web" / "src" / "components" / "landing" / "LandingAsistanSohbeti.tsx").read_text(encoding="utf-8")

    if "useState" in apk or "Evet, Oluşturalım" in apk:
        errors.append("LandingApkAssistant bağımsız Next state/UX üretiyor; Flutter referansına delege etmeli")
    if "<LandingAsistanSohbeti" not in apk:
        errors.append("LandingApkAssistant tek onboarding uygulamasına delege etmiyor")

    for option_id in ("hazir_vitrin_sec", "sifirdan_olustur", "bakiniyorum"):
        if option_id not in sohbet:
            errors.append(f"Next onboarding hızlı seçenek id'si eksik: {option_id}")
    if 'data-testid="landing-onboarding-quick-options"' not in sohbet:
        errors.append("Next onboarding gerçek-render E2E kökü eksik")
    if "setBakiniyorumAck(true)" not in sohbet:
        errors.append("Bakınıyorum Flutter gibi welcome durumunda kalmıyor")


def run_guard(base: str, head: str) -> list[str]:
    errors: list[str] = []
    try:
        paths = changed_files(base, head)
    except (ValueError, subprocess.CalledProcessError) as exc:
        return [f"Değişiklik listesi okunamadı: {exc}"]

    violations = mixed_change_violations(paths, enforce=base_has_lock(base))
    if violations:
        errors.append(
            "Next.js değişikliği ile Flutter referansı/parite kapısı aynı PR'da değiştirildi: "
            + ", ".join(violations)
            + ". İşleri ayır; Flutter referans değişikliği ayrı PR olmalı."
        )

    verify_reference_lock(errors)
    verify_contract_against_flutter(errors)
    verify_next_contract_wiring(errors)
    return errors


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base", required=True)
    parser.add_argument("--head", default="HEAD")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    errors = run_guard(args.base, args.head)
    if errors:
        for error in errors:
            print(f"::error::{error}", file=sys.stderr)
        print(f"Flutter -> Next Parity: FAIL ({len(errors)} hata)", file=sys.stderr)
        return 1
    print("Flutter -> Next Parity: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
