-- Medicine is bought from someone too.
ALTER TYPE "PartyKind" ADD VALUE 'MEDICINE_SUPPLIER';

-- Who a bill is owed to. Null on a cost with no counterparty (accrued rent).
ALTER TABLE "Expense" ADD COLUMN "partyId" TEXT;
CREATE INDEX "Expense_orgId_partyId_idx" ON "Expense"("orgId", "partyId");
ALTER TABLE "Expense" ADD CONSTRAINT "Expense_partyId_fkey"
    FOREIGN KEY ("partyId") REFERENCES "Party"("id")
    ON DELETE SET NULL ON UPDATE CASCADE;

-- The mirror of BuyerPayment: money going out.
CREATE TABLE "SupplierPayment" (
    "id" TEXT NOT NULL,
    "orgId" TEXT NOT NULL,
    "partyId" TEXT NOT NULL,
    "expenseId" TEXT,
    "date" TIMESTAMP(3) NOT NULL,
    "amount" INTEGER NOT NULL,
    "mode" TEXT NOT NULL DEFAULT 'CASH',
    "reference" TEXT,
    "notes" TEXT,
    "createdBy" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "SupplierPayment_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "SupplierPayment_orgId_partyId_idx" ON "SupplierPayment"("orgId", "partyId");

ALTER TABLE "SupplierPayment" ADD CONSTRAINT "SupplierPayment_partyId_fkey"
    FOREIGN KEY ("partyId") REFERENCES "Party"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "SupplierPayment" ADD CONSTRAINT "SupplierPayment_expenseId_fkey"
    FOREIGN KEY ("expenseId") REFERENCES "Expense"("id") ON DELETE SET NULL ON UPDATE CASCADE;
