import type { PrismaClient } from '@prisma/client';

/**
 * Which Prisma client the services actually talk to.
 *
 * Every service imports `{ prisma }` from this package at module scope and
 * calls it directly — `prisma.batch.findMany(...)` — in a few hundred places.
 * That is the right shape for a Node process, where there is one client for
 * the life of the process and `DATABASE_URL` is known before the first import.
 *
 * On a Worker neither holds. There is no connection of its own to make, and
 * the connection string arrives per request as a binding, after the module has
 * already been evaluated. Rewriting every call site to accept an injected
 * client would be a large change to working code for the sake of the runtime.
 *
 * So the export stays a value and becomes a proxy. On Node it resolves to the
 * singleton, exactly as before. On a Worker the entry point calls
 * [setPrismaClient] during bootstrap and the proxy resolves to that. Business
 * code does not know the difference, and there is nothing to keep in step.
 */
let resolver: (() => PrismaClient | undefined) | undefined;

/** Point the shared `prisma` export at a client this runtime made itself. */
export function setPrismaClient(client: PrismaClient): void {
  resolver = () => client;
}

/**
 * Point it at a client chosen per call instead of once.
 *
 * A Worker needs this. Cloudflare binds every I/O object — including a
 * database connection — to the request that created it: the connection that
 * served one request cannot serve the next, and attempting it hangs until the
 * runtime cancels the request. So the client has to be per-request, while the
 * services still import one `prisma` at module scope. The resolver is what
 * joins those two facts.
 */
export function setPrismaResolver(fn: () => PrismaClient | undefined): void {
  resolver = fn;
}

/** The client the resolver currently yields, if any. */
export function currentPrismaClient(): PrismaClient | undefined {
  return resolver?.();
}

/**
 * Wrap a lazily-made default in a proxy that prefers the override.
 *
 * `makeDefault` is only called if nothing has been set and something actually
 * touches the client — so importing this package on a Worker never constructs
 * a Node client, and never loads the engine that would fail there.
 */
export function proxyPrisma(makeDefault: () => PrismaClient): PrismaClient {
  let fallback: PrismaClient | undefined;
  const resolve = (): PrismaClient => {
    const supplied = resolver?.();
    if (supplied) return supplied;
    fallback ??= makeDefault();
    return fallback;
  };

  return new Proxy({} as PrismaClient, {
    get(_target, prop, receiver) {
      const client = resolve();
      const value = Reflect.get(client as object, prop, receiver);
      // Methods must keep their `this`, or `prisma.$transaction(...)` and
      // every model delegate lose the client they belong to.
      return typeof value === 'function' ? value.bind(client) : value;
    },
    has: (_t, prop) => Reflect.has(resolve() as object, prop),
    ownKeys: () => Reflect.ownKeys(resolve() as object),
    getOwnPropertyDescriptor: (_t, prop) =>
      Reflect.getOwnPropertyDescriptor(resolve() as object, prop),
  });
}

// ---------------------------------------------------------------------------
// Scalar lists across two databases
// ---------------------------------------------------------------------------
//
// Postgres stores `Organization.capabilities` as a native array. SQLite has no
// array type, so on D1 the same column is a String holding JSON. Business code
// should not have to know which it is talking to — it wants a list either way.
//
// So reads go through [readList], which accepts both shapes, and writes go
// through [writeList], which produces whichever the active database wants.

let listsAreJsonText = false;

/**
 * Say that scalar lists are stored as JSON text rather than as native arrays.
 * Called by a Worker entry point during bootstrap; left false on Node.
 */
export function setScalarListsAreJson(value: boolean): void {
  listsAreJsonText = value;
}

/** Read a scalar list written as either a native array or JSON text. */
export function readList<T = string>(value: unknown): T[] {
  if (Array.isArray(value)) return value as T[];
  if (typeof value !== 'string' || value.length === 0) return [];
  try {
    const parsed = JSON.parse(value);
    return Array.isArray(parsed) ? (parsed as T[]) : [];
  } catch {
    // A value that is not JSON is a single entry, not a crash. This also
    // covers rows written before the column became JSON.
    return [value as unknown as T];
  }
}

/**
 * Write a scalar list in whatever shape the active database stores.
 *
 * The return type is the array, though on D1 the value is JSON text. That is
 * a deliberate cast rather than a union: the two generated Prisma clients type
 * this column differently — `Capability[]` on Postgres, `string` on SQLite —
 * so no single signature can satisfy both type-checkers. Erasing it here keeps
 * the lie in one documented place instead of forcing a cast at every call
 * site. The runtime value is always right for the database in use.
 */
export function writeList<T>(value: T[]): T[] {
  return (listsAreJsonText ? JSON.stringify(value) : value) as unknown as T[];
}

/**
 * Write a JSON column in whatever shape the active database stores.
 *
 * Postgres has a real `Json` type and takes the object. SQLite has none, so on
 * D1 these columns are String and the object has to be serialised. Same
 * deliberate cast as [writeList], and for the same reason: the two generated
 * clients type the column differently, so one signature cannot satisfy both.
 */
export function writeJson<T>(value: T): T {
  return (listsAreJsonText ? JSON.stringify(value) : value) as unknown as T;
}

/** Read a JSON column written as either an object or JSON text. */
export function readJson<T>(value: unknown): T | null {
  if (value == null) return null;
  if (typeof value !== 'string') return value as T;
  try {
    return JSON.parse(value) as T;
  } catch {
    return null;
  }
}
