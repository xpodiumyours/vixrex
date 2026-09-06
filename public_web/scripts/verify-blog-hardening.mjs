import { createClient } from "@supabase/supabase-js";

const supabaseUrl = process.env.SUPABASE_URL;
const anonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const baseUrl = process.env.E2E_PUBLIC_BASE_URL ?? "http://127.0.0.1:3000";

if (!supabaseUrl || !anonKey || !serviceRoleKey) {
  throw new Error("Supabase test ortamı değişkenleri eksik.");
}

const service = createClient(supabaseUrl, serviceRoleKey, {
  auth: { persistSession: false, autoRefreshToken: false },
});
const publicClient = createClient(supabaseUrl, anonKey, {
  auth: { persistSession: false, autoRefreshToken: false },
});

const suffix = `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
const adminEmail = `blog-admin-${suffix}@example.test`;
const userEmail = `blog-user-${suffix}@example.test`;
const password = `Vixrex-Test-${suffix}!`;

let adminUserId;
let normalUserId;
let articleAId;
let articleBId;
let adminDirectArticleId;
let apiArticleId;

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

async function createUser(email) {
  const { data, error } = await service.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
  });
  if (error || !data.user) throw new Error(`Test kullanıcısı oluşturulamadı: ${error?.message}`);
  return data.user.id;
}

async function signIn(email) {
  const client = createClient(supabaseUrl, anonKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data, error } = await client.auth.signInWithPassword({ email, password });
  if (error || !data.session) throw new Error(`Test oturumu açılamadı: ${error?.message}`);
  return data.session.access_token;
}

function authedClient(token) {
  return createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: `Bearer ${token}` } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

async function api(path, token, options = {}) {
  const headers = new Headers(options.headers ?? {});
  if (token) headers.set("authorization", `Bearer ${token}`);
  if (options.body && !headers.has("content-type")) headers.set("content-type", "application/json");
  return fetch(`${baseUrl}${path}`, { ...options, headers });
}

async function run() {
  adminUserId = await createUser(adminEmail);
  normalUserId = await createUser(userEmail);

  const { error: adminSeedError } = await service.from("admins").insert({ user_id: adminUserId });
  if (adminSeedError) throw new Error(`Admin test kaydı oluşturulamadı: ${adminSeedError.message}`);

  const adminToken = await signIn(adminEmail);
  const normalToken = await signIn(userEmail);
  const admin = authedClient(adminToken);
  const normal = authedClient(normalToken);

  const slugA = `hardening-published-${suffix}`;
  const slugB = `hardening-draft-${suffix}`;
  const common = {
    summary: "Katman 2.5 güvenlik doğrulama kaydı.",
    content: "Bu kayıt yalnız yerel test ortamında kullanılır.",
    reading_minutes: 1,
    primary_topic: "google-yerel-gorunurluk",
    purpose: "gorunurluk-artirma",
    sector_ids: [],
    location_scope: "national",
    province_codes: [],
    district_targets: [],
    tags: ["hardening-test"],
    provenance: "automated-test",
    source_urls: [],
  };

  const { data: articleA, error: articleAError } = await service
    .from("vixrex_blog_articles")
    .insert({
      ...common,
      slug: slugA,
      title: "Hardening Published",
      status: "published",
      published_at: new Date().toISOString(),
    })
    .select("id")
    .single();
  if (articleAError || !articleA) throw new Error(`Published fixture oluşturulamadı: ${articleAError?.message}`);
  articleAId = articleA.id;

  const { data: articleB, error: articleBError } = await service
    .from("vixrex_blog_articles")
    .insert({
      ...common,
      slug: slugB,
      title: "Hardening Draft",
      status: "draft",
      published_at: null,
    })
    .select("id")
    .single();
  if (articleBError || !articleB) throw new Error(`Draft fixture oluşturulamadı: ${articleBError?.message}`);
  articleBId = articleB.id;

  // Public: published görünür, draft görünmez.
  const { data: publicPublished, error: publicPublishedError } = await publicClient
    .from("vixrex_blog_articles")
    .select("id")
    .eq("id", articleAId);
  assert(!publicPublishedError && publicPublished?.length === 1, "Anon published yazıyı göremedi.");

  const { data: publicDraft, error: publicDraftError } = await publicClient
    .from("vixrex_blog_articles")
    .select("id")
    .eq("id", articleBId);
  assert(!publicDraftError && publicDraft?.length === 0, "Anon draft yazıyı gördü.");

  // Normal authenticated: taslak okuyamaz ve yazamaz.
  const { data: normalDraft, error: normalDraftError } = await normal
    .from("vixrex_blog_articles")
    .select("id")
    .eq("id", articleBId);
  assert(!normalDraftError && normalDraft?.length === 0, "Normal kullanıcı draft yazıyı gördü.");

  const { error: normalInsertError } = await normal.from("vixrex_blog_articles").insert({
    ...common,
    slug: `hardening-denied-${suffix}`,
    title: "Denied insert",
    status: "draft",
    published_at: null,
  });
  assert(normalInsertError, "Normal kullanıcı merkezi blog yazısı ekleyebildi.");

  const { data: normalUpdate, error: normalUpdateError } = await normal
    .from("vixrex_blog_articles")
    .update({ title: "Unauthorized update" })
    .eq("id", articleAId)
    .select("id");
  assert(!normalUpdateError && normalUpdate?.length === 0, "Normal kullanıcı merkezi blog yazısını güncelleyebildi.");

  const { data: normalDelete, error: normalDeleteError } = await normal
    .from("vixrex_blog_articles")
    .delete()
    .eq("id", articleAId)
    .select("id");
  assert(!normalDeleteError && normalDelete?.length === 0, "Normal kullanıcı merkezi blog yazısını silebildi.");

  // Admin authenticated: draft okuyabilir ve doğrudan RLS üzerinden yönetebilir.
  const { data: adminDraft, error: adminDraftError } = await admin
    .from("vixrex_blog_articles")
    .select("id")
    .eq("id", articleBId);
  assert(!adminDraftError && adminDraft?.length === 1, "Admin draft yazıyı okuyamadı.");

  const { data: adminDirectArticle, error: adminDirectError } = await admin
    .from("vixrex_blog_articles")
    .insert({
      ...common,
      slug: `hardening-admin-${suffix}`,
      title: "Admin direct insert",
      status: "draft",
      published_at: null,
    })
    .select("id")
    .single();
  if (adminDirectError || !adminDirectArticle) {
    throw new Error(`Admin RLS insert başarısız: ${adminDirectError?.message}`);
  }
  adminDirectArticleId = adminDirectArticle.id;

  // Relation public kuralı: iki uç published değilse görünmez.
  const { error: relationError } = await service.from("vixrex_blog_article_relations").insert({
    article_id: articleAId,
    related_article_id: articleBId,
  });
  if (relationError) throw new Error(`Relation fixture oluşturulamadı: ${relationError.message}`);

  const { data: relationHidden, error: relationHiddenError } = await publicClient
    .from("vixrex_blog_article_relations")
    .select("article_id,related_article_id")
    .eq("article_id", articleAId)
    .eq("related_article_id", articleBId);
  assert(!relationHiddenError && relationHidden?.length === 0, "Draft uçlu relation anon'a sızdı.");

  const { error: publishBError } = await service
    .from("vixrex_blog_articles")
    .update({ status: "published", published_at: new Date().toISOString() })
    .eq("id", articleBId);
  if (publishBError) throw new Error(`İkinci fixture yayınlanamadı: ${publishBError.message}`);

  const { data: relationVisible, error: relationVisibleError } = await publicClient
    .from("vixrex_blog_article_relations")
    .select("article_id,related_article_id")
    .eq("article_id", articleAId)
    .eq("related_article_id", articleBId);
  assert(!relationVisibleError && relationVisible?.length === 1, "İki ucu published relation anon'a görünmedi.");

  // Admin API kimlik kapısı.
  const noAuth = await api("/api/vixrex-blog/admin-articles", null, { method: "GET" });
  assert(noAuth.status === 401, `Admin API tokensız istekte ${noAuth.status} döndürdü, 401 bekleniyordu.`);

  const normalApi = await api("/api/vixrex-blog/admin-articles", normalToken, { method: "GET" });
  assert(normalApi.status === 403, `Admin API normal kullanıcıda ${normalApi.status} döndürdü, 403 bekleniyordu.`);

  const adminApi = await api("/api/vixrex-blog/admin-articles", adminToken, { method: "GET" });
  assert(adminApi.status === 200, `Admin API admin kullanıcıda ${adminApi.status} döndürdü, 200 bekleniyordu.`);

  const adminCreate = await api("/api/vixrex-blog/admin-articles", adminToken, {
    method: "POST",
    body: JSON.stringify({
      title: "API hardening draft",
      slug: `api-hardening-${suffix}`,
      summary: "Yerel entegrasyon testi.",
      content: "Yerel entegrasyon testi.",
      readingMinutes: 1,
      primaryTopic: "google-yerel-gorunurluk",
      purpose: "gorunurluk-artirma",
      sectorIds: [],
      locationScope: "national",
      provinceCodes: [],
      districtTargets: [],
      tags: ["hardening-test"],
      provenance: "automated-test",
      sourceUrls: [],
    }),
  });
  assert(adminCreate.status === 200, `Admin API create ${adminCreate.status} döndürdü.`);
  const adminCreateBody = await adminCreate.json();
  assert(adminCreateBody?.tamam === true && adminCreateBody?.id, "Admin API create geçerli cevap üretmedi.");
  apiArticleId = adminCreateBody.id;

  console.log("Blog Katman 2.5 RLS + admin API davranış testi geçti.");
}

try {
  await run();
} finally {
  if (articleAId) {
    await service.from("vixrex_blog_article_relations").delete().eq("article_id", articleAId);
  }
  const ids = [apiArticleId, adminDirectArticleId, articleAId, articleBId].filter(Boolean);
  if (ids.length) await service.from("vixrex_blog_articles").delete().in("id", ids);
  if (adminUserId) await service.from("admins").delete().eq("user_id", adminUserId);
  if (adminUserId) await service.auth.admin.deleteUser(adminUserId);
  if (normalUserId) await service.auth.admin.deleteUser(normalUserId);
}
