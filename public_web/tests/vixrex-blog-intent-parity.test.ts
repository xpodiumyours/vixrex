import { describe, expect, it } from "vitest";
import fixtures from "../../shared/vixrex_blog_intent_fixtures.json";
import { routeVixrexAssistantDomain } from "../src/lib/vixrexBlogIntent";

type Fixture = {
  id: string;
  input: string;
  domain: "storefront" | "blog" | "ambiguous";
  intent: string | null;
};

describe("Vixrex Blog domain shared parity fixtures — Next.js", () => {
  for (const fixture of (fixtures as { cases: Fixture[] }).cases) {
    it(fixture.id, () => {
      const result = routeVixrexAssistantDomain(fixture.input);
      expect(result.domain).toBe(fixture.domain);
      expect(result.intent).toBe(fixture.intent);
    });
  }
});
