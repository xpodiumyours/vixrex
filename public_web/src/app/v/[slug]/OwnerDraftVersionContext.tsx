"use client";

import { createContext, useContext, useState, type ReactNode } from "react";

interface OwnerDraftVersionContextValue {
  draftVersion: number;
  setDraftVersion: (version: number) => void;
}

const OwnerDraftVersionContext = createContext<OwnerDraftVersionContextValue | null>(null);

/**
 * Server-loaded `draft_version` ile ekranda gösterilen `draft_data` aynı
 * snapshot'tan gelir. Router refresh sonrası prop değişirse version state de
 * render sırasında birlikte tazelenir; mutation API kendi kendine "latest"
 * version okuyup optimistic concurrency'yi baypas etmez.
 */
export function OwnerDraftVersionProvider({
  initialVersion,
  children,
}: {
  initialVersion: number;
  children: ReactNode;
}) {
  const [draftVersion, setDraftVersion] = useState(initialVersion);
  const [lastInitialVersion, setLastInitialVersion] = useState(initialVersion);

  if (initialVersion !== lastInitialVersion) {
    setLastInitialVersion(initialVersion);
    setDraftVersion(initialVersion);
  }

  return (
    <OwnerDraftVersionContext.Provider value={{ draftVersion, setDraftVersion }}>
      {children}
    </OwnerDraftVersionContext.Provider>
  );
}

export function useOwnerDraftVersion(): OwnerDraftVersionContextValue {
  const value = useContext(OwnerDraftVersionContext);
  if (!value) {
    throw new Error("OwnerDraftVersionProvider is required in owner workspace.");
  }
  return value;
}
