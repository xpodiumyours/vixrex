"use client";

import { createContext, useContext, useMemo, useState } from "react";

type AppShellContextValue = {
  globalSearch: string;
  setGlobalSearch: (value: string) => void;
  statusVersion: number;
  refreshShellStatus: () => void;
};

const FALLBACK_SHELL: AppShellContextValue = {
  globalSearch: "",
  setGlobalSearch: () => {},
  statusVersion: 0,
  refreshShellStatus: () => {},
};

const AppShellContext = createContext<AppShellContextValue | null>(null);

export function AppShellProvider({ children }: { children: React.ReactNode }) {
  const [globalSearch, setGlobalSearch] = useState("");
  const [statusVersion, setStatusVersion] = useState(0);

  const value = useMemo<AppShellContextValue>(
    () => ({
      globalSearch,
      setGlobalSearch,
      statusVersion,
      refreshShellStatus: () => setStatusVersion((current) => current + 1),
    }),
    [globalSearch, statusVersion],
  );

  return <AppShellContext.Provider value={value}>{children}</AppShellContext.Provider>;
}

/** Gerçek uygulamada AppShellProvider içinden gelir. Tekil bileşen testleri
 * shell dışında render edildiğinde yalnız shell-yenileme davranışı no-op olur. */
export function useAppShell(): AppShellContextValue {
  return useContext(AppShellContext) ?? FALLBACK_SHELL;
}

export const useAppShellSearch = useAppShell;
