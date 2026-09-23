import { PrismaClient } from '@prisma/client';
import { proxyPrisma } from './runtime';

/**
 * Single shared Prisma client. All services import the client from here —
 * there is exactly one schema and one DATABASE_URL (see docs/04 §5, docs/06).
 *
 * The export is a proxy so a runtime that cannot make its own client at import
 * time — a Cloudflare Worker — can supply one during bootstrap instead. On
 * Node nothing changes: the first property access builds the singleton below
 * and every later one reuses it. See ./runtime.ts.
 */
const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient };

export const prisma = proxyPrisma(() => {
  const client =
    globalForPrisma.prisma ??
    new PrismaClient({
      log: process.env.NODE_ENV === 'development' ? ['warn', 'error'] : ['error'],
    });
  if (process.env.NODE_ENV !== 'production') {
    globalForPrisma.prisma = client;
  }
  return client;
});

export { setPrismaClient, setPrismaResolver, currentPrismaClient } from './runtime';
export * from '@prisma/client';
export { PrismaClient } from '@prisma/client';
export * from './rbac';
