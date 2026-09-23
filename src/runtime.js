"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.setPrismaClient = setPrismaClient;
exports.setPrismaResolver = setPrismaResolver;
exports.currentPrismaClient = currentPrismaClient;
exports.proxyPrisma = proxyPrisma;
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
let resolver;
/** Point the shared `prisma` export at a client this runtime made itself. */
function setPrismaClient(client) {
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
function setPrismaResolver(fn) {
    resolver = fn;
}
/** The client the resolver currently yields, if any. */
function currentPrismaClient() {
    return resolver?.();
}
/**
 * Wrap a lazily-made default in a proxy that prefers the override.
 *
 * `makeDefault` is only called if nothing has been set and something actually
 * touches the client — so importing this package on a Worker never constructs
 * a Node client, and never loads the engine that would fail there.
 */
function proxyPrisma(makeDefault) {
    let fallback;
    const resolve = () => {
        const supplied = resolver?.();
        if (supplied)
            return supplied;
        fallback ??= makeDefault();
        return fallback;
    };
    return new Proxy({}, {
        get(_target, prop, receiver) {
            const client = resolve();
            const value = Reflect.get(client, prop, receiver);
            // Methods must keep their `this`, or `prisma.$transaction(...)` and
            // every model delegate lose the client they belong to.
            return typeof value === 'function' ? value.bind(client) : value;
        },
        has: (_t, prop) => Reflect.has(resolve(), prop),
        ownKeys: () => Reflect.ownKeys(resolve()),
        getOwnPropertyDescriptor: (_t, prop) => Reflect.getOwnPropertyDescriptor(resolve(), prop),
    });
}
//# sourceMappingURL=runtime.js.map