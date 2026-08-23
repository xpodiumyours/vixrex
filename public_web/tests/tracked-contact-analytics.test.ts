import { describe, expect, it, vi } from "vitest";
import {
  DIRECTIONS_CLICK_EVENT,
  PHONE_CLICK_EVENT,
  TrackedDirectionsLink,
  TrackedPhoneLink,
  trackDirectionsClick,
  trackPhoneClick,
} from "../src/components/TrackedContactLink";
import type { GtagCommand } from "../src/components/TrackedWhatsAppLink";

describe("phone conversion analytics", () => {
  it("records a storefront phone click without personal contact data", () => {
    const gtag: GtagCommand = vi.fn();

    trackPhoneClick(gtag, {
      storeSlug: "ornek-magaza",
      clickLocation: "storefront_contact",
    });

    expect(gtag).toHaveBeenCalledWith("event", PHONE_CLICK_EVENT, {
      store_slug: "ornek-magaza",
      click_location: "storefront_contact",
    });
  });

  it("does nothing while consent-gated analytics is unavailable", () => {
    expect(() =>
      trackPhoneClick(undefined, {
        storeSlug: "ornek-magaza",
        clickLocation: "storefront_contact",
      }),
    ).not.toThrow();
  });

  it("does not count owner or preview interactions", () => {
    const gtag: GtagCommand = vi.fn();
    vi.stubGlobal("window", { gtag });

    const link = TrackedPhoneLink({
      href: "tel:+905551234567",
      storeSlug: "ornek-magaza",
      clickLocation: "storefront_contact",
      trackingEnabled: false,
      children: "0555 123 45 67",
    });
    link.props.onClick({ defaultPrevented: false });

    expect(gtag).not.toHaveBeenCalled();
    vi.unstubAllGlobals();
  });
});

describe("directions conversion analytics", () => {
  it("records a storefront directions click without personal contact data", () => {
    const gtag: GtagCommand = vi.fn();

    trackDirectionsClick(gtag, {
      storeSlug: "ornek-magaza",
      clickLocation: "storefront_contact",
    });

    expect(gtag).toHaveBeenCalledWith("event", DIRECTIONS_CLICK_EVENT, {
      store_slug: "ornek-magaza",
      click_location: "storefront_contact",
    });
  });

  it("does nothing while consent-gated analytics is unavailable", () => {
    expect(() =>
      trackDirectionsClick(undefined, {
        storeSlug: "ornek-magaza",
        clickLocation: "storefront_contact",
      }),
    ).not.toThrow();
  });

  it("does not count owner or preview interactions", () => {
    const gtag: GtagCommand = vi.fn();
    vi.stubGlobal("window", { gtag });

    const link = TrackedDirectionsLink({
      href: "https://www.google.com/maps/search/?api=1&query=41.0,29.0",
      storeSlug: "ornek-magaza",
      clickLocation: "storefront_contact",
      trackingEnabled: false,
      children: "Yol Tarifi Al",
    });
    link.props.onClick({ defaultPrevented: false });

    expect(gtag).not.toHaveBeenCalled();
    vi.unstubAllGlobals();
  });
});
