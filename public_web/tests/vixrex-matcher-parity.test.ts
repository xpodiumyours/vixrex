import { describe, expect, it } from "vitest";
import fixtures from "../../shared/vixrex_motor_parity_fixtures.json";
import { resolveVixrexIntentMatches } from "../src/lib/vixrexIntentResolver";

type MatcherFixture = {
  id: string;
  input: string;
  expectedFieldKeys: string[];
  expectedMatchClasses: string[];
};

const matcherFixtures = (fixtures as { matcher: MatcherFixture[] }).matcher;

describe("Vixrex matcher shared parity fixtures — Next.js", () => {
  for (const fixture of matcherFixtures) {
    it(fixture.id, () => {
      const matches = resolveVixrexIntentMatches(fixture.input);
      expect(matches.map((match) => match.alan.anahtar)).toEqual(fixture.expectedFieldKeys);
      expect(matches.map((match) => match.matchClass)).toEqual(fixture.expectedMatchClasses);
    });
  }
});
