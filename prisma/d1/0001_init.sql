-- CreateTable
CREATE TABLE "Organization" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "name" TEXT NOT NULL,
    "capabilities" TEXT NOT NULL,
    "baseCurrency" TEXT NOT NULL DEFAULT 'INR',
    "status" TEXT NOT NULL DEFAULT 'active',
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    "deletedAt" DATETIME
);

-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "email" TEXT NOT NULL,
    "displayName" TEXT,
    "photoUrl" TEXT,
    "status" TEXT NOT NULL DEFAULT 'active',
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL
);

-- CreateTable
CREATE TABLE "ExternalIdentity" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "provider" TEXT NOT NULL,
    "subject" TEXT NOT NULL,
    "email" TEXT,
    "userId" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "ExternalIdentity_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "Membership" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "userId" TEXT NOT NULL,
    "orgId" TEXT NOT NULL,
    "roleId" TEXT NOT NULL,
    "capabilityScope" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "Membership_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "Membership_orgId_fkey" FOREIGN KEY ("orgId") REFERENCES "Organization" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "Membership_roleId_fkey" FOREIGN KEY ("roleId") REFERENCES "Role" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "MemberScope" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "orgId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "farmId" TEXT,
    "shedId" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- CreateTable
CREATE TABLE "Role" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "key" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "capability" TEXT NOT NULL,
    "orgId" TEXT
);

-- CreateTable
CREATE TABLE "Permission" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "roleId" TEXT NOT NULL,
    "resource" TEXT NOT NULL,
    "action" TEXT NOT NULL,
    CONSTRAINT "Permission_roleId_fkey" FOREIGN KEY ("roleId") REFERENCES "Role" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "AuditLog" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "orgId" TEXT NOT NULL,
    "actorUserId" TEXT NOT NULL,
    "resource" TEXT NOT NULL,
    "resourceId" TEXT NOT NULL,
    "action" TEXT NOT NULL,
    "before" TEXT,
    "after" TEXT,
    "at" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- CreateTable
CREATE TABLE "Notification" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "orgId" TEXT NOT NULL,
    "userId" TEXT,
    "type" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "body" TEXT NOT NULL,
    "payload" TEXT,
    "readAt" DATETIME,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- CreateTable
CREATE TABLE "Alert" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "orgId" TEXT NOT NULL,
    "kind" TEXT NOT NULL,
    "subjectType" TEXT NOT NULL,
    "subjectId" TEXT NOT NULL,
    "farmId" TEXT,
    "title" TEXT NOT NULL,
    "detail" TEXT NOT NULL,
    "value" REAL,
    "dayKey" TEXT NOT NULL,
    "readAt" DATETIME,
    "resolvedAt" DATETIME,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- CreateTable
CREATE TABLE "AlertSetting" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "orgId" TEXT NOT NULL,
    "kind" TEXT NOT NULL,
    "enabled" BOOLEAN NOT NULL DEFAULT true,
    "threshold" REAL
);

-- CreateTable
CREATE TABLE "AlertMute" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "orgId" TEXT NOT NULL,
    "kind" TEXT NOT NULL,
    "shedId" TEXT NOT NULL
);

-- CreateTable
CREATE TABLE "BreedStandard" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "orgId" TEXT NOT NULL,
    "breed" TEXT NOT NULL
);

-- CreateTable
CREATE TABLE "BreedStandardPoint" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "standardId" TEXT NOT NULL,
    "day" INTEGER NOT NULL,
    "weightG" INTEGER NOT NULL,
    "fcr" REAL,
    CONSTRAINT "BreedStandardPoint_standardId_fkey" FOREIGN KEY ("standardId") REFERENCES "BreedStandard" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "MemberVisibility" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "orgId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "seeCosts" BOOLEAN NOT NULL DEFAULT true,
    "seeRevenue" BOOLEAN NOT NULL DEFAULT false,
    "seeProfit" BOOLEAN NOT NULL DEFAULT false,
    "canPlaceClose" BOOLEAN NOT NULL DEFAULT true,
    "canRecordSales" BOOLEAN NOT NULL DEFAULT false,
    "canAddExpenses" BOOLEAN NOT NULL DEFAULT true
);

-- CreateTable
CREATE TABLE "OrgSetting" (
    "orgId" TEXT NOT NULL,
    "key" TEXT NOT NULL,
    "value" TEXT NOT NULL,

    PRIMARY KEY ("orgId", "key")
);

-- CreateTable
CREATE TABLE "Farm" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "orgId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "location" TEXT,
    "tenure" TEXT NOT NULL DEFAULT 'OWNED',
    "lessorName" TEXT,
    "rentAmount" INTEGER,
    "rentBasis" TEXT,
    "leaseStart" DATETIME,
    "leaseEnd" DATETIME,
    "deposit" INTEGER,
    "createdBy" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    "deletedAt" DATETIME,
    CONSTRAINT "Farm_orgId_fkey" FOREIGN KEY ("orgId") REFERENCES "Organization" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "Shed" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "orgId" TEXT NOT NULL,
    "farmId" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "capacity" INTEGER NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'EMPTY',
    "tenure" TEXT NOT NULL DEFAULT 'OWNED',
    "notionalRent" INTEGER,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "Shed_farmId_fkey" FOREIGN KEY ("farmId") REFERENCES "Farm" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "Batch" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "orgId" TEXT NOT NULL,
    "farmId" TEXT NOT NULL,
    "shedId" TEXT NOT NULL,
    "chickSupplierId" TEXT,
    "breed" TEXT NOT NULL,
    "growingModel" TEXT NOT NULL DEFAULT 'OWN',
    "hatchery" TEXT,
    "chickRate" INTEGER,
    "chickDiscount" INTEGER,
    "placementDate" DATETIME NOT NULL,
    "targetHarvestDate" DATETIME,
    "initialBirds" INTEGER NOT NULL,
    "mortality" INTEGER NOT NULL DEFAULT 0,
    "culls" INTEGER NOT NULL DEFAULT 0,
    "birdsSold" INTEGER NOT NULL DEFAULT 0,
    "birdsWrittenOff" INTEGER NOT NULL DEFAULT 0,
    "harvestVisibility" TEXT NOT NULL DEFAULT 'HIDDEN',
    "status" TEXT NOT NULL DEFAULT 'PLANNED',
    "createdBy" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    "deletedAt" DATETIME,
    CONSTRAINT "Batch_farmId_fkey" FOREIGN KEY ("farmId") REFERENCES "Farm" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "Batch_shedId_fkey" FOREIGN KEY ("shedId") REFERENCES "Shed" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "DailyLog" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "orgId" TEXT NOT NULL,
    "batchId" TEXT NOT NULL,
    "date" DATETIME NOT NULL,
    "openingBirds" INTEGER NOT NULL,
    "mortality" INTEGER NOT NULL DEFAULT 0,
    "culls" INTEGER NOT NULL DEFAULT 0,
    "closingBirds" INTEGER NOT NULL,
    "weightSampleQty" INTEGER,
    "avgWeight" INTEGER,
    "minWeight" INTEGER,
    "maxWeight" INTEGER,
    "uniformity" INTEGER,
    "feedType" TEXT,
    "feedConsumed" INTEGER,
    "water" INTEGER,
    "medicineNotes" TEXT,
    "tempC" REAL,
    "humidity" REAL,
    "notes" TEXT,
    "createdBy" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "DailyLog_batchId_fkey" FOREIGN KEY ("batchId") REFERENCES "Batch" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "WeightRecord" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "orgId" TEXT NOT NULL,
    "batchId" TEXT NOT NULL,
    "date" DATETIME NOT NULL,
    "sampleQty" INTEGER NOT NULL,
    "avgWeight" INTEGER NOT NULL,
    "minWeight" INTEGER,
    "maxWeight" INTEGER,
    "uniformity" INTEGER,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "WeightRecord_batchId_fkey" FOREIGN KEY ("batchId") REFERENCES "Batch" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "FeedItem" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "orgId" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "brand" TEXT,
    "bagSizeKg" INTEGER NOT NULL
);

-- CreateTable
CREATE TABLE "FeedInventory" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "orgId" TEXT NOT NULL,
    "farmId" TEXT,
    "feedItemId" TEXT NOT NULL,
    "kind" TEXT NOT NULL DEFAULT 'PURCHASE',
    "reason" TEXT,
    "bags" INTEGER NOT NULL DEFAULT 0,
    "kg" INTEGER NOT NULL DEFAULT 0,
    "supplierId" TEXT,
    "unitCost" INTEGER,
    "currency" TEXT NOT NULL DEFAULT 'INR',
    "date" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "FeedInventory_feedItemId_fkey" FOREIGN KEY ("feedItemId") REFERENCES "FeedItem" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "FeedConsumption" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "orgId" TEXT NOT NULL,
    "batchId" TEXT NOT NULL,
    "feedItemId" TEXT NOT NULL,
    "date" DATETIME NOT NULL,
    "bags" INTEGER NOT NULL DEFAULT 0,
    "kg" INTEGER NOT NULL DEFAULT 0,
    "cost" INTEGER,
    "currency" TEXT NOT NULL DEFAULT 'INR',
    CONSTRAINT "FeedConsumption_batchId_fkey" FOREIGN KEY ("batchId") REFERENCES "Batch" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "FeedConsumption_feedItemId_fkey" FOREIGN KEY ("feedItemId") REFERENCES "FeedItem" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "MedicineItem" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "orgId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "unit" TEXT NOT NULL,
    "withdrawalDays" INTEGER NOT NULL DEFAULT 0
);

-- CreateTable
CREATE TABLE "MedicineInventory" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "orgId" TEXT NOT NULL,
    "farmId" TEXT,
    "medicineItemId" TEXT NOT NULL,
    "kind" TEXT NOT NULL DEFAULT 'PURCHASE',
    "reason" TEXT,
    "qty" INTEGER NOT NULL DEFAULT 0,
    "supplierId" TEXT,
    "unitCost" INTEGER,
    "currency" TEXT NOT NULL DEFAULT 'INR',
    "expiryDate" DATETIME,
    "date" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "MedicineInventory_medicineItemId_fkey" FOREIGN KEY ("medicineItemId") REFERENCES "MedicineItem" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "MedicineUsage" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "orgId" TEXT NOT NULL,
    "batchId" TEXT NOT NULL,
    "medicineItemId" TEXT NOT NULL,
    "date" DATETIME NOT NULL,
    "endDate" DATETIME,
    "withdrawalDays" INTEGER NOT NULL DEFAULT 0,
    "reason" TEXT,
    "qty" INTEGER NOT NULL,
    "cost" INTEGER,
    "currency" TEXT NOT NULL DEFAULT 'INR',
    "notes" TEXT,
    CONSTRAINT "MedicineUsage_batchId_fkey" FOREIGN KEY ("batchId") REFERENCES "Batch" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "MedicineUsage_medicineItemId_fkey" FOREIGN KEY ("medicineItemId") REFERENCES "MedicineItem" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "VaccinationSchedule" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "orgId" TEXT NOT NULL,
    "batchId" TEXT NOT NULL,
    "vaccine" TEXT NOT NULL,
    "scheduledDate" DATETIME NOT NULL,
    "completedDate" DATETIME,
    "status" TEXT NOT NULL DEFAULT 'SCHEDULED',
    CONSTRAINT "VaccinationSchedule_batchId_fkey" FOREIGN KEY ("batchId") REFERENCES "Batch" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "Party" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "orgId" TEXT NOT NULL,
    "kind" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "phone" TEXT,
    "place" TEXT,
    "declaredRate" INTEGER,
    "discount" INTEGER,
    "rateBasis" TEXT NOT NULL DEFAULT 'MARKET',
    "creditDays" INTEGER NOT NULL DEFAULT 15,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL
);

-- CreateTable
CREATE TABLE "Expense" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "orgId" TEXT NOT NULL,
    "batchId" TEXT,
    "farmId" TEXT,
    "category" TEXT NOT NULL,
    "amount" INTEGER NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'INR',
    "date" DATETIME NOT NULL,
    "periodMonth" DATETIME,
    "paid" BOOLEAN NOT NULL DEFAULT true,
    "partyId" TEXT,
    "billKey" TEXT,
    "autoAccrued" BOOLEAN NOT NULL DEFAULT false,
    "notes" TEXT,
    "createdBy" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "Expense_batchId_fkey" FOREIGN KEY ("batchId") REFERENCES "Batch" ("id") ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT "Expense_partyId_fkey" FOREIGN KEY ("partyId") REFERENCES "Party" ("id") ON DELETE SET NULL ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "SupplierPayment" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "orgId" TEXT NOT NULL,
    "partyId" TEXT NOT NULL,
    "date" DATETIME NOT NULL,
    "amount" INTEGER NOT NULL,
    "mode" TEXT NOT NULL DEFAULT 'CASH',
    "reference" TEXT,
    "notes" TEXT,
    "createdBy" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "SupplierPayment_partyId_fkey" FOREIGN KEY ("partyId") REFERENCES "Party" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "SupplierPaymentAllocation" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "orgId" TEXT NOT NULL,
    "paymentId" TEXT NOT NULL,
    "expenseId" TEXT NOT NULL,
    "amount" INTEGER NOT NULL,
    CONSTRAINT "SupplierPaymentAllocation_paymentId_fkey" FOREIGN KEY ("paymentId") REFERENCES "SupplierPayment" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "SupplierPaymentAllocation_expenseId_fkey" FOREIGN KEY ("expenseId") REFERENCES "Expense" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "ExpenseAllocation" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "orgId" TEXT NOT NULL,
    "expenseId" TEXT NOT NULL,
    "batchId" TEXT NOT NULL,
    "amount" INTEGER NOT NULL,
    "birdDays" INTEGER NOT NULL DEFAULT 0,
    "manual" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "ExpenseAllocation_expenseId_fkey" FOREIGN KEY ("expenseId") REFERENCES "Expense" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "ExpenseAllocation_batchId_fkey" FOREIGN KEY ("batchId") REFERENCES "Batch" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "Revenue" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "orgId" TEXT NOT NULL,
    "batchId" TEXT NOT NULL,
    "source" TEXT NOT NULL,
    "amount" INTEGER NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'INR',
    "date" DATETIME NOT NULL,
    CONSTRAINT "Revenue_batchId_fkey" FOREIGN KEY ("batchId") REFERENCES "Batch" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "Harvest" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "orgId" TEXT NOT NULL,
    "batchId" TEXT NOT NULL,
    "date" DATETIME NOT NULL,
    "birdsHarvested" INTEGER NOT NULL,
    "totalWeight" INTEGER NOT NULL,
    CONSTRAINT "Harvest_batchId_fkey" FOREIGN KEY ("batchId") REFERENCES "Batch" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "Sale" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "orgId" TEXT NOT NULL,
    "batchId" TEXT NOT NULL,
    "buyerId" TEXT,
    "date" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "qty" INTEGER NOT NULL,
    "weight" INTEGER NOT NULL,
    "declaredRate" INTEGER,
    "discount" INTEGER,
    "rate" INTEGER NOT NULL,
    "amount" INTEGER NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'INR',
    "vehicle" TEXT,
    "slipKey" TEXT,
    "notes" TEXT,
    "createdBy" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "Sale_batchId_fkey" FOREIGN KEY ("batchId") REFERENCES "Batch" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "Sale_buyerId_fkey" FOREIGN KEY ("buyerId") REFERENCES "Party" ("id") ON DELETE SET NULL ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "BuyerPayment" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "orgId" TEXT NOT NULL,
    "partyId" TEXT NOT NULL,
    "date" DATETIME NOT NULL,
    "amount" INTEGER NOT NULL,
    "mode" TEXT NOT NULL DEFAULT 'CASH',
    "reference" TEXT,
    "notes" TEXT,
    "createdBy" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "BuyerPayment_partyId_fkey" FOREIGN KEY ("partyId") REFERENCES "Party" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "BuyerPaymentAllocation" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "orgId" TEXT NOT NULL,
    "paymentId" TEXT NOT NULL,
    "saleId" TEXT NOT NULL,
    "amount" INTEGER NOT NULL,
    CONSTRAINT "BuyerPaymentAllocation_paymentId_fkey" FOREIGN KEY ("paymentId") REFERENCES "BuyerPayment" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "BuyerPaymentAllocation_saleId_fkey" FOREIGN KEY ("saleId") REFERENCES "Sale" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "Settlement" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "orgId" TEXT NOT NULL,
    "batchId" TEXT NOT NULL,
    "payable" INTEGER NOT NULL,
    "paid" INTEGER NOT NULL DEFAULT 0,
    "balance" INTEGER NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'PENDING',
    "date" DATETIME,
    "reference" TEXT,
    "currency" TEXT NOT NULL DEFAULT 'INR',
    CONSTRAINT "Settlement_batchId_fkey" FOREIGN KEY ("batchId") REFERENCES "Batch" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "BatchClosure" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "orgId" TEXT NOT NULL,
    "batchId" TEXT NOT NULL,
    "closedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "summaryMetrics" TEXT NOT NULL,
    "closedBy" TEXT NOT NULL,
    CONSTRAINT "BatchClosure_batchId_fkey" FOREIGN KEY ("batchId") REFERENCES "Batch" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "Product" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "orgId" TEXT NOT NULL,
    "kind" TEXT NOT NULL,
    "breed" TEXT,
    "age" INTEGER,
    "pricePerChick" INTEGER,
    "feedType" TEXT,
    "brand" TEXT,
    "bagSize" INTEGER,
    "pricePerBag" INTEGER,
    "qty" INTEGER NOT NULL DEFAULT 0,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "currency" TEXT NOT NULL DEFAULT 'INR',
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "Product_orgId_fkey" FOREIGN KEY ("orgId") REFERENCES "Organization" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "Inventory" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "orgId" TEXT NOT NULL,
    "productId" TEXT NOT NULL,
    "onHand" INTEGER NOT NULL DEFAULT 0,
    "reserved" INTEGER NOT NULL DEFAULT 0,
    CONSTRAINT "Inventory_productId_fkey" FOREIGN KEY ("productId") REFERENCES "Product" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "SupplierOrder" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "orgId" TEXT NOT NULL,
    "buyerOrgId" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'DRAFT',
    "subtotal" INTEGER NOT NULL DEFAULT 0,
    "tax" INTEGER NOT NULL DEFAULT 0,
    "discount" INTEGER NOT NULL DEFAULT 0,
    "total" INTEGER NOT NULL DEFAULT 0,
    "currency" TEXT NOT NULL DEFAULT 'INR',
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL
);

-- CreateTable
CREATE TABLE "OrderLine" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "orderId" TEXT NOT NULL,
    "productId" TEXT NOT NULL,
    "qty" INTEGER NOT NULL,
    "unitRate" INTEGER NOT NULL,
    "lineAmount" INTEGER NOT NULL,
    "subtotal" INTEGER NOT NULL,
    "tax" INTEGER NOT NULL DEFAULT 0,
    "discount" INTEGER NOT NULL DEFAULT 0,
    "total" INTEGER NOT NULL,
    CONSTRAINT "OrderLine_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "SupplierOrder" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "OrderLine_productId_fkey" FOREIGN KEY ("productId") REFERENCES "Product" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "Dispatch" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "orderId" TEXT NOT NULL,
    "number" TEXT NOT NULL,
    "vehicle" TEXT,
    "driver" TEXT,
    "dateTime" DATETIME NOT NULL,
    "status" TEXT NOT NULL,
    CONSTRAINT "Dispatch_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "SupplierOrder" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "Invoice" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "orderId" TEXT NOT NULL,
    "amount" INTEGER NOT NULL,
    "paid" INTEGER NOT NULL DEFAULT 0,
    "balance" INTEGER NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'PENDING',
    CONSTRAINT "Invoice_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "SupplierOrder" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "Payment" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "invoiceId" TEXT NOT NULL,
    "amount" INTEGER NOT NULL,
    "method" TEXT,
    "reference" TEXT,
    "date" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "Payment_invoiceId_fkey" FOREIGN KEY ("invoiceId") REFERENCES "Invoice" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "DistributorProfile" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "orgId" TEXT NOT NULL,
    "operatingArea" TEXT,
    CONSTRAINT "DistributorProfile_orgId_fkey" FOREIGN KEY ("orgId") REFERENCES "Organization" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "FarmerRelationship" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "distributorProfileId" TEXT NOT NULL,
    "farmerOrgId" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'active',
    CONSTRAINT "FarmerRelationship_distributorProfileId_fkey" FOREIGN KEY ("distributorProfileId") REFERENCES "DistributorProfile" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "Purchase" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "orgId" TEXT NOT NULL,
    "distributorProfileId" TEXT NOT NULL,
    "batchId" TEXT NOT NULL,
    "farmerOrgId" TEXT NOT NULL,
    "expectedQty" INTEGER NOT NULL,
    "expectedWeight" INTEGER NOT NULL,
    "rate" INTEGER NOT NULL,
    "amount" INTEGER NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'INR',
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "Purchase_distributorProfileId_fkey" FOREIGN KEY ("distributorProfileId") REFERENCES "DistributorProfile" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "Purchase_batchId_fkey" FOREIGN KEY ("batchId") REFERENCES "Batch" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "PurchaseActuals" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "purchaseId" TEXT NOT NULL,
    "actualBirds" INTEGER NOT NULL,
    "rejects" INTEGER NOT NULL DEFAULT 0,
    "liveWeight" INTEGER NOT NULL,
    "rate" INTEGER NOT NULL,
    "gross" INTEGER NOT NULL,
    "adjustments" INTEGER NOT NULL DEFAULT 0,
    "final" INTEGER NOT NULL,
    CONSTRAINT "PurchaseActuals_purchaseId_fkey" FOREIGN KEY ("purchaseId") REFERENCES "Purchase" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "DistributorSettlement" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "purchaseId" TEXT NOT NULL,
    "payable" INTEGER NOT NULL,
    "paid" INTEGER NOT NULL DEFAULT 0,
    "balance" INTEGER NOT NULL,
    "date" DATETIME,
    "reference" TEXT,
    "status" TEXT NOT NULL DEFAULT 'PENDING',
    "currency" TEXT NOT NULL DEFAULT 'INR',
    CONSTRAINT "DistributorSettlement_purchaseId_fkey" FOREIGN KEY ("purchaseId") REFERENCES "Purchase" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- CreateIndex
CREATE INDEX "ExternalIdentity_userId_idx" ON "ExternalIdentity"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "ExternalIdentity_provider_subject_key" ON "ExternalIdentity"("provider", "subject");

-- CreateIndex
CREATE INDEX "Membership_orgId_idx" ON "Membership"("orgId");

-- CreateIndex
CREATE UNIQUE INDEX "Membership_userId_orgId_roleId_key" ON "Membership"("userId", "orgId", "roleId");

-- CreateIndex
CREATE INDEX "MemberScope_orgId_userId_idx" ON "MemberScope"("orgId", "userId");

-- CreateIndex
CREATE UNIQUE INDEX "MemberScope_orgId_userId_farmId_shedId_key" ON "MemberScope"("orgId", "userId", "farmId", "shedId");

-- CreateIndex
CREATE UNIQUE INDEX "Role_orgId_key_key" ON "Role"("orgId", "key");

-- CreateIndex
CREATE UNIQUE INDEX "Permission_roleId_resource_action_key" ON "Permission"("roleId", "resource", "action");

-- CreateIndex
CREATE INDEX "AuditLog_orgId_resource_resourceId_idx" ON "AuditLog"("orgId", "resource", "resourceId");

-- CreateIndex
CREATE INDEX "Notification_orgId_userId_idx" ON "Notification"("orgId", "userId");

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

-- CreateIndex
CREATE INDEX "Farm_orgId_idx" ON "Farm"("orgId");

-- CreateIndex
CREATE INDEX "Shed_orgId_farmId_idx" ON "Shed"("orgId", "farmId");

-- CreateIndex
CREATE INDEX "Batch_orgId_status_idx" ON "Batch"("orgId", "status");

-- CreateIndex
CREATE INDEX "DailyLog_orgId_idx" ON "DailyLog"("orgId");

-- CreateIndex
CREATE UNIQUE INDEX "DailyLog_batchId_date_key" ON "DailyLog"("batchId", "date");

-- CreateIndex
CREATE INDEX "WeightRecord_orgId_batchId_idx" ON "WeightRecord"("orgId", "batchId");

-- CreateIndex
CREATE INDEX "FeedItem_orgId_idx" ON "FeedItem"("orgId");

-- CreateIndex
CREATE INDEX "FeedInventory_orgId_feedItemId_idx" ON "FeedInventory"("orgId", "feedItemId");

-- CreateIndex
CREATE INDEX "FeedConsumption_orgId_batchId_idx" ON "FeedConsumption"("orgId", "batchId");

-- CreateIndex
CREATE INDEX "MedicineItem_orgId_idx" ON "MedicineItem"("orgId");

-- CreateIndex
CREATE INDEX "MedicineInventory_orgId_medicineItemId_idx" ON "MedicineInventory"("orgId", "medicineItemId");

-- CreateIndex
CREATE INDEX "MedicineUsage_orgId_batchId_idx" ON "MedicineUsage"("orgId", "batchId");

-- CreateIndex
CREATE INDEX "VaccinationSchedule_orgId_batchId_idx" ON "VaccinationSchedule"("orgId", "batchId");

-- CreateIndex
CREATE INDEX "Party_orgId_kind_idx" ON "Party"("orgId", "kind");

-- CreateIndex
CREATE INDEX "Expense_orgId_batchId_idx" ON "Expense"("orgId", "batchId");

-- CreateIndex
CREATE INDEX "Expense_orgId_partyId_idx" ON "Expense"("orgId", "partyId");

-- CreateIndex
CREATE INDEX "SupplierPayment_orgId_partyId_idx" ON "SupplierPayment"("orgId", "partyId");

-- CreateIndex
CREATE INDEX "SupplierPaymentAllocation_orgId_expenseId_idx" ON "SupplierPaymentAllocation"("orgId", "expenseId");

-- CreateIndex
CREATE UNIQUE INDEX "SupplierPaymentAllocation_paymentId_expenseId_key" ON "SupplierPaymentAllocation"("paymentId", "expenseId");

-- CreateIndex
CREATE INDEX "ExpenseAllocation_orgId_batchId_idx" ON "ExpenseAllocation"("orgId", "batchId");

-- CreateIndex
CREATE UNIQUE INDEX "ExpenseAllocation_expenseId_batchId_key" ON "ExpenseAllocation"("expenseId", "batchId");

-- CreateIndex
CREATE INDEX "Revenue_orgId_batchId_idx" ON "Revenue"("orgId", "batchId");

-- CreateIndex
CREATE INDEX "Harvest_orgId_batchId_idx" ON "Harvest"("orgId", "batchId");

-- CreateIndex
CREATE INDEX "Sale_orgId_batchId_idx" ON "Sale"("orgId", "batchId");

-- CreateIndex
CREATE INDEX "BuyerPayment_orgId_partyId_idx" ON "BuyerPayment"("orgId", "partyId");

-- CreateIndex
CREATE INDEX "BuyerPaymentAllocation_orgId_saleId_idx" ON "BuyerPaymentAllocation"("orgId", "saleId");

-- CreateIndex
CREATE UNIQUE INDEX "BuyerPaymentAllocation_paymentId_saleId_key" ON "BuyerPaymentAllocation"("paymentId", "saleId");

-- CreateIndex
CREATE UNIQUE INDEX "Settlement_batchId_key" ON "Settlement"("batchId");

-- CreateIndex
CREATE UNIQUE INDEX "BatchClosure_batchId_key" ON "BatchClosure"("batchId");

-- CreateIndex
CREATE INDEX "Product_orgId_idx" ON "Product"("orgId");

-- CreateIndex
CREATE INDEX "Inventory_orgId_productId_idx" ON "Inventory"("orgId", "productId");

-- CreateIndex
CREATE INDEX "SupplierOrder_orgId_status_idx" ON "SupplierOrder"("orgId", "status");

-- CreateIndex
CREATE INDEX "SupplierOrder_buyerOrgId_idx" ON "SupplierOrder"("buyerOrgId");

-- CreateIndex
CREATE INDEX "OrderLine_orderId_idx" ON "OrderLine"("orderId");

-- CreateIndex
CREATE INDEX "Dispatch_orderId_idx" ON "Dispatch"("orderId");

-- CreateIndex
CREATE UNIQUE INDEX "Invoice_orderId_key" ON "Invoice"("orderId");

-- CreateIndex
CREATE INDEX "Payment_invoiceId_idx" ON "Payment"("invoiceId");

-- CreateIndex
CREATE UNIQUE INDEX "DistributorProfile_orgId_key" ON "DistributorProfile"("orgId");

-- CreateIndex
CREATE UNIQUE INDEX "FarmerRelationship_distributorProfileId_farmerOrgId_key" ON "FarmerRelationship"("distributorProfileId", "farmerOrgId");

-- CreateIndex
CREATE INDEX "Purchase_orgId_idx" ON "Purchase"("orgId");

-- CreateIndex
CREATE INDEX "Purchase_batchId_idx" ON "Purchase"("batchId");

-- CreateIndex
CREATE UNIQUE INDEX "PurchaseActuals_purchaseId_key" ON "PurchaseActuals"("purchaseId");

-- CreateIndex
CREATE UNIQUE INDEX "DistributorSettlement_purchaseId_key" ON "DistributorSettlement"("purchaseId");

