/**
 * Create any org-scoped roles an organisation is missing for the capabilities
 * it holds.
 *
 * The six-role migration could rewrite the values it found, but not invent the
 * ones that had never existed: an org that held SUPPLIER gained both HATCHERY
 * and FEED_SUPPLIER, and only the feed half had roles to rename. Rather than
 * hand-write the missing rows in SQL — a second copy of the templates, free to
 * drift from the first — this replays ROLE_TEMPLATES, which is the source of
 * truth the application itself uses.
 *
 * Idempotent per (orgId, key), so it is safe to run repeatedly and safe to run
 * against an org that needs nothing.
 *
 *   DATABASE_URL=... npx ts-node --transpile-only prisma/backfill-roles.ts
 */
import { PrismaClient } from '@prisma/client';
import { createOrgRoles } from '../src/rbac';

const prisma = new PrismaClient();

async function main() {
  const orgs = await prisma.organization.findMany({
    where: { deletedAt: null },
    select: { id: true, name: true, capabilities: true },
    orderBy: { createdAt: 'asc' },
  });

  let created = 0;
  for (const org of orgs) {
    const before = await prisma.role.count({ where: { orgId: org.id } });
    await createOrgRoles(prisma, org.id, org.capabilities);
    const after = await prisma.role.count({ where: { orgId: org.id } });
    const added = after - before;
    created += added;
    console.log(
      `${added > 0 ? '+' : ' '}${String(added).padStart(2)}  ${org.name}  [${org.capabilities.join(', ')}]`,
    );
  }
  console.log(`\n${created} role(s) created across ${orgs.length} organisation(s).`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
