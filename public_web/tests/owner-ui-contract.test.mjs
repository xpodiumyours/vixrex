import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";

const read = (path) => readFileSync(new URL(`../${path}`, import.meta.url), "utf8");

const globals = read("src/app/globals.css");
const giris = read("src/app/giris/page.tsx");
const kayit = read("src/app/kayit/page.tsx");
const app = read("src/app/app/page.tsx");

test("owner palette stays isolated from landing and live storefront palettes", () => {
  assert.match(globals, /\.owner-shell\s*\{/);
  assert.match(globals, /--owner-primary:\s*#147DFF/);
  assert.match(globals, /--color-lp-primary:\s*#147DFF/);
  assert.match(globals, /--primary:\s*#38A0E4/);
  assert.match(globals, /\.vitrin-shell\s*\{/);
});

test("management forms expose labels, busy state and errors", () => {
  for (const source of [giris, kayit, app]) {
    assert.match(source, /<label htmlFor=/);
    assert.match(source, /aria-busy=/);
    assert.match(source, /role="alert"/);
  }
});

test("owner language follows the one-store Vitrinim model", () => {
  assert.match(app, />Vitrinim</);
  assert.match(app, /Vitrini Yönet/);
  assert.doesNotMatch(app, /Vitrinlerim/);
  assert.doesNotMatch(app, /Yeni Vitrin Oluştur/);
});

test("public SEO route entry points remain server components", () => {
  const publicPages = [
    "src/app/(site)/page.tsx",
    "src/app/(site)/kesfet/page.tsx",
    "src/app/v/[slug]/page.tsx",
  ];

  for (const path of publicPages) {
    assert.doesNotMatch(read(path), /^\s*["']use client["'];/);
  }
});
