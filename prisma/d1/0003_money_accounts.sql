-- Money accounts: where the farm's cash actually sits.
--
-- One account covers most farms and is what every existing org gets below:
-- costs go out of it, receipts come into it, the owner tops it up when it runs
-- short. Accounts nest (parentId) so a farm keeping separate books per
-- location can say so. Only a leaf account holds entries — a master's balance
-- is the sum of its children, which is what stops a rupee being counted once
-- on the sub and again on the master.
--
-- Hand-written because prisma migrate does not touch D1. SQLite has no enums,
-- so direction/kind/source are TEXT.

-- ── account types, configurable per org ──────────────────────────────────
CREATE TABLE "AccountType" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "orgId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "system" BOOLEAN NOT NULL DEFAULT false,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "archivedAt" DATETIME,
    "createdAt" DATETIME NOT NULL,
    "updatedAt" DATETIME NOT NULL
);
CREATE UNIQUE INDEX "AccountType_orgId_name_key" ON "AccountType"("orgId", "name");
CREATE INDEX "AccountType_orgId_idx" ON "AccountType"("orgId");

-- ── the accounts themselves ──────────────────────────────────────────────
CREATE TABLE "Account" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "orgId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "typeId" TEXT,
    "parentId" TEXT,
    "farmId" TEXT,
    "isDefault" BOOLEAN NOT NULL DEFAULT false,
    "openingBalance" INTEGER NOT NULL DEFAULT 0,
    "openedOn" DATETIME,
    "currency" TEXT NOT NULL DEFAULT 'INR',
    "archivedAt" DATETIME,
    "createdAt" DATETIME NOT NULL,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "Account_typeId_fkey" FOREIGN KEY ("typeId") REFERENCES "AccountType" ("id") ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT "Account_parentId_fkey" FOREIGN KEY ("parentId") REFERENCES "Account" ("id") ON DELETE SET NULL ON UPDATE CASCADE
);
CREATE INDEX "Account_orgId_idx" ON "Account"("orgId");
CREATE INDEX "Account_orgId_parentId_idx" ON "Account"("orgId", "parentId");

-- ── movements nothing else already records ───────────────────────────────
-- Buyer and supplier payments are deliberately NOT copied in here; they carry
-- an accountId and are read where they already live, so each rupee has one row.
CREATE TABLE "AccountEntry" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "orgId" TEXT NOT NULL,
    "accountId" TEXT NOT NULL,
    "date" DATETIME NOT NULL,
    "direction" TEXT NOT NULL,
    "kind" TEXT NOT NULL,
    "amount" INTEGER NOT NULL,
    "partyId" TEXT,
    "transferId" TEXT,
    "notes" TEXT,
    "createdBy" TEXT,
    "createdAt" DATETIME NOT NULL,
    CONSTRAINT "AccountEntry_accountId_fkey" FOREIGN KEY ("accountId") REFERENCES "Account" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "AccountEntry_partyId_fkey" FOREIGN KEY ("partyId") REFERENCES "Party" ("id") ON DELETE SET NULL ON UPDATE CASCADE
);
CREATE INDEX "AccountEntry_orgId_accountId_date_idx" ON "AccountEntry"("orgId", "accountId", "date");

-- ── which account the money moved through ────────────────────────────────
-- Nullable, and null means the org's default account, so nothing already
-- recorded needs backfilling.
ALTER TABLE "BuyerPayment" ADD COLUMN "accountId" TEXT;
ALTER TABLE "SupplierPayment" ADD COLUMN "accountId" TEXT;
ALTER TABLE "Expense" ADD COLUMN "accountId" TEXT;

-- ── revenue that is not a bird, and not always a batch's ─────────────────
-- batchId has to lose its NOT NULL, which SQLite cannot do in place, so the
-- table is rebuilt. Existing rows all have a batch and carry over unchanged.
CREATE TABLE "Revenue_new" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "orgId" TEXT NOT NULL,
    "batchId" TEXT,
    "farmId" TEXT,
    "partyId" TEXT,
    "source" TEXT NOT NULL,
    "amount" INTEGER NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'INR',
    "date" DATETIME NOT NULL,
    "notes" TEXT,
    CONSTRAINT "Revenue_batchId_fkey" FOREIGN KEY ("batchId") REFERENCES "Batch" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "Revenue_partyId_fkey" FOREIGN KEY ("partyId") REFERENCES "Party" ("id") ON DELETE SET NULL ON UPDATE CASCADE
);
INSERT INTO "Revenue_new" ("id", "orgId", "batchId", "source", "amount", "currency", "date")
SELECT "id", "orgId", "batchId", "source", "amount", "currency", "date" FROM "Revenue";
DROP TABLE "Revenue";
ALTER TABLE "Revenue_new" RENAME TO "Revenue";
CREATE INDEX "Revenue_orgId_batchId_idx" ON "Revenue"("orgId", "batchId");

-- ── every existing org gets the one account it has been running on ───────
-- Named plainly rather than after a bank: the farm can rename it, and a wrong
-- guess at a bank name is worse than no guess.
INSERT INTO "AccountType" ("id", "orgId", "name", "system", "sortOrder", "createdAt", "updatedAt")
SELECT lower(hex(randomblob(16))), o."id", t."name", true, t."sortOrder",
       datetime('now'), datetime('now')
FROM "Organization" o
CROSS JOIN (
    SELECT 'Bank' AS "name", 0 AS "sortOrder"
    UNION ALL SELECT 'Cash', 1
    UNION ALL SELECT 'UPI', 2
    UNION ALL SELECT 'Loan', 3
) t;

INSERT INTO "Account" ("id", "orgId", "name", "typeId", "isDefault", "openingBalance", "currency", "createdAt", "updatedAt")
SELECT lower(hex(randomblob(16))), o."id", 'Farm account',
       (SELECT at."id" FROM "AccountType" at WHERE at."orgId" = o."id" AND at."name" = 'Bank'),
       true, 0, 'INR', datetime('now'), datetime('now')
FROM "Organization" o;
