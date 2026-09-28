import { PrismaD1 } from '@prisma/adapter-d1';
import type { D1Database } from '@cloudflare/workers-types';
import { PrismaClient } from '../node_modules/.prisma/client-d1';

/**
 * A Prisma client backed by Cloudflare D1.
 *
 * Three things differ from the Node client in `./index`, and all three follow
 * from D1 being SQLite reached through a binding rather than Postgres reached
 * over a socket:
 *
 *   - **A different generated client.** The column types are not the same —
 *     every enum is TEXT here, and so is every JSON column — so the Postgres
 *     client would mis-describe this database. It is generated separately from
 *     `schema.d1.prisma` into its own output directory.
 *   - **No connection string.** The database arrives as a binding on `env`.
 *     There is nothing to dial and nothing to pool.
 *   - **A client per request.** Cloudflare binds an I/O object to the request
 *     that created it, so a client made for one request cannot serve the next.
 *
 * What the caller must know: **D1 has no interactive transactions.** It runs
 * in auto-commit, and `batch()` is atomic only for a fixed list of statements
 * settled in advance. Prisma's `$transaction(async tx => …)` — which this
 * codebase uses in the feed-issue, payment-allocation and batch-close paths —
 * therefore does not give the atomicity it gives on Postgres. Those call sites
 * are being reworked; until they are, a failure partway through one of them
 * can leave money and stock records inconsistent.
 */
/**
 * The columns Postgres types as `Json` and SQLite has to keep as text.
 *
 * Business code passes and expects objects — `before: { mortality: 6 }` — and
 * should not have to know which database is underneath. So the translation
 * happens here, once, rather than at every call site with a conditional that
 * would be wrong on Postgres.
 */
const JSON_FIELDS: Record<string, string[]> = {
  AuditLog: ['before', 'after'],
  Notification: ['payload'],
  OrgSetting: ['value'],
  BatchClosure: ['summaryMetrics'],
};

/** Serialise on the way in; anything already a string is left alone. */
function encode(model: string | undefined, data: unknown): unknown {
  const fields = model ? JSON_FIELDS[model] : undefined;
  if (!fields || !data || typeof data !== 'object') return data;
  if (Array.isArray(data)) return data.map((d) => encode(model, d));
  const out: Record<string, unknown> = { ...(data as Record<string, unknown>) };
  for (const f of fields) {
    const v = out[f];
    if (v !== undefined && v !== null && typeof v !== 'string') {
      out[f] = JSON.stringify(v);
    }
  }
  return out;
}

/** Parse on the way out, so a reader still gets the object it expects. */
function decode(model: string | undefined, row: unknown): unknown {
  const fields = model ? JSON_FIELDS[model] : undefined;
  if (!fields || !row || typeof row !== 'object') return row;
  if (Array.isArray(row)) return row.map((r) => decode(model, r));
  const out = row as Record<string, unknown>;
  for (const f of fields) {
    if (typeof out[f] === 'string') {
      try {
        out[f] = JSON.parse(out[f] as string);
      } catch {
        // Not JSON after all — leave the raw text rather than lose it.
      }
    }
  }
  return out;
}

export function createD1Client(db: D1Database): PrismaClient {
  if (!db) {
    throw new Error(
      'createD1Client needs the D1 binding. Bind the database as DB in ' +
        'wrangler.toml — see [[d1_databases]].',
    );
  }
  const client = new PrismaClient({ adapter: new PrismaD1(db), log: ['error'] });

  return client.$extends({
    query: {
      $allModels: {
        async $allOperations({ model, args, query }) {
          const a = args as Record<string, unknown> | undefined;
          if (a) {
            if (a.data) a.data = encode(model, a.data);
            if (a.create) a.create = encode(model, a.create);
            if (a.update) a.update = encode(model, a.update);
          }
          return decode(model, await query(args));
        },
      },
    },
  }) as unknown as PrismaClient;
}

export type { D1Database };

export {
  setPrismaClient,
  setPrismaResolver,
  currentPrismaClient,
  setScalarListsAreJson,
  readList,
  writeList,
  readJson,
  writeJson,
} from './runtime';
export * from './rbac';
