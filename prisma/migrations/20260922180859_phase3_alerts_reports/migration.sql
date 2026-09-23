-- CreateEnum
CREATE TYPE "AlertKind" AS ENUM ('NOT_LOGGED', 'MORTALITY_SPIKE', 'MORTALITY_CUMULATIVE', 'FEED_LOW', 'VACCINATION_DUE', 'WEIGHT_BEHIND', 'FCR_DRIFT', 'BATCH_READY', 'PAYMENT_OVERDUE', 'SHED_IDLE');

-- AlterTable
ALTER TABLE "Shed" ADD COLUMN     "notionalRent" INTEGER;

-- CreateTable
CREATE TABLE "Alert" (
    "id" TEXT NOT NULL,
    "orgId" TEXT NOT NULL,
    "kind" "AlertKind" NOT NULL,
    "subjectType" TEXT NOT NULL,
    "subjectId" TEXT NOT NULL,
    "farmId" TEXT,
    "title" TEXT NOT NULL,
    "detail" TEXT NOT NULL,
    "value" DOUBLE PRECISION,
    "dayKey" TEXT NOT NULL,
    "readAt" TIMESTAMP(3),
    "resolvedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Alert_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AlertSetting" (
    "id" TEXT NOT NULL,
    "orgId" TEXT NOT NULL,
    "kind" "AlertKind" NOT NULL,
    "enabled" BOOLEAN NOT NULL DEFAULT true,
    "threshold" DOUBLE PRECISION,

    CONSTRAINT "AlertSetting_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AlertMute" (
    "id" TEXT NOT NULL,
    "orgId" TEXT NOT NULL,
    "kind" "AlertKind" NOT NULL,
    "shedId" TEXT NOT NULL,

    CONSTRAINT "AlertMute_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "BreedStandard" (
    "id" TEXT NOT NULL,
    "orgId" TEXT NOT NULL,
    "breed" TEXT NOT NULL,

    CONSTRAINT "BreedStandard_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "BreedStandardPoint" (
    "id" TEXT NOT NULL,
    "standardId" TEXT NOT NULL,
    "day" INTEGER NOT NULL,
    "weightG" INTEGER NOT NULL,
    "fcr" DOUBLE PRECISION,

    CONSTRAINT "BreedStandardPoint_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "MemberVisibility" (
    "id" TEXT NOT NULL,
    "orgId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "seeCosts" BOOLEAN NOT NULL DEFAULT true,
    "seeRevenue" BOOLEAN NOT NULL DEFAULT false,
    "seeProfit" BOOLEAN NOT NULL DEFAULT false,
    "canPlaceClose" BOOLEAN NOT NULL DEFAULT true,
    "canRecordSales" BOOLEAN NOT NULL DEFAULT false,
    "canAddExpenses" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "MemberVisibility_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "OrgSetting" (
    "orgId" TEXT NOT NULL,
    "key" TEXT NOT NULL,
    "value" JSONB NOT NULL,

    CONSTRAINT "OrgSetting_pkey" PRIMARY KEY ("orgId","key")
);

-- CreateIndex
CREATE INDEX "Alert_orgId_resolvedAt_idx" ON "Alert"("orgId", "resolvedAt");

-- CreateIndex
CREATE UNIQUE INDEX "Alert_orgId_kind_subjectId_dayKey_key" ON "Alert"("orgId", "kind", "subjectId", "dayKey");

-- CreateIndex
CREATE UNIQUE INDEX "AlertSetting_orgId_kind_key" ON "AlertSetting"("orgId", "kind");

-- CreateIndex
CREATE UNIQUE INDEX "AlertMute_orgId_kind_shedId_key" ON "AlertMute"("orgId", "kind", "shedId");

-- CreateIndex
CREATE UNIQUE INDEX "BreedStandard_orgId_breed_key" ON "BreedStandard"("orgId", "breed");

-- CreateIndex
CREATE UNIQUE INDEX "BreedStandardPoint_standardId_day_key" ON "BreedStandardPoint"("standardId", "day");

-- CreateIndex
CREATE UNIQUE INDEX "MemberVisibility_orgId_userId_key" ON "MemberVisibility"("orgId", "userId");

-- AddForeignKey
ALTER TABLE "BreedStandardPoint" ADD CONSTRAINT "BreedStandardPoint_standardId_fkey" FOREIGN KEY ("standardId") REFERENCES "BreedStandard"("id") ON DELETE CASCADE ON UPDATE CASCADE;
