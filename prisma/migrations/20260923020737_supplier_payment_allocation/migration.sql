-- One transfer is one payment row however many bills it clears; what it
-- cleared moves to its allocations. Nothing has been paid yet, so the column
-- it replaces is dropped rather than migrated.
ALTER TABLE "SupplierPayment" DROP CONSTRAINT "SupplierPayment_expenseId_fkey";
ALTER TABLE "SupplierPayment" DROP COLUMN "expenseId";

CREATE TABLE "SupplierPaymentAllocation" (
    "id" TEXT NOT NULL,
    "orgId" TEXT NOT NULL,
    "paymentId" TEXT NOT NULL,
    "expenseId" TEXT NOT NULL,
    "amount" INTEGER NOT NULL,
    CONSTRAINT "SupplierPaymentAllocation_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "SupplierPaymentAllocation_paymentId_expenseId_key"
    ON "SupplierPaymentAllocation"("paymentId", "expenseId");
CREATE INDEX "SupplierPaymentAllocation_orgId_expenseId_idx"
    ON "SupplierPaymentAllocation"("orgId", "expenseId");

ALTER TABLE "SupplierPaymentAllocation" ADD CONSTRAINT "SupplierPaymentAllocation_paymentId_fkey"
    FOREIGN KEY ("paymentId") REFERENCES "SupplierPayment"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "SupplierPaymentAllocation" ADD CONSTRAINT "SupplierPaymentAllocation_expenseId_fkey"
    FOREIGN KEY ("expenseId") REFERENCES "Expense"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
