import { notFound } from "next/navigation";
import { fetchSupplierPermissionRequest } from "@/lib/supplierPermissionRequest";
import IzinTalebiOnayClient from "./IzinTalebiOnayClient";

export const dynamic = "force-dynamic";

interface PageProps {
  params: Promise<{ token: string }>;
}

export async function generateMetadata() {
  return {
    title: "Yetkili Bayi Görsel İzni - Vixrex",
    robots: "noindex, nofollow",
  };
}

export default async function SupplierPermissionApprovalPage(props: PageProps) {
  const params = await props.params;
  const requestData = await fetchSupplierPermissionRequest(params.token);
  if (!requestData) {
    notFound();
  }

  return <IzinTalebiOnayClient initialData={requestData} token={params.token} />;
}
