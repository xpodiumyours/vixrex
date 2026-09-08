import { describe, expect, it } from "vitest";
import workingHoursContract from "../../shared/working_hours_contract.json";
import { FIELD_BY_KEY } from "@/lib/vitrinFieldSchema";

describe("çalışma saatleri — gerçek şema ve ortak sözleşme", () => {
  it("çalışma saatleri alanını gerçek VitrinField şemasından çözer", () => {
    const alan = FIELD_BY_KEY.get("calismaSaatleri");

    expect(alan).toMatchObject({
      anahtar: "calismaSaatleri",
      kolon: "working_hours",
      tip: "metin",
      bolum: "contact",
      kalite: true,
      maxUzunluk: 400,
    });
  });

  it("ortak çalışma saati sözleşmesi haftanın yedi gününü çalıştırılabilir veri olarak taşır", () => {
    const gunler = workingHoursContract.working_hours;

    expect(Object.keys(gunler)).toEqual(["1", "2", "3", "4", "5", "6", "7"]);
    expect(gunler["1"]).toEqual({ start: "09:00", end: "18:00", active: true });
    expect(gunler["7"]).toEqual({ start: "00:00", end: "00:00", active: false });

    for (const gun of Object.values(gunler)) {
      expect(gun.start).toMatch(/^\d{2}:\d{2}$/);
      expect(gun.end).toMatch(/^\d{2}:\d{2}$/);
      expect(typeof gun.active).toBe("boolean");
    }
  });
});
