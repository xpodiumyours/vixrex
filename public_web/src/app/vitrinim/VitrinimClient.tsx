"use client";

import { useRouter } from "next/navigation";
import { VitrinimEditor } from "@/components/owner/VitrinimEditor";
import type { OwnerProduct, OwnerProductCategory } from "@/components/owner/OwnerProductManager";

interface Props {
  store: { slug: string; name: string; is_published: boolean; products: OwnerProduct[]; product_categories: OwnerProductCategory[] };
  initialDraft: Record<string, unknown>;
}

export function VitrinimClient({ store, initialDraft }: Props) {
  const router = useRouter();
  return <VitrinimEditor store={store} initialDraft={initialDraft} onRefresh={async () => { router.refresh(); }} />;
}
