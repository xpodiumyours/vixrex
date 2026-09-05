import { describe, expect, it } from "vitest";
import {
  buildServerFieldContracts,
  generateServerFieldContractSql,
} from "../../tool/server_field_contract_uret";

describe("Vixrex server field contract generator", () => {
  it("canonical şemadan tam 46 benzersiz field/column üretir", () => {
    const fields = buildServerFieldContracts();

    expect(fields).toHaveLength(46);
    expect(new Set(fields.map((field) => field.fieldKey)).size).toBe(46);
    expect(new Set(fields.map((field) => field.column)).size).toBe(46);
  });

  it("authoritative DB lookup SQL'ini deterministic ve privilege-free üretir", () => {
    const fields = buildServerFieldContracts();
    const sql = generateServerFieldContractSql(fields);

    expect(sql).toContain("create or replace function public.vixrex_storefront_field_contract");
    expect(sql).toContain("language sql");
    expect(sql).toContain("immutable");
    expect(sql.toLowerCase()).not.toContain("security definer");
    expect((sql.match(/\n    when '/g) ?? [])).toHaveLength(46);

    for (const field of fields) {
      expect(sql).toContain(`when '${field.fieldKey}'`);
      expect(sql).toContain(`\"column\":\"${field.column}\"`);
    }
  });

  it("adres ve tip/min/max gibi semantic metadata'yı kaybetmez", () => {
    const fields = buildServerFieldContracts();
    const adres = fields.find((field) => field.fieldKey === "adres");
    const enlem = fields.find((field) => field.fieldKey === "enlem");
    const whatsapp = fields.find((field) => field.fieldKey === "whatsapp");

    expect(adres?.validation).toBe("adres");
    expect(enlem?.type).toBe("sayi");
    expect(enlem?.min).toBe(-90);
    expect(enlem?.max).toBe(90);
    expect(whatsapp?.validation).toBe("tr_mobil");
  });
});
