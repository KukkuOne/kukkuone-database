-- Accepting a quote makes an order.
--
-- SupplierOrder.sourceQuoteId is unique, which is what makes "one accepted
-- quote, one order" a guarantee the database keeps rather than something the
-- application remembers — two acceptances racing cannot produce two orders.
--
-- dealModel and facilitatorOrgId record who the order is actually against.
-- Under a reseller quote the partner is the seller and orgId is theirs; under
-- an agent quote the supplier sells and the partner is the facilitator, owed a
-- fee that is deliberately NOT part of the order total. Adding them would
-- invoice one party for the other's money.
--
-- OrderLine.productId becomes nullable. A line from a quote has no catalogue
-- item: the partner quoted a quantity and a price, and inventing a catalogue
-- row to hold it would put something in a supplier catalogue they never
-- listed. Existing lines all have one and are untouched.

-- DropForeignKey
ALTER TABLE "OrderLine" DROP CONSTRAINT "OrderLine_productId_fkey";

-- AlterTable
ALTER TABLE "OrderLine" ADD COLUMN     "description" TEXT,
ALTER COLUMN "productId" DROP NOT NULL;

-- AlterTable
ALTER TABLE "SupplierOrder" ADD COLUMN     "dealModel" "InputDealModel",
ADD COLUMN     "facilitationFee" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN     "facilitatorOrgId" TEXT,
ADD COLUMN     "sourceQuoteId" TEXT;

-- CreateIndex
CREATE UNIQUE INDEX "SupplierOrder_sourceQuoteId_key" ON "SupplierOrder"("sourceQuoteId");

-- AddForeignKey
ALTER TABLE "OrderLine" ADD CONSTRAINT "OrderLine_productId_fkey" FOREIGN KEY ("productId") REFERENCES "Product"("id") ON DELETE SET NULL ON UPDATE CASCADE;

