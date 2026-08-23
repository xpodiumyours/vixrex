import { NextRequest, NextResponse } from "next/server";
import { supabase } from "@/lib/supabase";

/**
 * Kategori gorsel sablonlarini getir
 * GET /api/category-images?category={category_key}
 */
export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url);
  const category = searchParams.get("category");

  if (!category) {
    return NextResponse.json(
      { error: "category parameter required" },
      { status: 400 }
    );
  }

  try {
    const { data, error } = await supabase
      .from("category_image_templates")
      .select("*")
      .eq("category_key", category)
      .eq("is_active", true)
      .order("display_order");

    if (error) {
      console.error("Category images fetch error:", error);
      return NextResponse.json(
        { error: "Internal server error" },
        { status: 500 }
      );
    }

    // image_type'a gore grupla
    const grouped = {
      category_key: category,
      category_label: data.length > 0 ? data[0].category_label : category,
      images: {
        cover: data.filter((i) => i.image_type === "cover"),
        logo_placeholder: data.filter((i) => i.image_type === "logo_placeholder"),
        gallery: data.filter((i) => i.image_type === "gallery"),
        product: data.filter((i) => i.image_type === "product"),
      },
      total_count: data.length,
    };

    return NextResponse.json(grouped);
  } catch {
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 }
    );
  }
}

/**
 * Store'u kategori sablonuyla otomatik doldur
 * POST /api/category-images/apply
 * Body: { store_id, category_key, edit_token, fill_cover?, fill_logo?, fill_gallery?, fill_products? }
 *
 * V-56 Fix: edit_token zorunlu — RPC sahiplik kontrolü için gerektirir.
 * Flutter (auto_fill_service.dart:102) zaten edit_token gönderiyor.
 * Web caller'ları da edit_token sağlamalı.
 */
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const {
      store_id,
      category_key,
      edit_token,
      fill_cover = true,
      fill_logo = true,
      fill_gallery = true,
      fill_products = true,
    } = body;

    if (!store_id || !category_key) {
      return NextResponse.json(
        { error: "store_id and category_key required" },
        { status: 400 }
      );
    }

    // V-56: edit_token zorunlu — sahiplik kontrolü RPC içinde yapılır
    // (auth.uid() NULL olduğunda edit_token ile yetki doğrulanır)
    if (!edit_token || typeof edit_token !== "string" || edit_token.length < 24) {
      return NextResponse.json(
        { error: "edit_token required (min 24 chars)" },
        { status: 400 }
      );
    }

    // RPC fonksiyonunu cagir
    const result = await supabase.rpc("apply_category_template", {
      p_store_id: store_id,
      p_category_key: category_key,
      p_edit_token: edit_token,
      p_fill_cover: fill_cover,
      p_fill_logo: fill_logo,
      p_fill_gallery: fill_gallery,
      p_fill_products: fill_products,
    });

    if (result.error) {
      console.error("Apply template error:", result.error);
      return NextResponse.json(
        { error: result.error.message },
        { status: 500 }
      );
    }

    return NextResponse.json(result.data);
  } catch {
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 }
    );
  }
}