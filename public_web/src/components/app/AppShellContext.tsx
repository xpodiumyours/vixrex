"use client";

import { createContext, useContext, useMemo, useState } from "react";

type AppShellContextValue = {
  globalSearch: string;
  setGlobalSearch: (value: string) => void;
  statusVersion: number;
  refreshShellStatus: () => void;
  hasOwnerStore: boolean;
  setHasOwnerStore: (value: boolean) => void;
};

const FALLBACK_SHELL: AppShellContextValue = {
  globalSearch: "",
  setGlobalSearch: () => {},
  statusVersion: 0,
  refreshShellStatus: () => {},
  hasOwnerStore: false,
  setHasOwnerStore: () => {},
};

const AppShellContext = createContext<AppShellContextValue | null>(null);

export function AppShellProvider({ children }: { children: React.ReactNode }) {
  const [globalSearch, setGlobalSearch] = useState("");
  const [statusVersion, setStatusVersion] = useState(0);
  const [hasOwnerStore, setHasOwnerStore] = useState(false);

  const value = useMemo<AppShellContextValue>(
    () => ({
      globalSearch,
      setGlobalSearch,
      statusVersion,
      refreshShellStatus: () => setStatusVersion((current) => current + 1),
      hasOwnerStore,
      setHasOwnerStore,
    }),
    [globalSearch, statusVersion, hasOwnerStore],
  );

  return <AppShellContext.Provider value={value}>{children}</AppShellContext.Provider>;
}

/** Gerçek uygulamada AppShellProvider içinden gelir. Tekil bileşen testleri
 * shell dışında render edildiğinde yalnız shell-yenileme davranışı no-op olur. */
export function useAppShell(): AppShellContextValue {
  return useContext(AppShellContext) ?? FALLBACK_SHELL;
}

export const useAppShellSearch = useAppShell;
