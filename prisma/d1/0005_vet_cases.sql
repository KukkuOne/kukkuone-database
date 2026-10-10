-- Vet cases: a farm asking a vet to look, and the record that comes back.
--
-- The product is the consultation. The training set is a by-product, and that
-- order matters — a farmer raises a case because birds are dying today, not to
-- improve a model.
--
-- Hand-written because prisma migrate does not touch D1. SQLite has no enums,
-- so organ, lesion, severity, evidence, media kind and status are all TEXT;
-- the closed vocabularies are enforced by the API rather than the column, and
-- that is the trade already made everywhere else in this schema.

-- ── the disease catalogue ────────────────────────────────────────────────
-- Seeded, not typed. Two vets spelling Gumboro differently would otherwise
-- become two diseases, and a dataset split across both cannot be trained on.
-- `notifiable` is a duty, not a label: Newcastle and avian influenza must be
-- reported to the authorities in India.
CREATE TABLE "Disease" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "code" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "nameTe" TEXT,
    "summary" TEXT,
    "summaryTe" TEXT,
    "notifiable" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" DATETIME NOT NULL,
    "updatedAt" DATETIME NOT NULL
);
CREATE UNIQUE INDEX "Disease_code_key" ON "Disease"("code");

-- ── the case ─────────────────────────────────────────────────────────────
-- The farm's numbers are not copied in: the batch carries its own age,
-- mortality, feed and water, so a case is the question rather than a snapshot.
-- birdsAffected and birdsDead are the exception, because a case is usually
-- raised mid-day, before that day's log exists.
--
-- trainingConsent is separate from the consult itself. Disease history is
-- commercially damaging — a farm known to have had Newcastle loses buyers —
-- so "my vet may see this" and "anyone may train on this" are two questions.
CREATE TABLE "VetCase" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "orgId" TEXT NOT NULL,
    "batchId" TEXT,
    "farmId" TEXT,
    "complaint" TEXT NOT NULL,
    "birdsAffected" INTEGER,
    "birdsDead" INTEGER,
    "status" TEXT NOT NULL DEFAULT 'RAISED',
    "vetOrgId" TEXT,
    "vetUserId" TEXT,
    "trainingConsent" BOOLEAN NOT NULL DEFAULT false,
    "consentAt" DATETIME,
    "raisedBy" TEXT,
    "createdAt" DATETIME NOT NULL,
    "updatedAt" DATETIME NOT NULL,
    "closedAt" DATETIME
);
CREATE INDEX "VetCase_orgId_status_idx" ON "VetCase"("orgId", "status");
CREATE INDEX "VetCase_vetOrgId_status_idx" ON "VetCase"("vetOrgId", "status");
CREATE INDEX "VetCase_batchId_idx" ON "VetCase"("batchId");

-- ── the pictures ─────────────────────────────────────────────────────────
-- storageKey is an object key and never a URL: the bucket is private and a
-- signed link is asked for when one is needed. A stored URL expires in the
-- database and rots there.
--
-- takenAt is not createdAt. A farmer photographs in a shed with no signal and
-- the upload lands hours later.
CREATE TABLE "CaseMedia" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "caseId" TEXT NOT NULL,
    "kind" TEXT NOT NULL,
    "storageKey" TEXT NOT NULL,
    "mimeType" TEXT NOT NULL,
    "bytes" INTEGER,
    "width" INTEGER,
    "height" INTEGER,
    "takenAt" DATETIME,
    "birdRef" TEXT,
    "note" TEXT,
    "uploadedBy" TEXT,
    "createdAt" DATETIME NOT NULL,
    CONSTRAINT "CaseMedia_caseId_fkey" FOREIGN KEY ("caseId") REFERENCES "VetCase" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "CaseMedia_caseId_kind_idx" ON "CaseMedia"("caseId", "kind");

-- ── the label ────────────────────────────────────────────────────────────
-- organ, lesion and severity are closed vocabularies so the set is trainable
-- the day it is written. region is the box drawn on the image, stored as
-- fractions of the image rather than pixels so a resize or a thumbnail does
-- not invalidate every label ever drawn.
--
-- mediaId is nullable on purpose. A vet can report airsacculitis they saw and
-- did not photograph, and a record that only admits what was photographed
-- quietly teaches the model that unphotographed lesions do not exist.
CREATE TABLE "CaseFinding" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "caseId" TEXT NOT NULL,
    "mediaId" TEXT,
    "organ" TEXT NOT NULL,
    "lesion" TEXT NOT NULL,
    "severity" TEXT NOT NULL DEFAULT 'MODERATE',
    "region" TEXT,
    "note" TEXT,
    "notedBy" TEXT,
    "createdAt" DATETIME NOT NULL,
    CONSTRAINT "CaseFinding_caseId_fkey" FOREIGN KEY ("caseId") REFERENCES "VetCase" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "CaseFinding_mediaId_fkey" FOREIGN KEY ("mediaId") REFERENCES "CaseMedia" ("id") ON DELETE SET NULL ON UPDATE CASCADE
);
CREATE INDEX "CaseFinding_caseId_idx" ON "CaseFinding"("caseId");
CREATE INDEX "CaseFinding_organ_lesion_idx" ON "CaseFinding"("organ", "lesion");

-- ── what the vet concluded ───────────────────────────────────────────────
-- More than one is allowed: a differential is a real clinical answer, and
-- forcing a single disease would make the vet pick one and the dataset
-- believe them. evidence separates an eye from a laboratory.
CREATE TABLE "CaseDiagnosis" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "caseId" TEXT NOT NULL,
    "diseaseId" TEXT,
    "freeName" TEXT,
    "evidence" TEXT NOT NULL DEFAULT 'PRESUMPTIVE',
    "rank" INTEGER NOT NULL DEFAULT 1,
    "advice" TEXT,
    "diagnosedBy" TEXT,
    "createdAt" DATETIME NOT NULL,
    CONSTRAINT "CaseDiagnosis_caseId_fkey" FOREIGN KEY ("caseId") REFERENCES "VetCase" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "CaseDiagnosis_diseaseId_fkey" FOREIGN KEY ("diseaseId") REFERENCES "Disease" ("id") ON DELETE SET NULL ON UPDATE CASCADE
);
CREATE INDEX "CaseDiagnosis_caseId_idx" ON "CaseDiagnosis"("caseId");
CREATE INDEX "CaseDiagnosis_diseaseId_idx" ON "CaseDiagnosis"("diseaseId");

-- ── going to the farm ────────────────────────────────────────────────────
-- Separate from the case because a visit has its own logistics, and because
-- the post-mortems done on it are the richest images in the whole set.
-- birdsExamined is what the vet reports, which may exceed how many they
-- managed to photograph.
CREATE TABLE "VetVisit" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "caseId" TEXT NOT NULL,
    "scheduledFor" DATETIME,
    "visitedOn" DATETIME,
    "birdsExamined" INTEGER NOT NULL DEFAULT 0,
    "summary" TEXT,
    "feePaise" INTEGER,
    "vetUserId" TEXT,
    "createdAt" DATETIME NOT NULL,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "VetVisit_caseId_fkey" FOREIGN KEY ("caseId") REFERENCES "VetCase" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "VetVisit_caseId_idx" ON "VetVisit"("caseId");
