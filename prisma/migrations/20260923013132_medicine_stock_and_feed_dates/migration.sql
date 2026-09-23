-- Feed and medicine move the same three ways, so the vocabulary is shared.
-- Renamed in place: recreating the type would drop every existing movement.
ALTER TYPE "FeedMovementKind" RENAME TO "StockMovementKind";

-- A movement without a date cannot be counted, aged or reversed.
ALTER TABLE "FeedInventory" ADD COLUMN "date" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;

-- Medicine gains the store feed already had.
CREATE TABLE "MedicineInventory" (
    "id" TEXT NOT NULL,
    "orgId" TEXT NOT NULL,
    "farmId" TEXT,
    "medicineItemId" TEXT NOT NULL,
    "kind" "StockMovementKind" NOT NULL DEFAULT 'PURCHASE',
    "reason" TEXT,
    "qty" INTEGER NOT NULL DEFAULT 0,
    "supplierId" TEXT,
    "unitCost" INTEGER,
    "currency" TEXT NOT NULL DEFAULT 'INR',
    "expiryDate" TIMESTAMP(3),
    "date" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "MedicineInventory_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "MedicineInventory_orgId_medicineItemId_idx"
    ON "MedicineInventory"("orgId", "medicineItemId");

ALTER TABLE "MedicineInventory" ADD CONSTRAINT "MedicineInventory_medicineItemId_fkey"
    FOREIGN KEY ("medicineItemId") REFERENCES "MedicineItem"("id")
    ON DELETE RESTRICT ON UPDATE CASCADE;
