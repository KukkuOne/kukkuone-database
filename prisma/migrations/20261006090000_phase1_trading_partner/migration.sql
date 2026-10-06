-- CreateEnum
CREATE TYPE "InputOrderStatus" AS ENUM ('PLACED', 'ACCEPTED', 'DELIVERED', 'INVOICED', 'SETTLED', 'CANCELLED');

-- CreateTable
CREATE TABLE "Partnership" (
    "id" TEXT NOT NULL,
    "farmerOrgId" TEXT NOT NULL,
    "partnerOrgId" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'active',
    "startedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "endedAt" TIMESTAMP(3),
    "createdBy" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Partnership_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ChickRate" (
    "id" TEXT NOT NULL,
    "onDate" TIMESTAMP(3) NOT NULL,
    "paisePerChick" INTEGER NOT NULL,
    "publishedBy" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ChickRate_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "InputOrder" (
    "id" TEXT NOT NULL,
    "orgId" TEXT NOT NULL,
    "farmerOrgId" TEXT NOT NULL,
    "kind" "ProductKind" NOT NULL,
    "hatcheryOrgId" TEXT,
    "hatcheryName" TEXT,
    "feedType" TEXT,
    "brand" TEXT,
    "bagSizeKg" INTEGER,
    "qty" INTEGER NOT NULL,
    "needBy" TIMESTAMP(3),
    "notes" TEXT,
    "unitPrice" INTEGER,
    "costPrice" INTEGER,
    "batchId" TEXT,
    "status" "InputOrderStatus" NOT NULL DEFAULT 'PLACED',
    "createdBy" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "InputOrder_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "InputDelivery" (
    "id" TEXT NOT NULL,
    "orderId" TEXT NOT NULL,
    "deliveredOn" TIMESTAMP(3) NOT NULL,
    "received" INTEGER NOT NULL,
    "dead" INTEGER NOT NULL DEFAULT 0,
    "weak" INTEGER NOT NULL DEFAULT 0,
    "billable" INTEGER NOT NULL,
    "replacing" INTEGER NOT NULL DEFAULT 0,
    "note" TEXT,
    "recordedBy" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "InputDelivery_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "CommissionRate" (
    "id" TEXT NOT NULL,
    "orgId" TEXT NOT NULL,
    "kind" TEXT NOT NULL,
    "farmerOrgId" TEXT,
    "perUnit" INTEGER,
    "basisPoints" INTEGER,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "CommissionRate_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "LiftingRequirement" (
    "id" TEXT NOT NULL,
    "orgId" TEXT NOT NULL,
    "birds" INTEGER NOT NULL,
    "wantBy" TIMESTAMP(3),
    "place" TEXT,
    "notes" TEXT,
    "status" TEXT NOT NULL DEFAULT 'open',
    "createdBy" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "LiftingRequirement_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "Partnership_partnerOrgId_status_idx" ON "Partnership"("partnerOrgId", "status");

-- CreateIndex
CREATE INDEX "Partnership_farmerOrgId_status_idx" ON "Partnership"("farmerOrgId", "status");

-- CreateIndex
CREATE UNIQUE INDEX "Partnership_farmerOrgId_partnerOrgId_key" ON "Partnership"("farmerOrgId", "partnerOrgId");

-- CreateIndex
CREATE UNIQUE INDEX "ChickRate_onDate_key" ON "ChickRate"("onDate");

-- CreateIndex
CREATE INDEX "InputOrder_orgId_status_idx" ON "InputOrder"("orgId", "status");

-- CreateIndex
CREATE INDEX "InputOrder_farmerOrgId_status_idx" ON "InputOrder"("farmerOrgId", "status");

-- CreateIndex
CREATE UNIQUE INDEX "InputDelivery_orderId_key" ON "InputDelivery"("orderId");

-- CreateIndex
CREATE UNIQUE INDEX "CommissionRate_orgId_kind_farmerOrgId_key" ON "CommissionRate"("orgId", "kind", "farmerOrgId");

-- CreateIndex
CREATE INDEX "LiftingRequirement_orgId_status_idx" ON "LiftingRequirement"("orgId", "status");

-- AddForeignKey
ALTER TABLE "InputDelivery" ADD CONSTRAINT "InputDelivery_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "InputOrder"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

