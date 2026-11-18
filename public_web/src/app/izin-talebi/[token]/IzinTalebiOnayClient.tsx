"use client";

import { useState } from "react";
import Image from "next/image";
import Link from "next/link";
import type { SupplierPermissionRequestView } from "@/lib/supplierPermissionRequest";

interface IzinTalebiOnayClientProps {
  initialData: SupplierPermissionRequestView;
  token: string;
}

export default function IzinTalebiOnayClient({
  initialData,
  token,
}: IzinTalebiOnayClientProps) {
  const [data, setData] = useState<SupplierPermissionRequestView>(initialData);
  const [submitting, setSubmitting] = useState(false);
  const [errorMessage, setErrorMessage] = useState("");
  const [successMessage, setSuccessMessage] = useState(
    initialData.status === "onaylandi"
      ? "Yetkili bayi görsel izni daha önce onaylanmış."
      : "",
  );

  const isApproved = data.status === "onaylandi";
  const isRejected = data.status === "reddedildi";

  async function handleApprove() {
    if (submitting || isApproved || isRejected) return;
    setSubmitting(true);
    setErrorMessage("");
    try {
      const response = await fetch("/api/izin-talebi", {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ token }),
      });
      const payload = (await response.json()) as {
        success?: boolean;
        hata?: string;
        alreadyApproved?: boolean;
      };
      if (!response.ok || !payload.success) {
        setErrorMessage(payload.hata ?? "İzin onayı kaydedilemedi.");
        return;
      }
      setData((prev) => ({
        ...prev,
        status: "onaylandi",
        products: prev.products.map((product) => ({
          ...product,
          permission_status: "onaylandi",
        })),
      }));
      setSuccessMessage(
        payload.alreadyApproved
          ? "Yetkili bayi görsel izni zaten onaylanmış."
          : "Görsel kullanım izni onaylandı. Yetkili bayinizin ürün görselleri vitrin yayınına açıldı.",
      );
    } catch {
      setErrorMessage("Bağlantı sırasında bir sorun oluştu. Lütfen tekrar deneyin.");
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <main className="min-h-screen bg-slate-50 text-slate-900 py-10 px-4 sm:px-6 lg:px-8">
      <div className="mx-auto max-w-4xl flex flex-col gap-6">
        <header className="rounded-2xl border border-slate-200 bg-white p-6 sm:p-8 shadow-sm">
          <div className="flex flex-wrap items-center justify-between gap-3">
            <span className="inline-flex items-center gap-2 rounded-full bg-emerald-50 border border-emerald-200 px-3 py-1 text-xs font-semibold text-emerald-800">
              Fatura Kanıtlı Yetkili Bayi
            </span>
            <span
              className={`inline-flex items-center rounded-full px-3 py-1 text-xs font-semibold border ${
                isApproved
                  ? "bg-emerald-50 border-emerald-200 text-emerald-800"
                  : isRejected
                    ? "bg-rose-50 border-rose-200 text-rose-800"
                    : "bg-amber-50 border-amber-200 text-amber-800"
              }`}
            >
              {isApproved ? "İzin Onaylandı" : isRejected ? "Reddedildi" : "Onay Bekliyor"}
            </span>
          </div>

          <div className="mt-5 flex flex-col gap-2">
            <p className="text-xs font-semibold uppercase tracking-wider text-slate-500">
              Vixrex Marka &amp; Görsel İzin Portalı
            </p>
            <h1 className="text-2xl sm:text-3xl font-bold tracking-tight text-slate-900">
              {data.brand} Yetkili Bayi Görsel Kullanım Talebi
            </h1>
            <p className="text-sm sm:text-base text-slate-600 leading-relaxed">
              Aşağıdaki işletme, faturasını ibraz ettiği {data.brand} ürünlerini Vixrex vitrininde resmi ürün görselleriyle sergileyebilmek için tek tıkla kullanım izninizi talep etmektedir.
            </p>
          </div>

          <div className="mt-6 grid grid-cols-1 sm:grid-cols-3 gap-4 rounded-xl bg-slate-50 border border-slate-200 p-4">
            <div className="flex flex-col gap-1">
              <span className="text-xs font-medium text-slate-500">Yetkili Bayi / Mağaza</span>
              <span className="text-sm font-semibold text-slate-900">{data.store_name}</span>
            </div>
            <div className="flex flex-col gap-1">
              <span className="text-xs font-medium text-slate-500">Vitrin Bağlantısı</span>
              <Link
                href={`/v/${encodeURIComponent(data.store_slug)}`}
                target="_blank"
                rel="noopener noreferrer"
                className="text-sm font-semibold text-sky-700 hover:text-sky-900 underline underline-offset-2"
              >
                /v/{data.store_slug}
              </Link>
            </div>
            <div className="flex flex-col gap-1">
              <span className="text-xs font-medium text-slate-500">Kapsam</span>
              <span className="text-sm font-semibold text-slate-900">
                {data.product_count} ürün kartı
              </span>
            </div>
          </div>
        </header>

        <section className="rounded-2xl border border-slate-200 bg-white p-6 sm:p-8 shadow-sm">
          <div className="flex items-center justify-between gap-4 mb-5">
            <h2 className="text-lg font-bold text-slate-900">Ürün Kartları Önizlemesi</h2>
            <span className="text-xs font-medium text-slate-500">
              {data.products.length} kayıt listeleniyor
            </span>
          </div>

          {data.products.length === 0 ? (
            <p className="text-sm text-slate-600 py-4">
              Bu izin talebiyle eşleşen önizleme ürünü bulunamadı.
            </p>
          ) : (
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
              {data.products.map((product) => {
                const imageUrl = product.image_urls[0] ?? "";
                const cardApproved = isApproved || product.permission_status === "onaylandi";
                return (
                  <article
                    key={product.id}
                    className="flex flex-col rounded-xl border border-slate-200 bg-white overflow-hidden"
                  >
                    <div className="relative aspect-square w-full bg-slate-100 flex items-center justify-center overflow-hidden">
                      {imageUrl ? (
                        <Image
                          src={imageUrl}
                          alt={product.name}
                          fill
                          sizes="(max-width: 640px) 100vw, (max-width: 1024px) 50vw, 33vw"
                          className="object-contain p-3"
                        />
                      ) : (
                        <span className="text-xs font-medium text-slate-400">Görsel Yok</span>
                      )}
                    </div>
                    <div className="p-4 flex flex-col gap-2 flex-1">
                      <div className="flex items-center justify-between gap-2">
                        <span className="text-xs font-semibold uppercase tracking-wide text-slate-500">
                          {product.brand}
                        </span>
                        <span
                          className={`rounded-full px-2 py-0.5 text-[11px] font-semibold ${
                            cardApproved
                              ? "bg-emerald-50 text-emerald-700 border border-emerald-200"
                              : "bg-amber-50 text-amber-700 border border-amber-200"
                          }`}
                        >
                          {cardApproved ? "İzinli" : "Bekliyor"}
                        </span>
                      </div>
                      <h3 className="text-sm font-semibold text-slate-900 line-clamp-2">
                        {product.name}
                      </h3>
                      {product.model ? (
                        <p className="text-xs text-slate-500 mt-auto">
                          Model: <span className="font-mono text-slate-700">{product.model}</span>
                        </p>
                      ) : null}
                    </div>
                  </article>
                );
              })}
            </div>
          )}
        </section>

        <section className="rounded-2xl border border-slate-200 bg-white p-6 sm:p-8 shadow-sm flex flex-col gap-4">
          <p className="text-xs text-slate-500 leading-relaxed">
            Bu sayfada yalnızca vitrin kimliği ve ürün görselleri paylaşılır; fatura tutarı, alış fiyatı, iskonto, VKN veya ticari koşullar kesinlikle görüntülenmez.
          </p>

          {errorMessage ? (
            <div
              role="alert"
              className="rounded-xl border border-rose-200 bg-rose-50 px-4 py-3 text-sm font-medium text-rose-800"
            >
              {errorMessage}
            </div>
          ) : null}

          {successMessage ? (
            <div
              role="status"
              className="rounded-xl border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm font-medium text-emerald-800"
            >
              {successMessage}
            </div>
          ) : null}

          <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 pt-1">
            <button
              type="button"
              onClick={handleApprove}
              disabled={submitting || isApproved || isRejected}
              className={`inline-flex items-center justify-center rounded-xl px-6 py-3.5 text-sm font-semibold transition ${
                isApproved
                  ? "bg-emerald-600 text-white cursor-default opacity-90"
                  : isRejected
                    ? "bg-slate-200 text-slate-500 cursor-not-allowed"
                    : "bg-slate-900 text-white hover:bg-slate-800 disabled:opacity-60 cursor-pointer"
              }`}
            >
              {submitting
                ? "Onay Kaydediliyor..."
                : isApproved
                  ? "Görsel İzni Onaylandı"
                  : "Yetkili Bayime Görsel İzni Ver"}
            </button>
          </div>
        </section>
      </div>
    </main>
  );
}
