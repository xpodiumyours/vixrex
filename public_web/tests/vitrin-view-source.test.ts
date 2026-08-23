import { describe, expect, it } from "vitest";
import { resolveVitrinViewSource } from "../src/lib/vitrinViewSource";

const HOST = "vixrex-public.vercel.app";

function resolve(srcParam: string | null, referrer: string) {
  return resolveVitrinViewSource({
    srcParam,
    referrer,
    currentHostname: HOST,
  });
}

describe("resolveVitrinViewSource", () => {
  it("empty referrer counts as direct", () => {
    expect(resolve(null, "")).toBe("direct");
  });

  it("google.com.tr resolves as google", () => {
    expect(resolve(null, "https://www.google.com.tr/")).toBe("google");
  });

  it("google subdomains and g.co also resolve as google", () => {
    expect(resolve(null, "https://news.google.com/")).toBe("google");
    expect(resolve(null, "https://g.co/kgs/abc")).toBe("google");
  });

  it("notgoogle.com is NOT google", () => {
    expect(resolve(null, "https://notgoogle.com/x")).toBe("diger_site");
  });

  it("instagram resolves as instagram", () => {
    expect(resolve(null, "https://l.instagram.com/?u=x")).toBe("instagram");
  });

  it("own domain counts as direct, not diger_site", () => {
    expect(resolve(null, `https://${HOST}/v/diger-vitrin`)).toBe("direct");
  });

  it("www variant of own domain also counts as direct", () => {
    return expect(
      resolveVitrinViewSource({
        srcParam: null,
        referrer: "https://www.vixrex-public.vercel.app/v/a",
        currentHostname: HOST,
      }),
    ).toBe("direct");
  });

  it("an unknown external site resolves as diger_site", () => {
    expect(resolve(null, "https://eksisozluk.com/entry/123")).toBe(
      "diger_site",
    );
  });

  it("?src=qr takes priority over a google referrer", () => {
    expect(resolve("qr", "https://www.google.com/")).toBe("qr");
  });

  it("?src=share takes priority over everything else", () => {
    expect(resolve("share", "https://wa.me/90555")).toBe("share");
  });

  it("src values other than qr/share are ignored (old behavior kept)", () => {
    expect(resolve("facebook", "https://eksisozluk.com/")).toBe("diger_site");
  });

  it("wa.me and chat.whatsapp.com resolve as whatsapp", () => {
    expect(resolve(null, "https://wa.me/905551234567")).toBe("whatsapp");
    expect(resolve(null, "https://chat.whatsapp.com/AbcDef")).toBe("whatsapp");
  });

  it("facebook, fb.com and l.facebook.com resolve as facebook", () => {
    expect(resolve(null, "https://www.facebook.com/vixrex")).toBe("facebook");
    expect(resolve(null, "https://fb.com/")).toBe("facebook");
    expect(resolve(null, "https://l.facebook.com/l.php?u=x")).toBe("facebook");
  });

  it("t.co, twitter.com and x.com resolve as twitter", () => {
    expect(resolve(null, "https://t.co/abc")).toBe("twitter");
    expect(resolve(null, "https://mobile.twitter.com/home")).toBe("twitter");
    expect(resolve(null, "https://x.com/vixrex")).toBe("twitter");
  });

  it("tiktok resolves as tiktok", () => {
    expect(resolve(null, "https://www.tiktok.com/@magaza")).toBe("tiktok");
  });

  it("a malformed referrer falls back to unknown", () => {
    expect(resolve(null, "not-a-url")).toBe("unknown");
  });
});
