import { readFileSync, readdirSync, statSync } from "fs";
import { join, resolve } from "path";
import { describe, expect, it } from "vitest";

const srcDir = resolve(__dirname, "../src");
const dashboardPath = resolve(srcDir, "app/app/page.tsx");
const dashboardSource = readFileSync(dashboardPath, "utf8");
const storeLoaderSource = dashboardSource.slice(
  dashboardSource.indexOf("async function magazalariGetir"),
  dashboardSource.indexOf("useEffect(() =>")
);

function sourceFilesUnder(directory: string): string[] {
  return readdirSync(directory).flatMap((entry) => {
    const path = join(directory, entry);
    return statSync(path).isDirectory() ? sourceFilesUnder(path) : [path];
  });
}

describe("sahip panosu vitrin erişim sözleşmesi", () => {
  it("istemci stores sorgularında okunamayan user_id sütununu filtrelemez", () => {
    const violations = sourceFilesUnder(srcDir)
      .filter((path) => /\.[jt]sx?$/.test(path))
      .filter((path) => {
        const source = readFileSync(path, "utf8");
        return (
          /^\s*["']use client["'];?/m.test(source) &&
          /\.from\(\s*["']stores["']\s*\)[\s\S]{0,2000}?\.eq\(\s*["']user_id["']/.test(
            source
          )
        );
      });

    expect(violations).toEqual([]);
  });

  it("vitrin sahipliğini bootstrap RPC ile bulup vitrini okunabilir slug üzerinden getirir", () => {
    // Yeni birleşik bootstrap RPC (get_owner_workspace_bootstrap) birincil
    // yoldur; eski bootstrap_owner_state yedek olarak tutulur.
    expect(storeLoaderSource).toMatch(
      /\.rpc\(\s*["']get_owner_workspace_bootstrap["']\s*\)/
    );
    expect(storeLoaderSource).toMatch(
      /\.rpc\(\s*["']bootstrap_owner_state["']\s*\)/
    );
  });

  it("RPC vitrinin olmadığını söylediğinde kurulum formuna hatasız geçer", () => {
    // Yeni birleşik bootstrap yapısında slug boşsa setStores([]) çağrılır.
    expect(storeLoaderSource).toContain("setStores([])");
    expect(storeLoaderSource).toContain("if (showLoading) setYukleniyor(false)");
  });
});
