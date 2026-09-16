import type { ReactNode } from "react";
import KesfetVitrinSourceMarker from "@/components/kesfet/KesfetVitrinSourceMarker";

export default function KesfetLayout({ children }: { children: ReactNode }) {
  return (
    <>
      <KesfetVitrinSourceMarker />
      {children}
    </>
  );
}
