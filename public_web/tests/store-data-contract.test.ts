import { describe, expect, it } from "vitest";
import { EDITABLE_COLUMNS } from "../src/lib/vitrinFieldSchema";
import { PUBLIC_STORE_SELECT } from "../src/lib/publicStoreSelect";

describe("public mağaza kolon sözleşmesi", () => {
  it("bütün düzenlenebilir kolonları taşır, hassas kolonları taşımaz", () => {
    const selected = new Set(PUBLIC_STORE_SELECT.split(","));
    expect(EDITABLE_COLUMNS.filter((column) => !selected.has(column))).toEqual([]);
    expect(selected.has("edit_token")).toBe(false);
    expect(selected.has("user_id")).toBe(false);
  });
});
