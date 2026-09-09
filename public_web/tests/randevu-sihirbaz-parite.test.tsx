// @vitest-environment jsdom

import React from "react";
import { afterEach, describe, expect, it, vi } from "vitest";
import { cleanup, render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import BookingWizardClient from "@/app/v/[slug]/randevu/BookingWizardClient";

const rpcMock = vi.hoisted(() => vi.fn());
vi.mock("@/lib/supabase", () => ({ supabase: { rpc: rpcMock } }));
vi.mock("@/components/recaptcha/RecaptchaProvider", () => ({
  useRecaptcha: () => ({ executeRecaptcha: vi.fn(async () => "test-token") }),
}));
vi.mock("next/link", () => ({
  default: ({ href, children }: { href: string; children: React.ReactNode }) => <a href={href}>{children}</a>,
}));

afterEach(() => {
  cleanup();
  vi.clearAllMocks();
});

describe("Randevu sihirbazı gerçek etkileşim", () => {
  it("hizmet ve tarih seçince slot RPC'sini çağırır, saat seçince iletişim adımına geçer", async () => {
    rpcMock.mockResolvedValue({
      data: [{
        time: "10:00",
        capacity_total: 1,
        capacity_used: 0,
        slots_left: 1,
        confirmed_names: [],
        has_pending: false,
      }],
      error: null,
    });
    const user = userEvent.setup();

    render(
      <BookingWizardClient
        store={{
          slug: "demo-vitrin",
          name: "Demo Vitrin",
          offerings: [{ id: "hizmet-1", title: "Saç Kesimi", price: "250 TL", durationMinutes: 30, isBookable: true }],
        }}
      />,
    );

    await user.click(screen.getByRole("button", { name: /Saç Kesimi/i }));
    expect(screen.getByText("Bir randevu tarihi seçin")).toBeTruthy();

    const dateButton = screen.getAllByRole("button").find((button) => button.textContent?.trim() !== "Geri");
    expect(dateButton).toBeTruthy();
    await user.click(dateButton!);

    await waitFor(() => expect(rpcMock).toHaveBeenCalledTimes(1));
    const [rpcName, rpcArgs] = rpcMock.mock.calls[0];
    expect(rpcName).toBe("get_public_booking_slots");
    expect(rpcArgs.p_store_slug).toBe("demo-vitrin");
    expect(rpcArgs.p_date).toMatch(/^\d{4}-\d{2}-\d{2}$/);

    const slotButton = await screen.findByRole("button", { name: /10:00/ });
    await user.click(slotButton);
    expect(screen.getByText("Son Adım: İletişim Bilgileri")).toBeTruthy();
    expect(screen.getByText("Adım 4 / 4")).toBeTruthy();
  });
});
