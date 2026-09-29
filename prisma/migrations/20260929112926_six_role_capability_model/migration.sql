-- The three-value capability model becomes six.
--
--   FARMER      → FARMER, unchanged.
--   SUPPLIER    → HATCHERY *and* FEED_SUPPLIER. One value could not tell them
--                 apart, but a supplier product was already 'CHICK' | 'FEED',
--                 so the split existed a level down. An org that held SUPPLIER
--                 gains both, because nothing recorded which it actually was.
--   DISTRIBUTOR → LIFTING_PARTNER. What it does is discover harvest-ready
--                 batches, record actual weight lifted and settle; that is
--                 lifting, not trading.
--
-- TRADING_PARTNER and CHICKEN_RETAILER are new and no existing row becomes one.

-- ── 1. Merge the two distributor roles that collapse into one ───────────────
-- LIFTING_PARTNER has three roles where DISTRIBUTOR had four: PROCUREMENT_MANAGER
-- and OPERATIONS_MANAGER both become LIFTING_PARTNER_OPERATIONS, which
-- Role.@@unique([orgId, key]) forbids. Memberships move to the survivor first,
-- skipping any that would breach Membership.@@unique([userId, orgId, roleId]) —
-- those are users who already hold both, for whom the merge is a no-op.
UPDATE "Membership" m
SET "roleId" = surv.id
FROM "Role" dup
JOIN "Role" surv
  ON surv."orgId" IS NOT DISTINCT FROM dup."orgId"
 AND surv."key" = 'DISTRIBUTOR_PROCUREMENT_MANAGER'
WHERE m."roleId" = dup.id
  AND dup."key" = 'DISTRIBUTOR_OPERATIONS_MANAGER'
  AND NOT EXISTS (
    SELECT 1 FROM "Membership" x
    WHERE x."userId" = m."userId" AND x."orgId" = m."orgId" AND x."roleId" = surv.id
  );

-- Whatever still points at the duplicate is a user who already held the
-- survivor, so the row is redundant rather than lost.
DELETE FROM "Membership" m
USING "Role" dup
WHERE m."roleId" = dup.id AND dup."key" = 'DISTRIBUTOR_OPERATIONS_MANAGER';

DELETE FROM "Permission" p
USING "Role" r
WHERE p."roleId" = r.id AND r."key" = 'DISTRIBUTOR_OPERATIONS_MANAGER';

DELETE FROM "Role" WHERE "key" = 'DISTRIBUTOR_OPERATIONS_MANAGER';

-- ── 2. Hold the enum columns as text while the values are rewritten ─────────
-- Postgres cannot use an enum value added in the same transaction, and Prisma
-- runs a migration in one. Going out to text and back builds the new type
-- cleanly instead.
ALTER TABLE "Organization" ALTER COLUMN "capabilities"    TYPE text[] USING "capabilities"::text[];
ALTER TABLE "Membership"   ALTER COLUMN "capabilityScope" TYPE text   USING "capabilityScope"::text;
ALTER TABLE "Role"         ALTER COLUMN "capability"      TYPE text   USING "capability"::text;

-- ── 3. Rewrite the values ──────────────────────────────────────────────────
-- SUPPLIER expands to two entries, so the array is rebuilt rather than
-- substituted. DISTINCT guards an org that somehow held both.
UPDATE "Organization" SET "capabilities" = COALESCE((
  SELECT array_agg(DISTINCT v ORDER BY v)
  FROM (
    SELECT unnest(
      CASE c
        WHEN 'DISTRIBUTOR' THEN ARRAY['LIFTING_PARTNER']
        WHEN 'SUPPLIER'    THEN ARRAY['HATCHERY', 'FEED_SUPPLIER']
        ELSE ARRAY[c]
      END
    ) AS v
    FROM unnest("capabilities") AS c
  ) expanded
), ARRAY[]::text[]);

-- A membership is scoped to exactly one capability, so SUPPLIER cannot expand
-- here. It lands on FEED_SUPPLIER, matching where the SUPPLIER_* role keys go
-- below; the hatchery half is created by the role backfill, which reads the
-- templates rather than guessing.
UPDATE "Membership" SET "capabilityScope" =
  CASE "capabilityScope"
    WHEN 'DISTRIBUTOR' THEN 'LIFTING_PARTNER'
    WHEN 'SUPPLIER'    THEN 'FEED_SUPPLIER'
    ELSE "capabilityScope"
  END;

UPDATE "Role" SET
  "capability" = CASE "capability"
    WHEN 'DISTRIBUTOR' THEN 'LIFTING_PARTNER'
    WHEN 'SUPPLIER'    THEN 'FEED_SUPPLIER'
    ELSE "capability"
  END,
  "key" = CASE "key"
    WHEN 'SUPPLIER_OWNER'                   THEN 'FEED_SUPPLIER_OWNER'
    WHEN 'SUPPLIER_MANAGER'                 THEN 'FEED_SUPPLIER_MANAGER'
    WHEN 'SUPPLIER_OPERATIONS'              THEN 'FEED_SUPPLIER_OPERATIONS'
    WHEN 'SUPPLIER_FINANCE'                 THEN 'FEED_SUPPLIER_FINANCE'
    WHEN 'DISTRIBUTOR_OWNER'                THEN 'LIFTING_PARTNER_OWNER'
    WHEN 'DISTRIBUTOR_PROCUREMENT_MANAGER'  THEN 'LIFTING_PARTNER_OPERATIONS'
    WHEN 'DISTRIBUTOR_FINANCE_MANAGER'      THEN 'LIFTING_PARTNER_FINANCE'
    ELSE "key"
  END;

-- The renamed operations role keeps a name from a role that no longer exists.
UPDATE "Role" SET "name" = 'Operations' WHERE "key" = 'LIFTING_PARTNER_OPERATIONS';
UPDATE "Role" SET "name" = 'Finance'    WHERE "key" = 'LIFTING_PARTNER_FINANCE';

-- ── 4. Swap the type and put the columns back ──────────────────────────────
DROP TYPE "Capability";
CREATE TYPE "Capability" AS ENUM (
  'FARMER',
  'HATCHERY',
  'FEED_SUPPLIER',
  'TRADING_PARTNER',
  'LIFTING_PARTNER',
  'CHICKEN_RETAILER'
);

ALTER TABLE "Organization" ALTER COLUMN "capabilities"    TYPE "Capability"[] USING "capabilities"::"Capability"[];
ALTER TABLE "Membership"   ALTER COLUMN "capabilityScope" TYPE "Capability"   USING "capabilityScope"::"Capability";
ALTER TABLE "Role"         ALTER COLUMN "capability"      TYPE "Capability"   USING "capability"::"Capability";
