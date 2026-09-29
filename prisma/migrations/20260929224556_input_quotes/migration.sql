-- Input quotes: a trading partner quoting a farm for chicks or feed.
--
-- InputDealModel is the column the spec actually asks for. As an AGENT the
-- partner arranges a purchase the farm makes from the supplier — the supplier
-- invoices the farm, and the partner is owed a fee. As a RESELLER the partner
-- bought the stock and sells it on — the partner invoices the farm, and the
-- margin is theirs. Nothing may infer that a partner owns inventory because
-- they arranged a deal, which is what recording the model prevents.
--
-- ProductKind becomes a real enum. SupplierProduct.kind stays a bare string:
-- migrating a live column is its own change, and doing it in passing here
-- would put a data migration inside a feature.
--
-- Purely additive: one table and three enums.

-- CreateEnum
CREATE TYPE "ProductKind" AS ENUM ('CHICK', 'FEED');

-- CreateEnum
CREATE TYPE "InputDealModel" AS ENUM ('AGENT', 'RESELLER');

-- CreateEnum
CREATE TYPE "InputQuoteStatus" AS ENUM ('DRAFT', 'SENT', 'ACCEPTED', 'DECLINED', 'WITHDRAWN');

-- CreateTable
CREATE TABLE "InputQuote" (
    "id" TEXT NOT NULL,
    "orgId" TEXT NOT NULL,
    "farmerOrgId" TEXT NOT NULL,
    "kind" "ProductKind" NOT NULL,
    "model" "InputDealModel" NOT NULL,
    "qty" INTEGER NOT NULL,
    "unit" TEXT NOT NULL,
    "unitPrice" INTEGER NOT NULL,
    "feePerUnit" INTEGER,
    "supplierOrgId" TEXT,
    "currency" TEXT NOT NULL DEFAULT 'INR',
    "deliveryBy" TIMESTAMP(3),
    "validUntil" TIMESTAMP(3),
    "terms" TEXT,
    "notes" TEXT,
    "status" "InputQuoteStatus" NOT NULL DEFAULT 'SENT',
    "respondedAt" TIMESTAMP(3),
    "createdBy" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "InputQuote_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "InputQuote_orgId_status_idx" ON "InputQuote"("orgId", "status");

-- CreateIndex
CREATE INDEX "InputQuote_farmerOrgId_status_idx" ON "InputQuote"("farmerOrgId", "status");

