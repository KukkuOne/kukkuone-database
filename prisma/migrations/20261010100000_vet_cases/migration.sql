-- CreateEnum
CREATE TYPE "Organ" AS ENUM ('TRACHEA', 'LUNGS', 'AIR_SACS', 'PERICARDIUM', 'LIVER', 'SPLEEN', 'PROVENTRICULUS', 'GIZZARD', 'INTESTINE', 'CAECA', 'BURSA', 'KIDNEYS', 'JOINTS', 'SKIN', 'NERVES', 'CARCASS');

-- CreateEnum
CREATE TYPE "Lesion" AS ENUM ('HAEMORRHAGE', 'CONGESTION', 'SWELLING', 'NECROSIS', 'CASEOUS_EXUDATE', 'FIBRIN', 'ASCITES', 'PALLOR', 'ATROPHY', 'ULCERATION', 'AIRSACCULITIS', 'NODULES', 'PARASITES', 'NORMAL');

-- CreateEnum
CREATE TYPE "Severity" AS ENUM ('MILD', 'MODERATE', 'SEVERE');

-- CreateEnum
CREATE TYPE "EvidenceGrade" AS ENUM ('PRESUMPTIVE', 'POST_MORTEM', 'LAB_CONFIRMED');

-- CreateEnum
CREATE TYPE "MediaKind" AS ENUM ('BIRD', 'DROPPINGS', 'FLOCK', 'SHED', 'POST_MORTEM', 'DOCUMENT');

-- CreateEnum
CREATE TYPE "VetCaseStatus" AS ENUM ('RAISED', 'TRIAGED', 'VISIT_NEEDED', 'VISITED', 'CLOSED', 'WITHDRAWN');

-- AlterEnum
ALTER TYPE "Capability" ADD VALUE 'VET';

-- AlterEnum
ALTER TYPE "PartyKind" ADD VALUE 'VET';

-- CreateTable
CREATE TABLE "VetCase" (
    "id" TEXT NOT NULL,
    "orgId" TEXT NOT NULL,
    "batchId" TEXT,
    "farmId" TEXT,
    "complaint" TEXT NOT NULL,
    "birdsAffected" INTEGER,
    "birdsDead" INTEGER,
    "status" "VetCaseStatus" NOT NULL DEFAULT 'RAISED',
    "vetOrgId" TEXT,
    "vetUserId" TEXT,
    "trainingConsent" BOOLEAN NOT NULL DEFAULT false,
    "consentAt" TIMESTAMP(3),
    "raisedBy" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "closedAt" TIMESTAMP(3),

    CONSTRAINT "VetCase_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "CaseMedia" (
    "id" TEXT NOT NULL,
    "caseId" TEXT NOT NULL,
    "kind" "MediaKind" NOT NULL,
    "storageKey" TEXT NOT NULL,
    "mimeType" TEXT NOT NULL,
    "bytes" INTEGER,
    "width" INTEGER,
    "height" INTEGER,
    "takenAt" TIMESTAMP(3),
    "birdRef" TEXT,
    "note" TEXT,
    "uploadedBy" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "CaseMedia_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "CaseFinding" (
    "id" TEXT NOT NULL,
    "caseId" TEXT NOT NULL,
    "mediaId" TEXT,
    "organ" "Organ" NOT NULL,
    "lesion" "Lesion" NOT NULL,
    "severity" "Severity" NOT NULL DEFAULT 'MODERATE',
    "region" JSONB,
    "note" TEXT,
    "notedBy" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "CaseFinding_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "CaseDiagnosis" (
    "id" TEXT NOT NULL,
    "caseId" TEXT NOT NULL,
    "diseaseId" TEXT,
    "freeName" TEXT,
    "evidence" "EvidenceGrade" NOT NULL DEFAULT 'PRESUMPTIVE',
    "rank" INTEGER NOT NULL DEFAULT 1,
    "advice" TEXT,
    "diagnosedBy" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "CaseDiagnosis_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Disease" (
    "id" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "nameTe" TEXT,
    "summary" TEXT,
    "summaryTe" TEXT,
    "notifiable" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Disease_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "VetVisit" (
    "id" TEXT NOT NULL,
    "caseId" TEXT NOT NULL,
    "scheduledFor" TIMESTAMP(3),
    "visitedOn" TIMESTAMP(3),
    "birdsExamined" INTEGER NOT NULL DEFAULT 0,
    "summary" TEXT,
    "feePaise" INTEGER,
    "vetUserId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "VetVisit_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "VetCase_orgId_status_idx" ON "VetCase"("orgId", "status");

-- CreateIndex
CREATE INDEX "VetCase_vetOrgId_status_idx" ON "VetCase"("vetOrgId", "status");

-- CreateIndex
CREATE INDEX "VetCase_batchId_idx" ON "VetCase"("batchId");

-- CreateIndex
CREATE INDEX "CaseMedia_caseId_kind_idx" ON "CaseMedia"("caseId", "kind");

-- CreateIndex
CREATE INDEX "CaseFinding_caseId_idx" ON "CaseFinding"("caseId");

-- CreateIndex
CREATE INDEX "CaseFinding_organ_lesion_idx" ON "CaseFinding"("organ", "lesion");

-- CreateIndex
CREATE INDEX "CaseDiagnosis_caseId_idx" ON "CaseDiagnosis"("caseId");

-- CreateIndex
CREATE INDEX "CaseDiagnosis_diseaseId_idx" ON "CaseDiagnosis"("diseaseId");

-- CreateIndex
CREATE UNIQUE INDEX "Disease_code_key" ON "Disease"("code");

-- CreateIndex
CREATE INDEX "VetVisit_caseId_idx" ON "VetVisit"("caseId");

-- AddForeignKey
ALTER TABLE "CaseMedia" ADD CONSTRAINT "CaseMedia_caseId_fkey" FOREIGN KEY ("caseId") REFERENCES "VetCase"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CaseFinding" ADD CONSTRAINT "CaseFinding_caseId_fkey" FOREIGN KEY ("caseId") REFERENCES "VetCase"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CaseFinding" ADD CONSTRAINT "CaseFinding_mediaId_fkey" FOREIGN KEY ("mediaId") REFERENCES "CaseMedia"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CaseDiagnosis" ADD CONSTRAINT "CaseDiagnosis_caseId_fkey" FOREIGN KEY ("caseId") REFERENCES "VetCase"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CaseDiagnosis" ADD CONSTRAINT "CaseDiagnosis_diseaseId_fkey" FOREIGN KEY ("diseaseId") REFERENCES "Disease"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "VetVisit" ADD CONSTRAINT "VetVisit_caseId_fkey" FOREIGN KEY ("caseId") REFERENCES "VetCase"("id") ON DELETE CASCADE ON UPDATE CASCADE;

