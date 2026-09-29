import { randomUUID } from 'node:crypto';
import { Capability, PermissionAction, Prisma, PrismaClient } from '@prisma/client';

/**
 * Role + permission templates per capability. Onboarding (and the seed) create
 * org-scoped roles from these templates. Permission keys are `resource:Action`;
 * an owner holds `*` on every action. Keep in sync with docs/05-Auth-And-RBAC.md.
 */
export interface RoleTemplate {
  key: string;
  name: string;
  capability: Capability;
  permissions: { resource: string; action: PermissionAction }[];
}

const ALL_ACTIONS: PermissionAction[] = [
  'View',
  'Create',
  'Edit',
  'Approve',
  'Dispatch',
  'Settle',
  'Report',
];

const ownerPerms = (): { resource: string; action: PermissionAction }[] =>
  ALL_ACTIONS.map((action) => ({ resource: '*', action }));

const perms = (
  resources: string[],
  actions: PermissionAction[],
): { resource: string; action: PermissionAction }[] =>
  resources.flatMap((resource) => actions.map((action) => ({ resource, action })));

export const ROLE_TEMPLATES: Record<Capability, RoleTemplate[]> = {
  FARMER: [
    { key: 'FARMER_OWNER', name: 'Owner', capability: 'FARMER', permissions: ownerPerms() },
    {
      key: 'FARMER_MANAGER',
      name: 'Farm Manager',
      capability: 'FARMER',
      permissions: [
        ...perms(
          ['farm', 'shed', 'batch', 'dailyLog', 'feed', 'health'],
          ['View', 'Create', 'Edit', 'Report'],
        ),
        // The manager enters what the farm spent — wages, power, rent, and the
        // feed and medicine bills. They are the one on site when the bill
        // arrives; the owner frequently is not.
        //
        // Note the missing verb. `finance:Report` is what reads profit, margin
        // and the batch and farm comparisons, and it stays with the owner. A
        // manager paid partly on the farm's performance should not be the one
        // reading the number they are measured by.
        ...perms(['finance'], ['View', 'Create', 'Edit']),
      ],
    },
    {
      key: 'FARMER_OPERATOR',
      name: 'Farm Operator',
      capability: 'FARMER',
      permissions: [
        // Read-only on the farm and shed he is assigned to: he needs to see
        // which shed he is logging. MemberScope decides *which* ones.
        ...perms(['farm', 'shed'], ['View']),
        ...perms(['batch', 'dailyLog', 'feed', 'health'], ['View', 'Create', 'Edit']),
      ],
    },
    {
      key: 'FARMER_ACCOUNTANT',
      name: 'Accountant',
      capability: 'FARMER',
      permissions: perms(['finance', 'settlement', 'batch'], ['View', 'Report', 'Settle']),
    },
  ],
  // Hatchery and Feed Supplier run the same shape of business — publish a
  // catalog, take orders, confirm terms, dispatch, invoice, reconcile — so
  // they carry the same four roles over the same resources. They are separate
  // capabilities rather than one "supplier" because the spec keeps them
  // distinct direct sources, and because an org may be one without being the
  // other.
  HATCHERY: [
    { key: 'HATCHERY_OWNER', name: 'Owner', capability: 'HATCHERY', permissions: ownerPerms() },
    {
      key: 'HATCHERY_MANAGER',
      name: 'Manager',
      capability: 'HATCHERY',
      permissions: perms(['product', 'order', 'dispatch', 'invoice'], ['View', 'Create', 'Edit', 'Approve', 'Report']),
    },
    {
      key: 'HATCHERY_OPERATIONS',
      name: 'Operations',
      capability: 'HATCHERY',
      permissions: perms(['order', 'dispatch'], ['View', 'Edit', 'Dispatch']),
    },
    {
      key: 'HATCHERY_FINANCE',
      name: 'Finance',
      capability: 'HATCHERY',
      permissions: perms(['invoice', 'payment'], ['View', 'Report', 'Settle']),
    },
  ],
  FEED_SUPPLIER: [
    { key: 'FEED_SUPPLIER_OWNER', name: 'Owner', capability: 'FEED_SUPPLIER', permissions: ownerPerms() },
    {
      key: 'FEED_SUPPLIER_MANAGER',
      name: 'Manager',
      capability: 'FEED_SUPPLIER',
      permissions: perms(['product', 'order', 'dispatch', 'invoice'], ['View', 'Create', 'Edit', 'Approve', 'Report']),
    },
    {
      key: 'FEED_SUPPLIER_OPERATIONS',
      name: 'Operations',
      capability: 'FEED_SUPPLIER',
      permissions: perms(['order', 'dispatch'], ['View', 'Edit', 'Dispatch']),
    },
    {
      key: 'FEED_SUPPLIER_FINANCE',
      name: 'Finance',
      capability: 'FEED_SUPPLIER',
      permissions: perms(['invoice', 'payment'], ['View', 'Report', 'Settle']),
    },
  ],
  // The intermediary. `quote` and `offer` are its own resources: it works by
  // quoting inputs and by passing farmer-authorised harvest offers to lifters,
  // which is not the same as owning stock or buying birds. It gets no
  // `dispatch` — a partner who never takes delivery cannot dispatch — and no
  // `farm` or `batch`, because access to those is granted per transaction by
  // the farmer rather than carried by the role.
  TRADING_PARTNER: [
    { key: 'TRADING_PARTNER_OWNER', name: 'Owner', capability: 'TRADING_PARTNER', permissions: ownerPerms() },
    {
      key: 'TRADING_PARTNER_MANAGER',
      name: 'Manager',
      capability: 'TRADING_PARTNER',
      permissions: perms(['quote', 'order', 'offer'], ['View', 'Create', 'Edit', 'Approve', 'Report']),
    },
    {
      key: 'TRADING_PARTNER_FINANCE',
      name: 'Finance',
      capability: 'TRADING_PARTNER',
      permissions: perms(['invoice', 'commission', 'payment'], ['View', 'Report', 'Settle']),
    },
  ],
  // What DISTRIBUTOR was. `collection` is the pickup itself and `purchase` the
  // commercial side, and they are deliberately separate: a lifter may collect
  // without being the buyer, so the two must be recordable against different
  // parties.
  LIFTING_PARTNER: [
    { key: 'LIFTING_PARTNER_OWNER', name: 'Owner', capability: 'LIFTING_PARTNER', permissions: ownerPerms() },
    {
      key: 'LIFTING_PARTNER_OPERATIONS',
      name: 'Operations',
      capability: 'LIFTING_PARTNER',
      permissions: perms(['offer', 'purchase', 'collection'], ['View', 'Create', 'Edit', 'Dispatch']),
    },
    {
      key: 'LIFTING_PARTNER_FINANCE',
      name: 'Finance',
      capability: 'LIFTING_PARTNER',
      permissions: perms(['settlement', 'invoice'], ['View', 'Report', 'Settle']),
    },
  ],
  // Downstream. Buys, receives, reconciles — and reads nothing of a farmer's
  // flock health, medicine or profitability.
  CHICKEN_RETAILER: [
    { key: 'CHICKEN_RETAILER_OWNER', name: 'Owner', capability: 'CHICKEN_RETAILER', permissions: ownerPerms() },
    {
      key: 'CHICKEN_RETAILER_MANAGER',
      name: 'Manager',
      capability: 'CHICKEN_RETAILER',
      permissions: perms(['demand', 'purchase', 'receipt'], ['View', 'Create', 'Edit', 'Approve', 'Report']),
    },
    {
      key: 'CHICKEN_RETAILER_FINANCE',
      name: 'Finance',
      capability: 'CHICKEN_RETAILER',
      permissions: perms(['invoice', 'payment'], ['View', 'Report', 'Settle']),
    },
  ],
};

/** The owner role key for a capability (assigned to the org creator). */
export function ownerRoleKey(capability: Capability): string {
  return ROLE_TEMPLATES[capability][0].key;
}

/** Flatten a role's permissions into `resource:Action` keys. */
export function permissionKeys(template: RoleTemplate): string[] {
  return template.permissions.map((p) => `${p.resource}:${p.action}`);
}

type Tx = PrismaClient | Prisma.TransactionClient;

/**
 * Create org-scoped roles (+ permissions) for the given capabilities.
 * Idempotent per (orgId, key). Returns a map of roleKey -> roleId.
 */
/**
 * Work out the roles an org needs, without writing any of them.
 *
 * The companion to [createOrgRoles], for callers that must commit everything
 * in one batch — which on D1 is the only kind of transaction there is. It does
 * the reads here and hands back the writes unexecuted, along with the role ids
 * the caller's own writes will reference.
 *
 * Ids for roles that do not exist yet are generated here rather than by the
 * database, because a membership created in the same batch has to name one and
 * a batched statement cannot read a sibling's result.
 */
export async function planOrgRoles(
  tx: Tx,
  orgId: string,
  capabilities: Capability[],
): Promise<{ writes: Prisma.PrismaPromise<unknown>[]; roleIds: Record<string, string> }> {
  const roleIds: Record<string, string> = {};
  const writes: Prisma.PrismaPromise<unknown>[] = [];

  for (const capability of capabilities) {
    for (const template of ROLE_TEMPLATES[capability]) {
      const existing = await tx.role.findFirst({
        where: { orgId, key: template.key },
        include: { permissions: true },
      });

      if (existing) {
        roleIds[template.key] = existing.id;
        // An org created before a permission was added to the template is
        // topped up rather than left short.
        const have = new Set(existing.permissions.map((p) => `${p.resource}:${p.action}`));
        const missing = template.permissions.filter(
          (p) => !have.has(`${p.resource}:${p.action}`),
        );
        if (missing.length) {
          writes.push(
            (tx as PrismaClient).permission.createMany({
              data: missing.map((p) => ({
                roleId: existing.id,
                resource: p.resource,
                action: p.action,
              })),
            }),
          );
        }
        continue;
      }

      const id = randomUUID();
      roleIds[template.key] = id;
      writes.push(
        (tx as PrismaClient).role.create({
          data: {
            id,
            key: template.key,
            name: template.name,
            capability: template.capability,
            orgId,
            permissions: {
              create: template.permissions.map((p) => ({
                resource: p.resource,
                action: p.action,
              })),
            },
          },
        }),
      );
    }
  }
  return { writes, roleIds };
}

export async function createOrgRoles(
  tx: Tx,
  orgId: string,
  capabilities: Capability[],
): Promise<Record<string, string>> {
  const map: Record<string, string> = {};
  for (const capability of capabilities) {
    for (const template of ROLE_TEMPLATES[capability]) {
      const existing = await tx.role.findFirst({
        where: { orgId, key: template.key },
        include: { permissions: true },
      });
      if (existing) {
        const have = new Set(existing.permissions.map((p) => `${p.resource}:${p.action}`));
        const missing = template.permissions.filter((p) => !have.has(`${p.resource}:${p.action}`));
        if (missing.length) {
          await tx.permission.createMany({
            data: missing.map((p) => ({ roleId: existing.id, resource: p.resource, action: p.action })),
          });
        }
      }
      const role =
        existing ??
        (await tx.role.create({
          data: {
            key: template.key,
            name: template.name,
            capability: template.capability,
            orgId,
            permissions: {
              create: template.permissions.map((p) => ({ resource: p.resource, action: p.action })),
            },
          },
        }));
      map[template.key] = role.id;
    }
  }
  return map;
}
