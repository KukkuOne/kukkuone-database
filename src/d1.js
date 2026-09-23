"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __exportStar = (this && this.__exportStar) || function(m, exports) {
    for (var p in m) if (p !== "default" && !Object.prototype.hasOwnProperty.call(exports, p)) __createBinding(exports, m, p);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.currentPrismaClient = exports.setPrismaResolver = exports.setPrismaClient = void 0;
exports.createD1Client = createD1Client;
const adapter_d1_1 = require("@prisma/adapter-d1");
const client_d1_1 = require("../node_modules/.prisma/client-d1");
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
function createD1Client(db) {
    if (!db) {
        throw new Error('createD1Client needs the D1 binding. Bind the database as DB in ' +
            'wrangler.toml — see [[d1_databases]].');
    }
    return new client_d1_1.PrismaClient({ adapter: new adapter_d1_1.PrismaD1(db), log: ['error'] });
}
var runtime_1 = require("./runtime");
Object.defineProperty(exports, "setPrismaClient", { enumerable: true, get: function () { return runtime_1.setPrismaClient; } });
Object.defineProperty(exports, "setPrismaResolver", { enumerable: true, get: function () { return runtime_1.setPrismaResolver; } });
Object.defineProperty(exports, "currentPrismaClient", { enumerable: true, get: function () { return runtime_1.currentPrismaClient; } });
__exportStar(require("./rbac"), exports);
//# sourceMappingURL=d1.js.map