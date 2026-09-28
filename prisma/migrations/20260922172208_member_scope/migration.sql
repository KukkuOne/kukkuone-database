-- CreateTable
CREATE TABLE "MemberScope" (
    "id" TEXT NOT NULL,
    "orgId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "farmId" TEXT,
    "shedId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "MemberScope_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "MemberScope_orgId_userId_idx" ON "MemberScope"("orgId", "userId");

-- CreateIndex
CREATE UNIQUE INDEX "MemberScope_orgId_userId_farmId_shedId_key" ON "MemberScope"("orgId", "userId", "farmId", "shedId");
