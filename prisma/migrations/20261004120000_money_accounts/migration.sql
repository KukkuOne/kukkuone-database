-- CreateEnum
CREATE TYPE "EntryDirection" AS ENUM ('IN', 'OUT');

-- CreateEnum
CREATE TYPE "AccountEntryKind" AS ENUM ('OPENING', 'OWNER_IN', 'OWNER_OUT', 'TRANSFER', 'OTHER_INCOME', 'OTHER_EXPENSE');

-- AlterEnum
-- This migration adds more than one value to an enum.
-- With PostgreSQL versions 11 and earlier, this is not possible
-- in a single migration. This can be worked around by creating
-- multiple migrations, each migration adding only one value to
-- the enum.


ALTER TYPE "RevenueSource" ADD VALUE 'LITTER';
ALTER TYPE "RevenueSource" ADD VALUE 'GUNNY_BAG';
ALTER TYPE "RevenueSource" ADD VALUE 'FEED_RESALE';

-- AlterEnum
ALTER TYPE "StockMovementKind" ADD VALUE 'SALE';

-- DropForeignKey
ALTER TABLE "Revenue" DROP CONSTRAINT "Revenue_batchId_fkey";

-- AlterTable
ALTER TABLE "BuyerPayment" ADD COLUMN     "accountId" TEXT;

-- AlterTable
ALTER TABLE "Expense" ADD COLUMN     "accountId" TEXT;

-- AlterTable
ALTER TABLE "Revenue" ADD COLUMN     "farmId" TEXT,
ADD COLUMN     "notes" TEXT,
ADD COLUMN     "partyId" TEXT,
ALTER COLUMN "batchId" DROP NOT NULL;

-- AlterTable
ALTER TABLE "SupplierPayment" ADD COLUMN     "accountId" TEXT;

-- CreateTable
CREATE TABLE "AccountType" (
    "id" TEXT NOT NULL,
    "orgId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "system" BOOLEAN NOT NULL DEFAULT false,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "archivedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "AccountType_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Account" (
    "id" TEXT NOT NULL,
    "orgId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "typeId" TEXT,
    "parentId" TEXT,
    "farmId" TEXT,
    "isDefault" BOOLEAN NOT NULL DEFAULT false,
    "openingBalance" INTEGER NOT NULL DEFAULT 0,
    "openedOn" TIMESTAMP(3),
    "currency" TEXT NOT NULL DEFAULT 'INR',
    "archivedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Account_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AccountEntry" (
    "id" TEXT NOT NULL,
    "orgId" TEXT NOT NULL,
    "accountId" TEXT NOT NULL,
    "date" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "direction" "EntryDirection" NOT NULL,
    "kind" "AccountEntryKind" NOT NULL,
    "amount" INTEGER NOT NULL,
    "partyId" TEXT,
    "transferId" TEXT,
    "notes" TEXT,
    "createdBy" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AccountEntry_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "AccountType_orgId_idx" ON "AccountType"("orgId");

-- CreateIndex
CREATE UNIQUE INDEX "AccountType_orgId_name_key" ON "AccountType"("orgId", "name");

-- CreateIndex
CREATE INDEX "Account_orgId_idx" ON "Account"("orgId");

-- CreateIndex
CREATE INDEX "Account_orgId_parentId_idx" ON "Account"("orgId", "parentId");

-- CreateIndex
CREATE INDEX "AccountEntry_orgId_accountId_date_idx" ON "AccountEntry"("orgId", "accountId", "date");

-- AddForeignKey
ALTER TABLE "Revenue" ADD CONSTRAINT "Revenue_batchId_fkey" FOREIGN KEY ("batchId") REFERENCES "Batch"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Revenue" ADD CONSTRAINT "Revenue_partyId_fkey" FOREIGN KEY ("partyId") REFERENCES "Party"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Account" ADD CONSTRAINT "Account_typeId_fkey" FOREIGN KEY ("typeId") REFERENCES "AccountType"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Account" ADD CONSTRAINT "Account_parentId_fkey" FOREIGN KEY ("parentId") REFERENCES "Account"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AccountEntry" ADD CONSTRAINT "AccountEntry_accountId_fkey" FOREIGN KEY ("accountId") REFERENCES "Account"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AccountEntry" ADD CONSTRAINT "AccountEntry_partyId_fkey" FOREIGN KEY ("partyId") REFERENCES "Party"("id") ON DELETE SET NULL ON UPDATE CASCADE;

