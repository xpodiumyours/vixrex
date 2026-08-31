"use client";

import { supabase } from "@/lib/supabase";
import { taslagiOku } from "@/lib/landingAsistanAkisi";

/**
 * PR3-C11: Hesap sonrası yerel landing başlangıcını
 * owner_flow_states + tek active conversation'a idempotent aktarır.
 * Tekrar çağrı aynı sonucu üretir (client_message_id ile).
 */
export async function importLandingFlowStateIfNeeded(): Promise<void> {
  const taslak = taslagiOku() as Record<string, unknown>;
  if (!taslak || Object.keys(taslak).length === 0) return;

  const { data: { session } } = await supabase.auth.getSession();
  if (!session) return;

  // Akış tipi: kategori/kiralik var mı? Varsa rental, yoksa create
  const flowType = (taslak["kategori"] as string | undefined) ? "create" : "create";
  // Seçilen şablon: kategori veya kiralık slug
  const selectedTemplate = (taslak["kategori"] as string | undefined) ?? null;
  // Mevcut adım: en son doldurulan alana göre
  const hasName = !!taslak["name"];
  const currentStep = hasName ? "category" : "name";
  const clientMessageId = `landing-import-${session.user.id}-${hasName ? "name" : "empty"}`;
  const messageText = hasName ? `Landing başlangıç: ${taslak["name"] as string}` : "Landing başlangıç";

  const { error } = await supabase.rpc("import_landing_flow_state", {
    p_flow_type: flowType,
    p_selected_template: selectedTemplate,
    p_current_step: currentStep,
    p_client_message_id: clientMessageId,
    p_message_text: messageText,
  });

  if (error) {
    // Idempotent: zaten varsa sessiz geç, diğer hataları logla
    if (!error.message.includes("already") && !error.message.includes("duplicate")) {
      console.warn("[ownerFlowImport] import failed", error.message);
    }
    return;
  }

  // Başarılı aktarımda yerel taslağı temizleme — PR3 sonrası /app bootstrap devralacak
  // Şimdilik temizlemiyoruz, PR3-C12'de bootstrap sonrası temizlenecek
}
