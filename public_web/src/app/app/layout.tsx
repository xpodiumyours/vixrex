import { AppSidebar, AppBottomNav } from "@/components/app/AppSidebar";

export default function AppLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex min-h-screen bg-[#050B1A]">
      <AppSidebar />
      <div className="flex min-h-screen flex-1 flex-col">
        <div className="flex-1 pb-16 md:pb-0">{children}</div>
        <AppBottomNav />
      </div>
    </div>
  );
}
