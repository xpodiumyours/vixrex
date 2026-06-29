import { vi } from "vitest";

export type QueryResult<T> = { data: T; error: null };
export type StorageListResult = { data: Array<{ name: string }>; error: null };

const emptyResult = { data: null, error: null };

export function createSupabaseMockBuilder() {
  return {
    from: vi.fn().mockReturnThis(),
    select: vi.fn().mockReturnThis(),
    eq: vi.fn().mockReturnThis(),
    delete: vi.fn().mockReturnThis(),
    update: vi.fn().mockReturnThis(),
    upsert: vi.fn().mockImplementation(() => Promise.resolve(emptyResult)),
    maybeSingle: vi.fn().mockImplementation(() => Promise.resolve(emptyResult)),
    insert: vi.fn().mockImplementation(() => Promise.resolve(emptyResult)),
    then: vi.fn().mockImplementation((resolve) => resolve(emptyResult)),
    storage: {
      from: vi.fn().mockReturnThis(),
      list: vi.fn().mockResolvedValue({ data: [], error: null }),
      remove: vi.fn().mockResolvedValue({ data: [], error: null }),
      upload: vi.fn().mockResolvedValue({ error: null }),
      getPublicUrl: vi.fn().mockReturnValue({
        data: { publicUrl: "http://storage/img.jpg" },
      }),
    },
  };
}
