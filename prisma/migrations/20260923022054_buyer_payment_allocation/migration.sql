-- One receipt is one payment row however many lots it clears; what it cleared
-- moves to its allocations, the mirror of SupplierPaymentAllocation.
CREATE TABLE "BuyerPaymentAllocation" (
    "id" TEXT NOT NULL,
    "orgId" TEXT NOT NULL,
    "paymentId" TEXT NOT NULL,
    "saleId" TEXT NOT NULL,
    "amount" INTEGER NOT NULL,
    CONSTRAINT "BuyerPaymentAllocation_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "BuyerPaymentAllocation_paymentId_saleId_key"
    ON "BuyerPaymentAllocation"("paymentId", "saleId");
CREATE INDEX "BuyerPaymentAllocation_orgId_saleId_idx"
    ON "BuyerPaymentAllocation"("orgId", "saleId");

ALTER TABLE "BuyerPaymentAllocation" ADD CONSTRAINT "BuyerPaymentAllocation_paymentId_fkey"
    FOREIGN KEY ("paymentId") REFERENCES "BuyerPayment"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "BuyerPaymentAllocation" ADD CONSTRAINT "BuyerPaymentAllocation_saleId_fkey"
    FOREIGN KEY ("saleId") REFERENCES "Sale"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- Carry every existing payment's single sale across, capped at what that lot
-- is worth so the migration can never create an over-settled lot.
INSERT INTO "BuyerPaymentAllocation" ("id", "orgId", "paymentId", "saleId", "amount")
SELECT gen_random_uuid()::text, p."orgId", p.id, p."saleId", LEAST(p.amount, s.amount)
FROM "BuyerPayment" p
JOIN "Sale" s ON s.id = p."saleId"
WHERE p."saleId" IS NOT NULL AND p.amount > 0;

ALTER TABLE "BuyerPayment" DROP CONSTRAINT "BuyerPayment_saleId_fkey";
ALTER TABLE "BuyerPayment" DROP COLUMN "saleId";
