import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '@prisma/client';
import pg from 'pg';

/**
 * A Prisma client for a runtime with no sockets of its own.
 *
 * The Node services import `prisma` from `./index` — one client, made once,
 * kept for the life of the process. A Worker cannot do either of those things:
 *
 *   - it has no TCP stack, so Prisma's own engine cannot open a connection.
 *     A driver adapter hands the work to `pg`, which on Workers runs over the
 *     socket the platform provides;
 *   - its configuration arrives per request as a binding, not as `process.env`
 *     read at import time. So this is a factory, not a singleton.
 *
 * Point `connectionString` at a Hyperdrive binding rather than straight at the
 * database. Hyperdrive pools connections at the edge; without it every isolate
 * opens its own, and Postgres runs out of connections long before it runs out
 * of work.
 */
export function createPrismaClient(connectionString: string): PrismaClient {
  if (!connectionString) {
    throw new Error(
      'createPrismaClient needs a connection string — pass the Hyperdrive ' +
        'binding’s connectionString, or DATABASE_URL when running without one.',
    );
  }
  const pool = new pg.Pool({ connectionString });
  const adapter = new PrismaPg(pool);
  return new PrismaClient({ adapter, log: ['error'] });
}

export { setPrismaClient, setPrismaResolver, currentPrismaClient } from './runtime';
export * from '@prisma/client';
export { PrismaClient } from '@prisma/client';
export * from './rbac';
