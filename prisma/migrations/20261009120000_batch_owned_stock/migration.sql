-- Phase 1: stock belongs to a batch, not to a calendar or a farm.
--
-- A farmer buys twenty bags for the flock going into Shed 2, not for "the
-- farm". Holding every purchase in one farm store meant the only honest way
-- to charge a batch was to wait for it to eat, and the question a farmer
-- actually asks — "what did I put into this batch and what did I get back" —
-- had no column to read.
--
-- So a movement now names its batch. The costing rule does not change: a
-- batch is charged when it consumes, at its store's weighted average, so a
-- batch holding stock it has not fed yet is not charged for it. What changes
-- is who may draw on those kilos and whose sheet shows them as held.
--
-- A null batchId is still meaningful and still used: stock the farm holds
-- rather than any one flock — an opening balance, a bulk buy before placement,
-- or surplus handed back when a shed closes with no successor placed.

-- AlterEnum — the two legs of a carry-forward. Added before the tables, as
-- every other enum change in this folder is: a value cannot be used in the
-- transaction that adds it, and nothing here uses them.
ALTER TYPE "StockMovementKind" ADD VALUE 'TRANSFER_OUT';
ALTER TYPE "StockMovementKind" ADD VALUE 'TRANSFER_IN';

-- AlterTable
ALTER TABLE "FeedInventory" ADD COLUMN "batchId" TEXT;
ALTER TABLE "FeedInventory" ADD COLUMN "transferId" TEXT;
ALTER TABLE "MedicineInventory" ADD COLUMN "batchId" TEXT;
ALTER TABLE "MedicineInventory" ADD COLUMN "transferId" TEXT;

-- ── the carry-forward ────────────────────────────────────────────────────
-- Leftovers move between batches only because somebody said so. Both legs are
-- written under one row here or neither is, so stock can never leave a batch
-- without arriving somewhere.
CREATE TABLE "StockTransfer" (
    "id" TEXT NOT NULL,
    "orgId" TEXT NOT NULL,
    "fromBatchId" TEXT,
    "toBatchId" TEXT,
    "date" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "value" INTEGER NOT NULL DEFAULT 0,
    "currency" TEXT NOT NULL DEFAULT 'INR',
    "notes" TEXT,
    "createdBy" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "StockTransfer_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "StockTransfer_orgId_fromBatchId_idx" ON "StockTransfer"("orgId", "fromBatchId");
CREATE INDEX "StockTransfer_orgId_toBatchId_idx" ON "StockTransfer"("orgId", "toBatchId");
CREATE INDEX "FeedInventory_orgId_batchId_idx" ON "FeedInventory"("orgId", "batchId");
CREATE INDEX "MedicineInventory_orgId_batchId_idx" ON "MedicineInventory"("orgId", "batchId");

ALTER TABLE "StockTransfer" ADD CONSTRAINT "StockTransfer_fromBatchId_fkey"
    FOREIGN KEY ("fromBatchId") REFERENCES "Batch"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "StockTransfer" ADD CONSTRAINT "StockTransfer_toBatchId_fkey"
    FOREIGN KEY ("toBatchId") REFERENCES "Batch"("id") ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "FeedInventory" ADD CONSTRAINT "FeedInventory_batchId_fkey"
    FOREIGN KEY ("batchId") REFERENCES "Batch"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "FeedInventory" ADD CONSTRAINT "FeedInventory_transferId_fkey"
    FOREIGN KEY ("transferId") REFERENCES "StockTransfer"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "MedicineInventory" ADD CONSTRAINT "MedicineInventory_batchId_fkey"
    FOREIGN KEY ("batchId") REFERENCES "Batch"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "MedicineInventory" ADD CONSTRAINT "MedicineInventory_transferId_fkey"
    FOREIGN KEY ("transferId") REFERENCES "StockTransfer"("id") ON DELETE CASCADE ON UPDATE CASCADE;
