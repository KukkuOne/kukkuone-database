-- A bird sale names three parties, because they are separately true.
--
-- The buyer owes the money. The lifting party turned up and took the birds, and
-- may be somebody the buyer sent — short weight is argued with whoever did the
-- weighing, so it has to be recorded as its own fact. The facilitator is the
-- trading partner who introduced the two.
--
-- Purely additive. Both new columns are nullable and every existing sale keeps
-- exactly what it had: a buyer and nothing else, which for those rows is the
-- truth as it was recorded rather than a gap to be filled in.
--
-- Prisma warns that adding two enum values at once needs Postgres 12+. That is
-- satisfied here (the database runs 16) and the deployed D1 schema stores this
-- kind as text, so neither target is affected by the older limitation.

-- AlterEnum
-- This migration adds more than one value to an enum.
-- With PostgreSQL versions 11 and earlier, this is not possible
-- in a single migration. This can be worked around by creating
-- multiple migrations, each migration adding only one value to
-- the enum.


ALTER TYPE "PartyKind" ADD VALUE 'LIFTING_PARTNER';
ALTER TYPE "PartyKind" ADD VALUE 'TRADING_PARTNER';

-- AlterTable
ALTER TABLE "Sale" ADD COLUMN     "facilitatorId" TEXT,
ADD COLUMN     "liftingPartyId" TEXT;

-- AddForeignKey
ALTER TABLE "Sale" ADD CONSTRAINT "Sale_liftingPartyId_fkey" FOREIGN KEY ("liftingPartyId") REFERENCES "Party"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Sale" ADD CONSTRAINT "Sale_facilitatorId_fkey" FOREIGN KEY ("facilitatorId") REFERENCES "Party"("id") ON DELETE SET NULL ON UPDATE CASCADE;

