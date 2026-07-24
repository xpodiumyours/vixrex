// supabase/functions/fetch-xml-feed/index.ts
// XML feed URL'inden içerik indiren Edge Function.
// CORS sorununu çözerek tarayıcıdan XML çekmeyi sağlar.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { url } = await req.json();

    if (!url || typeof url !== "string") {
      return new Response(
        JSON.stringify({ error: "URL zorunludur." }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // URL formatını kontrol et
    let normalizedUrl = url.trim();
    if (
      !normalizedUrl.startsWith("http://") &&
      !normalizedUrl.startsWith("https://")
    ) {
      normalizedUrl = "https://" + normalizedUrl;
    }

    // XML'i indir
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 30000); // 30 saniye timeout

    let response: Response;
    try {
      response = await fetch(normalizedUrl, {
        method: "GET",
        headers: {
          "User-Agent": "VixRex-XML-Reader/1.0",
          Accept:
            "application/xml, text/xml, application/rss+xml, application/atom+xml, */*",
        },
        signal: controller.signal,
      });
    } catch (fetchError) {
      clearTimeout(timeout);
      const errorMessage =
        fetchError instanceof Error ? fetchError.message : String(fetchError);
      return new Response(
        JSON.stringify({
          error: `URL'ye erişilemedi: ${errorMessage}`,
          url: normalizedUrl,
        }),
        {
          status: 502,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }
    clearTimeout(timeout);

    if (!response.ok) {
      return new Response(
        JSON.stringify({
          error: `HTTP ${response.status}: ${response.statusText}`,
          url: normalizedUrl,
        }),
        {
          status: 502,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // İçeriği oku
    const text = await response.text();

    // Boş içerik kontrolü
    if (!text || text.trim().length === 0) {
      return new Response(
        JSON.stringify({ error: "Boş XML içeriği.", url: normalizedUrl }),
        {
          status: 422,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // XML olduğunu doğrula (basit kontrol)
    const trimmed = text.trim().substring(0, 500).toLowerCase();
    if (
      !trimmed.startsWith("<?xml") &&
      !trimmed.startsWith("<rss") &&
      !trimmed.startsWith("<feed") &&
      !trimmed.startsWith("<products") &&
      !trimmed.startsWith("<catalog") &&
      !trimmed.startsWith("<items") &&
      !trimmed.startsWith("<urunler")
    ) {
      return new Response(
        JSON.stringify({
          error: "İçerik XML formatında görünmüyor.",
          url: normalizedUrl,
          preview: text.substring(0, 200),
        }),
        {
          status: 422,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Base64 olarak_encode et (Flutter tarafında decode edilecek)
    const encoder = new TextEncoder();
    const data = encoder.encode(text);
    let binary = "";
    for (let i = 0; i < data.length; i++) {
      binary += String.fromCharCode(data[i]);
    }
    const base64 = btoa(binary);

    return new Response(
      JSON.stringify({
        content: base64,
        length: text.length,
        url: normalizedUrl,
        contentType: response.headers.get("content-type") || "application/xml",
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    return new Response(
      JSON.stringify({ error: `Sunucu hatası: ${errorMessage}` }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
