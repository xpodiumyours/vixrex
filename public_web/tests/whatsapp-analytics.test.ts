import { describe, expect, it, vi } from "vitest";
import {
  TrackedWhatsAppLink,
  WHATSAPP_CLICK_EVENT,
  trackWhatsAppClick,
  type GtagCommand,
} from "../src/components/TrackedWhatsAppLink";

describe("WhatsApp conversion analytics", () => {
  it("records a storefront click without personal contact data", () => {
    const gtag: GtagCommand = vi.fn();

    trackWhatsAppClick(gtag, {
      storeSlug: "ornek-magaza",
      clickLocation: "storefront_hero",
    });

    expect(gtag).toHaveBeenCalledWith("event", WHATSAPP_CLICK_EVENT, {
      store_slug: "ornek-magaza",
      click_location: "storefront_hero",
    });
  });

  it("records which product generated the WhatsApp click", () => {
    const gtag: GtagCommand = vi.fn();

    trackWhatsAppClick(gtag, {
      storeSlug: "ornek-magaza",
      productSlug: "keten-gomlek",
      clickLocation: "product_detail",
    });

    expect(gtag).toHaveBeenCalledWith("event", WHATSAPP_CLICK_EVENT, {
      store_slug: "ornek-magaza",
      product_slug: "keten-gomlek",
      click_location: "product_detail",
    });
  });

  it("does nothing while consent-gated analytics is unavailable", () => {
    expect(() =>
      trackWhatsAppClick(undefined, {
        storeSlug: "ornek-magaza",
        clickLocation: "storefront_contact",
      }),
    ).not.toThrow();
  });

  it("does not count owner or preview interactions", () => {
    const gtag: GtagCommand = vi.fn();
    vi.stubGlobal("window", { gtag });

    const link = TrackedWhatsAppLink({
      href: "https://wa.me/905551234567",
      storeSlug: "ornek-magaza",
      clickLocation: "storefront_contact",
      trackingEnabled: false,
      children: "WhatsApp",
    });
    link.props.onClick({ defaultPrevented: false });

    expect(gtag).not.toHaveBeenCalled();
    vi.unstubAllGlobals();
  });
});
