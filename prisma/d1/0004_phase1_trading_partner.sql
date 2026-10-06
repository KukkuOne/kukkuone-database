-- Phase 1: the farm's trading partner, and the orders that go through them.
--
-- The app replaces the phone call and keeps its shape: the farm asks, the
-- partner confirms what it can actually do, the load arrives, and the invoice
-- follows what arrived rather than what was ordered. There is no quote step,
-- because there is none on the phone.
--
-- Hand-written because prisma migrate does not touch D1. SQLite has no enums,
-- so kind and status are TEXT.

-- ── who the farm calls ───────────────────────────────────────────────────
-- A partnership exists before any deal does, which is why it cannot be derived
-- from past orders the way FarmerRelationship is.
CREATE TABLE "Partnership" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "farmerOrgId" TEXT NOT NULL,
    "partnerOrgId" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'active',
    "startedAt" DATETIME NOT NULL,
    "endedAt" DATETIME,
    "createdBy" TEXT,
    "createdAt" DATETIME NOT NULL,
    "updatedAt" DATETIME NOT NULL
);
CREATE UNIQUE INDEX "Partnership_farmerOrgId_partnerOrgId_key" ON "Partnership"("farmerOrgId", "partnerOrgId");
CREATE INDEX "Partnership_partnerOrgId_status_idx" ON "Partnership"("partnerOrgId", "status");
CREATE INDEX "Partnership_farmerOrgId_status_idx" ON "Partnership"("farmerOrgId", "status");

-- ── the day's chick price ────────────────────────────────────────────────
-- One market rate. Hatcheries differ only on the discount they give a partner,
-- so the farm sees one price whoever it picks.
CREATE TABLE "ChickRate" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "onDate" DATETIME NOT NULL,
    "paisePerChick" INTEGER NOT NULL,
    "publishedBy" TEXT,
    "createdAt" DATETIME NOT NULL,
    "updatedAt" DATETIME NOT NULL
);
CREATE UNIQUE INDEX "ChickRate_onDate_key" ON "ChickRate"("onDate");

-- ── what the farm asked its partner for ──────────────────────────────────
-- unitPrice is held at acceptance so a later rate change cannot silently
-- reprice an order somebody already agreed to. costPrice is what the partner
-- paid after its discount, and is never shown to the farm.
CREATE TABLE "InputOrder" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "orgId" TEXT NOT NULL,
    "farmerOrgId" TEXT NOT NULL,
    "kind" TEXT NOT NULL,
    "hatcheryOrgId" TEXT,
    "hatcheryName" TEXT,
    "feedType" TEXT,
    "brand" TEXT,
    "bagSizeKg" INTEGER,
    "qty" INTEGER NOT NULL,
    "needBy" DATETIME,
    "notes" TEXT,
    "unitPrice" INTEGER,
    "costPrice" INTEGER,
    "batchId" TEXT,
    "status" TEXT NOT NULL DEFAULT 'PLACED',
    "createdBy" TEXT,
    "createdAt" DATETIME NOT NULL,
    "updatedAt" DATETIME NOT NULL
);
CREATE INDEX "InputOrder_orgId_status_idx" ON "InputOrder"("orgId", "status");
CREATE INDEX "InputOrder_farmerOrgId_status_idx" ON "InputOrder"("farmerOrgId", "status");

-- ── what actually arrived ────────────────────────────────────────────────
-- billable is the partner's own call, recorded rather than computed: dead and
-- weak birds may be charged, not charged, or replaced on the next load, and
-- which of those happens is a decision between two businesses.
CREATE TABLE "InputDelivery" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "orderId" TEXT NOT NULL,
    "deliveredOn" DATETIME NOT NULL,
    "received" INTEGER NOT NULL,
    "dead" INTEGER NOT NULL DEFAULT 0,
    "weak" INTEGER NOT NULL DEFAULT 0,
    "billable" INTEGER NOT NULL,
    "replacing" INTEGER NOT NULL DEFAULT 0,
    "note" TEXT,
    "recordedBy" TEXT,
    "createdAt" DATETIME NOT NULL,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "InputDelivery_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "InputOrder" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
CREATE UNIQUE INDEX "InputDelivery_orderId_key" ON "InputDelivery"("orderId");

-- ── what the partner takes ───────────────────────────────────────────────
-- A row with no farmerOrgId is the partner's default for everyone; one with it
-- overrides that for a single farm.
CREATE TABLE "CommissionRate" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "orgId" TEXT NOT NULL,
    "kind" TEXT NOT NULL,
    "farmerOrgId" TEXT,
    "perUnit" INTEGER,
    "basisPoints" INTEGER,
    "createdAt" DATETIME NOT NULL,
    "updatedAt" DATETIME NOT NULL
);
CREATE UNIQUE INDEX "CommissionRate_orgId_kind_farmerOrgId_key" ON "CommissionRate"("orgId", "kind", "farmerOrgId");

-- ── the other half of a lifting match ────────────────────────────────────
CREATE TABLE "LiftingRequirement" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "orgId" TEXT NOT NULL,
    "birds" INTEGER NOT NULL,
    "wantBy" DATETIME,
    "place" TEXT,
    "notes" TEXT,
    "status" TEXT NOT NULL DEFAULT 'open',
    "createdBy" TEXT,
    "createdAt" DATETIME NOT NULL,
    "updatedAt" DATETIME NOT NULL
);
CREATE INDEX "LiftingRequirement_orgId_status_idx" ON "LiftingRequirement"("orgId", "status");
