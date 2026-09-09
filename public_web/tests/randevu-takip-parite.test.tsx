// @vitest-environment jsdom

import React from "react";
import { afterEach, describe, expect, it, vi } from "vitest";
import { cleanup, render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import BookingTrackerClient from "@/app/v/[slug]/randevu/[token]/BookingTrackerClient";

const rpcMock = vi.hoisted(() => vi.fn());
const executeRecaptchaMock = vi.hoisted(() => vi.fn(async () => "test-token"));
vi.mock("@/lib/supabase", () => ({ supabase: { rpc: rpcMock } }));
vi.mock("@/components/recaptcha/RecaptchaProvider", () => ({
  useRecaptcha: () => ({ executeRecaptcha: executeRecaptchaMock }),
}));
vi.mock("next/link", () => ({
  default: ({ href, children }: { href: string; children: React.ReactNode }) => <a href={href}>{children}</a>,
}));

afterEach(() => {
  cleanup();
  vi.clearAllMocks();
  vi.unstubAllGlobals();
});

describe("Randevu takip gerçek etkileşim", () => {
  it("iptal onayından sonra cancel_appointment_by_token RPC'sini çağırır ve başarıyı gösterir", async () => {
    const appointment = {
      id: "randevu-1",
      store_slug: "demo-vitrin",
      store_name: "Demo Vitrin",
      customer_name: "Ayşe Test",
      customer_phone: "05551234567",
      customer_notes: "",
      service_title: "Saç Kesimi",
      service_price: "250 TL",
      service_duration: 30,
      appointment_time: "2026-09-10T10:00:00.000Z",
      status: "pending",
      created_at: "2026-09-09T10:00:00.000Z",
      expires_at: "2026-09-10T09:00:00.000Z",
      reschedule_request: null,
    };

    rpcMock.mockImplementation(async (name: string) => {
      if (name === "cancel_appointment_by_token") return { data: true, error: null };
      if (name === "get_appointment_by_token") {
        return { data: { ...appointment, status: "cancelled_by_customer" }, error: null };
      }
      return { data: null, error: null };
    });
    vi.stubGlobal("confirm", vi.fn(() => true));
    const user = userEvent.setup();

    render(<BookingTrackerClient initialAppointment={appointment} token="takip-tokeni" />);

    await user.click(screen.getByRole("button", { name: "Randevuyu İptal Et" }));

    await waitFor(() => {
      expect(rpcMock).toHaveBeenCalledWith("cancel_appointment_by_token", { p_token: "takip-tokeni" });
    });
    expect(executeRecaptchaMock).toHaveBeenCalledWith("booking_cancel");
    expect(screen.getByText("Randevunuz iptal edildi.")).toBeTruthy();
    await waitFor(() => expect(screen.getByText("İptal Ettiniz")).toBeTruthy());
  });
});
