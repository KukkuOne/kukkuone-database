-- CreateEnum
CREATE TYPE "PartyKind" AS ENUM ('HATCHERY', 'FEED_SUPPLIER', 'BUYER');

-- CreateEnum
CREATE TYPE "SaleRateBasis" AS ENUM ('MARKET', 'FIXED');

-- CreateEnum
CREATE TYPE "FeedMovementKind" AS ENUM ('PURCHASE', 'RETURN', 'ADJUSTMENT');

-- AlterEnum
-- This migration adds more than one value to an enum.
-- With PostgreSQL versions 11 and earlier, this is not possible
-- in a single migration. This can be worked around by creating
-- multiple migrations, each migration adding only one value to
-- the enum.


ALTER TYPE "ExpenseCategory" ADD VALUE 'RENT';
ALTER TYPE "ExpenseCategory" ADD VALUE 'LITTER';
ALTER TYPE "ExpenseCategory" ADD VALUE 'GAS';
ALTER TYPE "ExpenseCategory" ADD VALUE 'REPAIRS';
ALTER TYPE "ExpenseCategory" ADD VALUE 'CLEANING';

-- DropForeignKey
ALTER TABLE "Expense" DROP CONSTRAINT "Expense_batchId_fkey";

-- AlterTable
ALTER TABLE "Expense" ADD COLUMN     "autoAccrued" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "billKey" TEXT,
ADD COLUMN     "farmId" TEXT,
ADD COLUMN     "paid" BOOLEAN NOT NULL DEFAULT true,
ADD COLUMN     "periodMonth" TIMESTAMP(3),
ALTER COLUMN "batchId" DROP NOT NULL;

-- AlterTable
ALTER TABLE "FeedInventory" ADD COLUMN     "farmId" TEXT,
ADD COLUMN     "kind" "FeedMovementKind" NOT NULL DEFAULT 'PURCHASE',
ADD COLUMN     "reason" TEXT;

-- AlterTable
ALTER TABLE "MedicineItem" ADD COLUMN     "withdrawalDays" INTEGER NOT NULL DEFAULT 0;

-- AlterTable
ALTER TABLE "MedicineUsage" ADD COLUMN     "endDate" TIMESTAMP(3),
ADD COLUMN     "reason" TEXT,
ADD COLUMN     "withdrawalDays" INTEGER NOT NULL DEFAULT 0;

-- AlterTable
ALTER TABLE "Sale" ADD COLUMN     "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN     "createdBy" TEXT,
ADD COLUMN     "date" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN     "declaredRate" INTEGER,
ADD COLUMN     "discount" INTEGER,
ADD COLUMN     "notes" TEXT,
ADD COLUMN     "slipKey" TEXT,
ADD COLUMN     "vehicle" TEXT;

-- CreateTable
CREATE TABLE "Party" (
    "id" TEXT NOT NULL,
    "orgId" TEXT NOT NULL,
    "kind" "PartyKind" NOT NULL,
    "name" TEXT NOT NULL,
    "phone" TEXT,
    "place" TEXT,
    "declaredRate" INTEGER,
    "discount" INTEGER,
    "rateBasis" "SaleRateBasis" NOT NULL DEFAULT 'MARKET',
    "creditDays" INTEGER NOT NULL DEFAULT 15,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Party_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ExpenseAllocation" (
    "id" TEXT NOT NULL,
    "orgId" TEXT NOT NULL,
    "expenseId" TEXT NOT NULL,
    "batchId" TEXT NOT NULL,
    "amount" INTEGER NOT NULL,
    "birdDays" INTEGER NOT NULL DEFAULT 0,
    "manual" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ExpenseAllocation_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "BuyerPayment" (
    "id" TEXT NOT NULL,
    "orgId" TEXT NOT NULL,
    "partyId" TEXT NOT NULL,
    "saleId" TEXT,
    "date" TIMESTAMP(3) NOT NULL,
    "amount" INTEGER NOT NULL,
    "mode" TEXT NOT NULL DEFAULT 'CASH',
    "reference" TEXT,
    "notes" TEXT,
    "createdBy" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "BuyerPayment_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "Party_orgId_kind_idx" ON "Party"("orgId", "kind");

-- CreateIndex
CREATE INDEX "ExpenseAllocation_orgId_batchId_idx" ON "ExpenseAllocation"("orgId", "batchId");

-- CreateIndex
CREATE UNIQUE INDEX "ExpenseAllocation_expenseId_batchId_key" ON "ExpenseAllocation"("expenseId", "batchId");

-- CreateIndex
CREATE INDEX "BuyerPayment_orgId_partyId_idx" ON "BuyerPayment"("orgId", "partyId");

-- AddForeignKey
ALTER TABLE "Expense" ADD CONSTRAINT "Expense_batchId_fkey" FOREIGN KEY ("batchId") REFERENCES "Batch"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ExpenseAllocation" ADD CONSTRAINT "ExpenseAllocation_expenseId_fkey" FOREIGN KEY ("expenseId") REFERENCES "Expense"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ExpenseAllocation" ADD CONSTRAINT "ExpenseAllocation_batchId_fkey" FOREIGN KEY ("batchId") REFERENCES "Batch"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Sale" ADD CONSTRAINT "Sale_buyerId_fkey" FOREIGN KEY ("buyerId") REFERENCES "Party"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "BuyerPayment" ADD CONSTRAINT "BuyerPayment_partyId_fkey" FOREIGN KEY ("partyId") REFERENCES "Party"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "BuyerPayment" ADD CONSTRAINT "BuyerPayment_saleId_fkey" FOREIGN KEY ("saleId") REFERENCES "Sale"("id") ON DELETE SET NULL ON UPDATE CASCADE;
