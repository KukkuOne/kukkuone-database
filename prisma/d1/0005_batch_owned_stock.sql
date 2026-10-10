-- Phase 1: stock belongs to a batch, not to a farm.
--
-- See prisma/migrations/20261009120000_batch_owned_stock for why. Hand-written
-- because prisma migrate does not touch D1. SQLite has no enums, so the two
-- new movement kinds (TRANSFER_OUT, TRANSFER_IN) need no DDL here — kind is
-- already TEXT.

ALTER TABLE "FeedInventory" ADD COLUMN "batchId" TEXT;
ALTER TABLE "FeedInventory" ADD COLUMN "transferId" TEXT;
ALTER TABLE "MedicineInventory" ADD COLUMN "batchId" TEXT;
ALTER TABLE "MedicineInventory" ADD COLUMN "transferId" TEXT;

CREATE INDEX "FeedInventory_orgId_batchId_idx" ON "FeedInventory"("orgId", "batchId");
CREATE INDEX "MedicineInventory_orgId_batchId_idx" ON "MedicineInventory"("orgId", "batchId");

-- ── the carry-forward ────────────────────────────────────────────────────
-- Leftovers move between batches only because somebody said so. Both legs are
-- written under one row here or neither is, so stock can never leave a batch
-- without arriving somewhere. Either side may be null: that is the farm's own
-- store, which is where a batch closing into an empty shed puts its surplus.
CREATE TABLE "StockTransfer" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "orgId" TEXT NOT NULL,
    "fromBatchId" TEXT,
    "toBatchId" TEXT,
    "date" DATETIME NOT NULL,
    "value" INTEGER NOT NULL DEFAULT 0,
    "currency" TEXT NOT NULL DEFAULT 'INR',
    "notes" TEXT,
    "createdBy" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL
);
CREATE INDEX "StockTransfer_orgId_fromBatchId_idx" ON "StockTransfer"("orgId", "fromBatchId");
CREATE INDEX "StockTransfer_orgId_toBatchId_idx" ON "StockTransfer"("orgId", "toBatchId");
