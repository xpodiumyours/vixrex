import { describe, expect, it } from "vitest";
import fixtures from "../../shared/vixrex_validator_parity_fixtures.json";
import { validateField } from "../src/lib/vitrinFieldValidation";

type ValidatorFixture = {
  id: string;
  fieldKey: string;
  input: unknown;
  expectedOk: boolean;
  expectedValue?: unknown;
};

const validatorFixtures = (fixtures as { validator: ValidatorFixture[] }).validator;

describe("Vixrex validator shared parity fixtures — Next.js", () => {
  for (const fixture of validatorFixtures) {
    it(fixture.id, () => {
      const result = validateField(fixture.fieldKey, fixture.input);
      expect(result.ok).toBe(fixture.expectedOk);
      if (fixture.expectedOk) {
        expect(result.ok).toBe(true);
        if (result.ok) expect(result.deger).toEqual(fixture.expectedValue);
      }
    });
  }
});
