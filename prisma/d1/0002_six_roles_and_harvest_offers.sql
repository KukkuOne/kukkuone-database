-- Catches D1 up with schema.d1.prisma.
--
-- The six-role restructure and the addressed harvest offers both changed
-- schema.d1.prisma — so the generated client queries these columns and tables —
-- but no D1 migration was ever written for them. 0001_init.sql was the only
-- one, and the dev database still matched it. The result was that every
-- sign-in failed on `prisma.membership.findFirst()` with
--
--   D1_ERROR: no such column: main.Organization.tradingCapabilities
--
-- which is not a useful thing for a farmer to be shown.
--
-- Everything here is additive: three nullable columns and three new tables.
-- No existing row changes and nothing is dropped, so this is safe to apply to
-- a database that is already serving.
--
-- Postgres has its own migration for the same change
-- (20260929192623_trading_capabilities and the harvest-offer migrations). This
-- is the D1 port, and it differs where SQLite demands it: no enum types, so
-- status and kind are TEXT; no array columns, so tradingCapabilities is TEXT
-- holding a JSON array, exactly as `capabilities` beside it already is.

-- ── Organization.tradingCapabilities ────────────────────────────────────────
--
-- NOT NULL with a default, because the column is non-nullable in the schema and
-- existing rows need a value. '[]' is the right one: no organisation holds
-- TRADING_PARTNER yet, and for one that does, empty means "not stated" rather
-- than "none".
ALTER TABLE "Organization" ADD COLUMN "tradingCapabilities" TEXT NOT NULL DEFAULT '[]';

-- ── Sale: the other two parties to a deal ───────────────────────────────────
--
-- Nullable, and left null for every existing sale. A Lifting Partner is not
-- automatically the buyer and the party that pays may be neither; back-filling
-- these from buyerId would invent a fact about who did what.
ALTER TABLE "Sale" ADD COLUMN "liftingPartyId" TEXT;
ALTER TABLE "Sale" ADD COLUMN "facilitatorId" TEXT;

-- ── Harvest offers ──────────────────────────────────────────────────────────
--
-- An offer addressed to named businesses, which is the replacement for the
-- legacy NETWORK broadcast on Batch.
CREATE TABLE "HarvestOffer" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "orgId" TEXT NOT NULL,
    "batchId" TEXT NOT NULL,
    "birds" INTEGER NOT NULL,
    "avgWeightGrams" INTEGER,
    "readyDate" DATETIME NOT NULL,
    "askRate" INTEGER,
    "farmName" TEXT NOT NULL,
    "place" TEXT,
    "breed" TEXT,
    "notes" TEXT,
    "status" TEXT NOT NULL DEFAULT 'OPEN',
    "offeredAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "closedAt" DATETIME,
    "createdBy" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "HarvestOffer_batchId_fkey" FOREIGN KEY ("batchId") REFERENCES "Batch" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE INDEX "HarvestOffer_orgId_status_idx" ON "HarvestOffer"("orgId", "status");
CREATE INDEX "HarvestOffer_batchId_idx" ON "HarvestOffer"("batchId");

-- Who the offer was put in front of. viaOrgId is not here: it is on the
-- Postgres side of the forwarding work and schema.d1.prisma does not carry it,
-- so adding it would put D1 ahead of its own schema rather than level with it.
CREATE TABLE "HarvestOfferRecipient" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "offerId" TEXT NOT NULL,
    "orgId" TEXT NOT NULL,
    "partyId" TEXT,
    "seenAt" DATETIME,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "HarvestOfferRecipient_offerId_fkey" FOREIGN KEY ("offerId") REFERENCES "HarvestOffer" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE UNIQUE INDEX "HarvestOfferRecipient_offerId_orgId_key" ON "HarvestOfferRecipient"("offerId", "orgId");
CREATE INDEX "HarvestOfferRecipient_orgId_idx" ON "HarvestOfferRecipient"("orgId");

-- What they said back. Kept when an offer is withdrawn: what somebody agreed to
-- last week is a fact about the deal whether or not the offer still stands.
CREATE TABLE "HarvestOfferResponse" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "offerId" TEXT NOT NULL,
    "orgId" TEXT NOT NULL,
    "kind" TEXT NOT NULL,
    "birds" INTEGER,
    "rate" INTEGER,
    "pickupDate" DATETIME,
    "notes" TEXT,
    "respondedBy" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "HarvestOfferResponse_offerId_fkey" FOREIGN KEY ("offerId") REFERENCES "HarvestOffer" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX "HarvestOfferResponse_offerId_idx" ON "HarvestOfferResponse"("offerId");
CREATE INDEX "HarvestOfferResponse_orgId_idx" ON "HarvestOfferResponse"("orgId");
