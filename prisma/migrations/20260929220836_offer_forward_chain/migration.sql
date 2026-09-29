-- Who passed an offer on.
--
-- A trading partner with bird marketing may forward a farmer's offer to lifting
-- partners. The forward adds recipients to the same offer — it cannot alter
-- what they see — and this column records who sent it, so a farmer who offered
-- a lot to one broker can see it reached four lifters and by whose hand.
--
-- Additive and nullable: every existing recipient was addressed by the farmer
-- directly, which is what null means.

-- AlterTable
ALTER TABLE "HarvestOfferRecipient" ADD COLUMN     "viaOrgId" TEXT;

