import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.1';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
};

const bucket = 'shelf-images';
const listPageSize = 100;
const removeBatchSize = 1000;

class AccountDeletionError extends Error {
  constructor(
    readonly code: string,
    message: string,
  ) {
    super(message);
  }
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  if (request.method !== 'POST') {
    return json({ error: 'Method not allowed.' }, 405);
  }

  try {
    const authorization = request.headers.get('Authorization');
    if (!authorization) {
      return json({ error: 'Authentication required.' }, 401);
    }

    const payload = await request.json().catch(() => ({}));
    if (payload.confirm !== true) {
      return json({ error: 'Deletion confirmation required.' }, 400);
    }

    const supabaseUrl = requiredEnv('SUPABASE_URL');
    const anonKey = requiredEnv('SUPABASE_ANON_KEY');
    const serviceRoleKey = requiredEnv('SUPABASE_SERVICE_ROLE_KEY');

    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authorization } },
      auth: { persistSession: false },
    });
    const {
      data: { user },
      error: userError,
    } = await userClient.auth.getUser();
    if (userError || !user) {
      return json({ error: 'Authentication required.' }, 401);
    }

    const admin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    const { data: stores, error: storesReadError } = await admin
      .from('stores')
      .select('id,slug')
      .eq('user_id', user.id);
    failIf(storesReadError, 'STORE_LOOKUP_FAILED');

    const slugs = (stores ?? [])
      .map((store) => String(store.slug ?? '').trim())
      .filter(Boolean);

    for (const slug of slugs) {
      await removeStoragePrefix(admin, slug);
    }

    await deleteByValues(
      admin,
      'legal_acceptance_events',
      'store_slug',
      slugs,
    );
    const { error: legalUserError } = await admin
      .from('legal_acceptance_events')
      .delete()
      .eq('user_id', user.id);
    failIf(legalUserError, 'LEGAL_EVENT_DELETE_FAILED');

    await deleteByValues(
      admin,
      'meta_data_deletion_requests',
      'store_slug',
      slugs,
    );

    const { error: storeDeleteError } = await admin
      .from('stores')
      .delete()
      .eq('user_id', user.id);
    failIf(storeDeleteError, 'STORE_DELETE_FAILED');

    const { error: authDeleteError } = await admin.auth.admin.deleteUser(
      user.id,
    );
    failIf(authDeleteError, 'AUTH_DELETE_FAILED');

    return json({ ok: true });
  } catch (error) {
    console.error('delete-user-account failed', error);
    const code =
      error instanceof AccountDeletionError
        ? error.code
        : 'ACCOUNT_DELETE_FAILED';
    return json(
      { error: 'Account deletion could not be completed.', code },
      500,
    );
  }
});

function requiredEnv(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) {
    throw new AccountDeletionError('SERVER_CONFIG_MISSING', name);
  }
  return value;
}

function failIf(
  error: { message?: string } | null,
  code: string,
): void {
  if (error) {
    throw new AccountDeletionError(code, error.message ?? code);
  }
}

async function deleteByValues(
  admin: ReturnType<typeof createClient>,
  table: string,
  column: string,
  values: string[],
): Promise<void> {
  if (values.length === 0) return;
  const { error } = await admin.from(table).delete().in(column, values);
  failIf(error, `${table.toUpperCase()}_DELETE_FAILED`);
}

async function removeStoragePrefix(
  admin: ReturnType<typeof createClient>,
  prefix: string,
): Promise<void> {
  const paths = await listStorageFiles(admin, prefix);
  for (let offset = 0; offset < paths.length; offset += removeBatchSize) {
    const { error } = await admin.storage
      .from(bucket)
      .remove(paths.slice(offset, offset + removeBatchSize));
    failIf(error, 'STORAGE_DELETE_FAILED');
  }
}

async function listStorageFiles(
  admin: ReturnType<typeof createClient>,
  prefix: string,
): Promise<string[]> {
  const files: string[] = [];
  let offset = 0;

  while (true) {
    const { data, error } = await admin.storage.from(bucket).list(prefix, {
      limit: listPageSize,
      offset,
      sortBy: { column: 'name', order: 'asc' },
    });
    failIf(error, 'STORAGE_LIST_FAILED');

    for (const entry of data ?? []) {
      const path = `${prefix}/${entry.name}`;
      if (entry.id || entry.metadata) {
        files.push(path);
      } else {
        files.push(...(await listStorageFiles(admin, path)));
      }
    }

    if (!data || data.length < listPageSize) break;
    offset += data.length;
  }

  return files;
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}
