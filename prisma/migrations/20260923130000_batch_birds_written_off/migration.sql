ALTER TABLE "Batch" ADD COLUMN IF NOT EXISTS "birdsWrittenOff" INTEGER NOT NULL DEFAULT 0;

-- Move every historic write-off out of culls, where the close path had put it.
UPDATE "Batch" b
SET "birdsWrittenOff" = wo.n,
    culls = GREATEST(0, b.culls - wo.n)
FROM (
  SELECT "batchId", (("summaryMetrics"->>'birdsWrittenOff')::int) AS n
  FROM "BatchClosure"
  WHERE ("summaryMetrics"->>'birdsWrittenOff') IS NOT NULL
) wo
WHERE wo."batchId" = b.id AND wo.n > 0;
