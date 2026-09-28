-- CreateEnum
CREATE TYPE "Tenure" AS ENUM ('OWNED', 'LEASED');

-- CreateEnum
CREATE TYPE "RentBasis" AS ENUM ('PER_MONTH', 'PER_SQFT', 'PER_BIRD_PLACED', 'PER_BATCH');

-- CreateEnum
CREATE TYPE "GrowingModel" AS ENUM ('OWN', 'CONTRACT');

-- AlterTable
ALTER TABLE "Batch" ADD COLUMN     "chickDiscount" INTEGER,
ADD COLUMN     "chickRate" INTEGER,
ADD COLUMN     "growingModel" "GrowingModel" NOT NULL DEFAULT 'OWN',
ADD COLUMN     "hatchery" TEXT;

-- AlterTable
ALTER TABLE "Farm" ADD COLUMN     "deposit" INTEGER,
ADD COLUMN     "leaseEnd" TIMESTAMP(3),
ADD COLUMN     "leaseStart" TIMESTAMP(3),
ADD COLUMN     "lessorName" TEXT,
ADD COLUMN     "rentAmount" INTEGER,
ADD COLUMN     "rentBasis" "RentBasis",
ADD COLUMN     "tenure" "Tenure" NOT NULL DEFAULT 'OWNED';

-- AlterTable
ALTER TABLE "Shed" ADD COLUMN     "tenure" "Tenure" NOT NULL DEFAULT 'OWNED';
