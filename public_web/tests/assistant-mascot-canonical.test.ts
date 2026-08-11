import { describe, expect, it } from "vitest";
import { readFileSync } from "fs";
import { resolve } from "path";

const next = (path: string) =>
  readFileSync(resolve(__dirname, "..", path), "utf-8");

const flutterAvatarSource = readFileSync(
  resolve(__dirname, "../..", "lib/widgets/vixrex_avatar.dart"),
  "utf-8"
);
const ownerPanelSource = next("src/app/v/[slug]/OwnerAssistantPanel.tsx");
const nextAvatarSource = next(
  "src/app/v/[slug]/components/VixrexAvatar.tsx"
);

describe("Vixrex Asistan sürekliliği — canonical maskot (#115)", () => {
  it("Flutter ve Next.js aynı canonical Vixrex maskotunu kullanır", () => {
    const canonicalAsset = "assets/images/vixrex_v_crystal_mascot.png";
    const flutterMascot = readFileSync(
      resolve(__dirname, "../..", canonicalAsset)
    );
    const nextMascot = readFileSync(
      resolve(__dirname, "../public/vixrex_v_crystal_mascot.png")
    );

    expect(flutterAvatarSource).toContain(canonicalAsset);
    expect(nextMascot.equals(flutterMascot)).toBe(true);
    expect(nextAvatarSource).toContain(
      'src="/vixrex_v_crystal_mascot.png"'
    );
    expect(ownerPanelSource).toContain("<VixrexAvatar size={28} decorative />");
    expect(ownerPanelSource).toContain(
      "<VixrexAvatar size={36} halo decorative />"
    );
    expect(ownerPanelSource).toContain("aria-expanded={acik}");
    expect(ownerPanelSource).not.toContain("🦊");
    expect(nextAvatarSource).toContain('alt={decorative ? "" : "Vixrex"}');
  });
});