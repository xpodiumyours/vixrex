import { defineConfig } from "vitest/config";
import path from "path";

export default defineConfig({
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
      // `server-only` paketi varsayilan girisinde "istemciden ice aktarilamaz"
      // diye firlatir; sunucu girisi bos modüldur ve Next.js derlemesi onu
      // `react-server` kosuluyla secer. Vitest bu kosulu kurmadigi icin ayni
      // bos girisi elle isaret ediyoruz. Uretimdeki koruma aynen devam eder.
      "server-only": path.resolve(
        __dirname,
        "./node_modules/server-only/empty.js"
      ),
    },
  },
  test: {
    environment: "node",
    globals: true,
    // e2e/ klasörü PLAYWRIGHT'a ait; vitest onu çalıştırmaya kalkarsa
    // "test is not defined" diye kırılır. İki koşucu, iki klasör:
    //   tests/ → vitest   (npm test)
    //   e2e/   → playwright (npm run e2e)
    include: ["tests/**/*.test.ts", "src/**/*.test.ts"],
    exclude: ["e2e/**", "node_modules/**"],
  },
});
