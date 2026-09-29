-- What a Trading Partner actually does, enabled one by one.
--
-- The role is an umbrella: sourcing inputs, reselling them, marketing birds and
-- coordinating lifting are different businesses that one intermediary may do
-- any combination of. Holding TRADING_PARTNER says nothing about which, so
-- nothing may infer that a partner owns inventory or buys birds merely because
-- they arranged a deal.
--
-- Purely additive. Existing rows get an empty array, which is the correct
-- answer for them: no organisation holds TRADING_PARTNER yet, and for one that
-- does, empty means "not stated" rather than "none" — the sign-up screen is
-- what fills it in.
--
-- Lower-case values because that is how the spec writes these keys. Re-casing
-- them would leave the stored value no longer matching the document anyone
-- checks it against.

-- CreateEnum
CREATE TYPE "TradingCapability" AS ENUM ('chick_trading', 'feed_trading', 'bird_marketing', 'lifting_coordination');

-- AlterTable
ALTER TABLE "Organization" ADD COLUMN     "tradingCapabilities" "TradingCapability"[];
