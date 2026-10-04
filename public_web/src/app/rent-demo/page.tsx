import RentDemoIcerik from "./RentDemoIcerik";

type Props = {
  searchParams: Promise<{ slug?: string; hesap?: string }>;
};

export default async function RentDemoPage({ searchParams }: Props) {
  const params = await searchParams;
  const demoSlug = String(params.slug ?? "").trim();
  const hesapliAkis = params.hesap === "1";

  return <RentDemoIcerik demoSlug={demoSlug} hesapliAkis={hesapliAkis} />;
}
