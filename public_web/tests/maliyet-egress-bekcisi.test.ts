import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { afterEach, describe, expect, it } from "vitest";

const PUBLIC_WEB_DIR = path.resolve(import.meta.dirname, "..");
const SCRIPT_PATH = path.join(PUBLIC_WEB_DIR, "scripts", "kontrol", "maliyet-egress-bekcisi.mjs");
const tempDirs: string[] = [];

function createTempPublicWebCopy(): string {
  const tempRoot = fs.mkdtempSync(path.join(os.tmpdir(), "vixrex-maliyet-bekci-"));
  tempDirs.push(tempRoot);
  fs.cpSync(path.join(PUBLIC_WEB_DIR, "src"), path.join(tempRoot, "src"), { recursive: true });
  fs.copyFileSync(path.join(PUBLIC_WEB_DIR, "next.config.ts"), path.join(tempRoot, "next.config.ts"));
  return tempRoot;
}

function runGuard(targetRoot?: string): { status: number; stdout: string; stderr: string } {
  const args = targetRoot ? [SCRIPT_PATH, targetRoot] : [SCRIPT_PATH];
  try {
    const stdout = execFileSync(process.execPath, args, {
      cwd: PUBLIC_WEB_DIR,
      encoding: "utf8",
      stdio: ["ignore", "pipe", "pipe"],
    });
    return { status: 0, stdout, stderr: "" };
  } catch (error) {
    const err = error as { status?: number; stdout?: string; stderr?: string };
    return {
      status: err.status ?? 1,
      stdout: err.stdout ?? "",
      stderr: err.stderr ?? "",
    };
  }
}

afterEach(() => {
  while (tempDirs.length > 0) {
    const dir = tempDirs.pop();
    if (dir) {
      fs.rmSync(dir, { recursive: true, force: true });
    }
  }
});

describe("maliyet-egress-bekcisi", () => {
  it("mevcut public_web uzerinde exit 0 verir", () => {
    const result = runGuard();
    expect(result.status).toBe(0);
    expect(result.stdout).toContain("OK:");
  });

  it("v/[slug]/page.tsx icinde select(*) kullanilirsa non-zero cikisla reddeder", () => {
    const tempRoot = createTempPublicWebCopy();
    const target = path.join(tempRoot, "src", "app", "v", "[slug]", "page.tsx");
    const original = fs.readFileSync(target, "utf8");
    fs.writeFileSync(target, original.replace('.select("slug")', '.select("*")'), "utf8");

    const result = runGuard(tempRoot);
    expect(result.status).not.toBe(0);
    expect(result.stderr).toContain('select("*")');
  });

  it("kesfet icinde select('*,') kullanilirsa non-zero cikisla reddeder", () => {
    const tempRoot = createTempPublicWebCopy();
    const target = path.join(tempRoot, "src", "app", "(site)", "kesfet", "page.tsx");
    const original = fs.readFileSync(target, "utf8");
    fs.writeFileSync(target, `${original}\nconst leak = supabase.from("stores").select('*, id');\n`, "utf8");

    const result = runGuard(tempRoot);
    expect(result.status).not.toBe(0);
    expect(result.stderr).toContain('select("*")');
  });

  it("api/test/route.ts icinde dogrudan storage.from('shelf-images').upload( varsa reddeder", () => {
    const tempRoot = createTempPublicWebCopy();
    const apiTestDir = path.join(tempRoot, "src", "app", "api", "test");
    fs.mkdirSync(apiTestDir, { recursive: true });
    fs.writeFileSync(
      path.join(apiTestDir, "route.ts"),
      'export async function POST(admin: any) { return admin.storage.from("shelf-images").upload("a.webp", new Uint8Array()); }\n',
      "utf8",
    );

    const result = runGuard(tempRoot);
    expect(result.status).not.toBe(0);
    expect(result.stderr).toContain("storage.from(...).upload()");
  });

  it("sitemap.xml/route.ts icinde s-maxage=60 yapilirsa non-zero cikisla reddeder", () => {
    const tempRoot = createTempPublicWebCopy();
    const target = path.join(tempRoot, "src", "app", "sitemap.xml", "route.ts");
    const original = fs.readFileSync(target, "utf8");
    fs.writeFileSync(target, original.replace("s-maxage=3600", "s-maxage=60"), "utf8");

    const result = runGuard(tempRoot);
    expect(result.status).not.toBe(0);
    expect(result.stderr).toContain("s-maxage=60");
  });

  it("v/[slug]/page.tsx unstable_cache revalidate esigi 300 altina duserse reddeder", () => {
    const tempRoot = createTempPublicWebCopy();
    const target = path.join(tempRoot, "src", "app", "v", "[slug]", "page.tsx");
    const original = fs.readFileSync(target, "utf8");
    fs.writeFileSync(target, original.replace("revalidate: 300", "revalidate: 60"), "utf8");

    const result = runGuard(tempRoot);
    expect(result.status).not.toBe(0);
    expect(result.stderr).toContain("revalidate=60");
  });

  it("gorselSikistir.ts ONBELLEK_SANIYE degeri dusurulurse reddeder", () => {
    const tempRoot = createTempPublicWebCopy();
    const target = path.join(tempRoot, "src", "lib", "gorselSikistir.ts");
    const original = fs.readFileSync(target, "utf8");
    fs.writeFileSync(target, original.replace('ONBELLEK_SANIYE = "31536000"', 'ONBELLEK_SANIYE = "60"'), "utf8");

    const result = runGuard(tempRoot);
    expect(result.status).not.toBe(0);
    expect(result.stderr).toContain("ONBELLEK_SANIYE");
  });
});
