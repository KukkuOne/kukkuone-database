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
export function createD1Client(db: D1Database): PrismaClient {
  if (!db) {
    throw new Error(
      'createD1Client needs the D1 binding. Bind the database as DB in ' +
        'wrangler.toml — see [[d1_databases]].',
    );
  }
  return new PrismaClient({ adapter: new PrismaD1(db), log: ['error'] });
}

export type { D1Database };

export { setPrismaClient, setPrismaResolver, currentPrismaClient } from './runtime';
export * from './rbac';
