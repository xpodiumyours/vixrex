import { describe, it, expect } from "vitest";
import { sanitizeHtml } from "@/lib/sanitize";

describe("sanitizeHtml", () => {
  it("returns empty string for falsy input", () => {
    expect(sanitizeHtml("")).toBe("");
  });

  it("passes through safe HTML untouched", () => {
    const safe = "<p>Hello <strong>world</strong></p>";
    expect(sanitizeHtml(safe)).toBe(safe);
  });

  it("removes script tags and their content", () => {
    const html = "<p>Safe</p><script>alert('xss')</script>";
    const result = sanitizeHtml(html);
    expect(result).not.toContain("<script");
    expect(result).not.toContain("alert");
    expect(result).toContain("<p>Safe</p>");
  });

  it("removes iframe tags", () => {
    const html = '<p>text</p><iframe src="https://evil.com"></iframe>';
    const result = sanitizeHtml(html);
    expect(result).not.toContain("<iframe");
    expect(result).toContain("<p>text</p>");
  });

  it("strips inline event handlers", () => {
    const html = '<a href="/" onclick="stealCookies()">Click</a>';
    const result = sanitizeHtml(html);
    expect(result).not.toContain("onclick");
    expect(result).toContain("Click");
  });

  it("neutralises javascript: URIs in href", () => {
    const html = '<a href="javascript:void(0)">Link</a>';
    const result = sanitizeHtml(html);
    expect(result).not.toContain("javascript:");
  });

  it("neutralises data: URIs in src", () => {
    const html = '<img src="data:text/html,<script>xss</script>">';
    const result = sanitizeHtml(html);
    expect(result).not.toContain("data:text/html");
  });

  it("removes object and embed tags", () => {
    const html = '<object data="evil.swf"></object><embed src="evil.swf">';
    const result = sanitizeHtml(html);
    expect(result).not.toContain("<object");
    expect(result).not.toContain("<embed");
  });

  it("removes style tags to prevent layout hijacking", () => {
    const html = "<style>body { display:none }</style><p>content</p>";
    const result = sanitizeHtml(html);
    expect(result).not.toContain("<style");
    expect(result).toContain("<p>content</p>");
  });
});
