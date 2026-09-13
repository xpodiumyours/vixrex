import type { Metadata } from "next";
import PublicProductDetailPage, {
  generateMetadata as generatePublicMetadata,
} from "./PublicProductDetailPage";
import OwnerProductDetailPreview from "./OwnerProductDetailPreview";

export const revalidate = 300;
export const dynamic = "force-dynamic";

interface PageProps {
  params: Promise<{ slug: string; productSlug: string }>;
}

export async function generateMetadata(props: PageProps): Promise<Metadata> {
  return generatePublicMetadata(props);
}

export default async function ProductDetailPage(props: PageProps) {
  const params = await props.params;
  const ownerPreview = await OwnerProductDetailPreview({
    slug: params.slug,
    productSlug: params.productSlug,
  });

  if (ownerPreview) return ownerPreview;
  return PublicProductDetailPage(props);
}
