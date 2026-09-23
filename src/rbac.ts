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
  SUPPLIER: [
    { key: 'SUPPLIER_OWNER', name: 'Owner', capability: 'SUPPLIER', permissions: ownerPerms() },
    {
      key: 'SUPPLIER_MANAGER',
      name: 'Manager',
      capability: 'SUPPLIER',
      permissions: perms(['product', 'order', 'dispatch', 'invoice'], ['View', 'Create', 'Edit', 'Approve', 'Report']),
    },
    {
      key: 'SUPPLIER_OPERATIONS',
      name: 'Operations',
      capability: 'SUPPLIER',
      permissions: perms(['order', 'dispatch'], ['View', 'Edit', 'Dispatch']),
    },
    {
      key: 'SUPPLIER_FINANCE',
      name: 'Finance',
      capability: 'SUPPLIER',
      permissions: perms(['invoice', 'payment'], ['View', 'Report', 'Settle']),
    },
  ],
  DISTRIBUTOR: [
    { key: 'DISTRIBUTOR_OWNER', name: 'Owner', capability: 'DISTRIBUTOR', permissions: ownerPerms() },
    {
      key: 'DISTRIBUTOR_PROCUREMENT_MANAGER',
      name: 'Procurement Manager',
      capability: 'DISTRIBUTOR',
      permissions: perms(['discovery', 'purchase'], ['View', 'Create', 'Edit', 'Approve', 'Report']),
    },
    {
      key: 'DISTRIBUTOR_OPERATIONS_MANAGER',
      name: 'Operations Manager',
      capability: 'DISTRIBUTOR',
      permissions: perms(['purchase', 'collection'], ['View', 'Edit', 'Dispatch']),
    },
    {
      key: 'DISTRIBUTOR_FINANCE_MANAGER',
      name: 'Finance Manager',
      capability: 'DISTRIBUTOR',
      permissions: perms(['settlement'], ['View', 'Report', 'Settle']),
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
