import { PrismaClient } from '@prisma/client';
import { createOrgRoles, ownerRoleKey } from '../src/rbac';

const prisma = new PrismaClient();

const SUPER_ADMIN_EMAIL = (process.env.ADMIN_SUPERUSER_EMAIL ?? 'naptrixlabs@gmail.com')
  .split(',')[0]
  .trim()
  .toLowerCase();

/** Upsert a user + a dev-provider external identity (subject = email). */
async function upsertDevUser(email: string, displayName: string) {
  const user = await prisma.user.upsert({
    where: { email },
    update: { displayName },
    create: { email, displayName },
  });
  const identity = await prisma.externalIdentity.findUnique({
    where: { provider_subject: { provider: 'dev', subject: email } },
  });
  if (!identity) {
    await prisma.externalIdentity.create({
      data: { provider: 'dev', subject: email, email, userId: user.id },
    });
  }
  return user;
}

async function main() {
  // 1. Platform super-admin (admin console allowlist). No org membership needed.
  await upsertDevUser(SUPER_ADMIN_EMAIL, 'KukkuOne Super Admin');
  console.log(`✓ super-admin seeded: ${SUPER_ADMIN_EMAIL}`);

  // 2. Demo Farmer organization with an owner, so there is data to explore.
  const demoOwnerEmail = 'farmer.demo@kukkuone.test';
  const owner = await upsertDevUser(demoOwnerEmail, 'Demo Farmer Owner');

  let org = await prisma.organization.findFirst({ where: { name: 'KukkuOne Demo Farm' } });
  if (!org) {
    org = await prisma.organization.create({
      data: {
        name: 'KukkuOne Demo Farm',
        capabilities: ['FARMER'],
        baseCurrency: 'INR',
      },
    });
    const roleMap = await createOrgRoles(prisma, org.id, ['FARMER']);
    await prisma.membership.create({
      data: {
        userId: owner.id,
        orgId: org.id,
        roleId: roleMap[ownerRoleKey('FARMER')],
        capabilityScope: 'FARMER',
      },
    });

    const farm = await prisma.farm.create({
      data: { orgId: org.id, name: 'Green Valley Farm', location: 'Karimnagar', createdBy: owner.id },
    });
    await prisma.shed.create({
      data: { orgId: org.id, farmId: farm.id, code: 'SHED-A', capacity: 5000, status: 'READY' },
    });
    console.log(`✓ demo farmer org seeded: ${org.name} (owner ${demoOwnerEmail})`);
  } else {
    console.log('✓ demo farmer org already present — skipping');
  }
}

main()
  .then(() => prisma.$disconnect())
  .catch(async (e) => {
    console.error(e);
    await prisma.$disconnect();
    process.exit(1);
  });
