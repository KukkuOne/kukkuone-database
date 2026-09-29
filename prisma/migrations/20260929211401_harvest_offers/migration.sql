-- Harvest offers: a farmer showing a ready lot to named lifting partners.
--
-- A grant rather than a publication. HarvestOfferRecipient is the grant — an
-- organisation sees an offer if and only if it has a row there — and the offer
-- carries its own snapshot of the lot so a recipient reads what they were told
-- rather than gaining a window onto the batch. Mortality, medicine, cost and
-- margin are not reachable from any of this.
--
-- Purely additive: three new tables and two enums. Batch.harvestVisibility is
-- untouched and the existing broadcast keeps working until discovery moves over.

-- CreateEnum
CREATE TYPE "HarvestOfferStatus" AS ENUM ('OPEN', 'CLOSED', 'WITHDRAWN');

-- CreateEnum
CREATE TYPE "HarvestResponseKind" AS ENUM ('INTERESTED', 'DECLINED', 'COUNTER');

-- CreateTable
CREATE TABLE "HarvestOffer" (
    "id" TEXT NOT NULL,
    "orgId" TEXT NOT NULL,
    "batchId" TEXT NOT NULL,
    "birds" INTEGER NOT NULL,
    "avgWeightGrams" INTEGER,
    "readyDate" TIMESTAMP(3) NOT NULL,
    "askRate" INTEGER,
    "farmName" TEXT NOT NULL,
    "place" TEXT,
    "breed" TEXT,
    "notes" TEXT,
    "status" "HarvestOfferStatus" NOT NULL DEFAULT 'OPEN',
    "offeredAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "closedAt" TIMESTAMP(3),
    "createdBy" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "HarvestOffer_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "HarvestOfferRecipient" (
    "id" TEXT NOT NULL,
    "offerId" TEXT NOT NULL,
    "orgId" TEXT NOT NULL,
    "partyId" TEXT,
    "seenAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "HarvestOfferRecipient_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "HarvestOfferResponse" (
    "id" TEXT NOT NULL,
    "offerId" TEXT NOT NULL,
    "orgId" TEXT NOT NULL,
    "kind" "HarvestResponseKind" NOT NULL,
    "birds" INTEGER,
    "rate" INTEGER,
    "pickupDate" TIMESTAMP(3),
    "notes" TEXT,
    "respondedBy" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "HarvestOfferResponse_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "HarvestOffer_orgId_status_idx" ON "HarvestOffer"("orgId", "status");

-- CreateIndex
CREATE INDEX "HarvestOffer_batchId_idx" ON "HarvestOffer"("batchId");

-- CreateIndex
CREATE INDEX "HarvestOfferRecipient_orgId_idx" ON "HarvestOfferRecipient"("orgId");

-- CreateIndex
CREATE UNIQUE INDEX "HarvestOfferRecipient_offerId_orgId_key" ON "HarvestOfferRecipient"("offerId", "orgId");

-- CreateIndex
CREATE INDEX "HarvestOfferResponse_offerId_idx" ON "HarvestOfferResponse"("offerId");

-- CreateIndex
CREATE INDEX "HarvestOfferResponse_orgId_idx" ON "HarvestOfferResponse"("orgId");

-- AddForeignKey
ALTER TABLE "HarvestOffer" ADD CONSTRAINT "HarvestOffer_batchId_fkey" FOREIGN KEY ("batchId") REFERENCES "Batch"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "HarvestOfferRecipient" ADD CONSTRAINT "HarvestOfferRecipient_offerId_fkey" FOREIGN KEY ("offerId") REFERENCES "HarvestOffer"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "HarvestOfferResponse" ADD CONSTRAINT "HarvestOfferResponse_offerId_fkey" FOREIGN KEY ("offerId") REFERENCES "HarvestOffer"("id") ON DELETE CASCADE ON UPDATE CASCADE;

