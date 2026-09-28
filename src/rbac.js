"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ROLE_TEMPLATES = void 0;
exports.ownerRoleKey = ownerRoleKey;
exports.permissionKeys = permissionKeys;
exports.createOrgRoles = createOrgRoles;
const ALL_ACTIONS = [
    'View',
    'Create',
    'Edit',
    'Approve',
    'Dispatch',
    'Settle',
    'Report',
];
const ownerPerms = () => ALL_ACTIONS.map((action) => ({ resource: '*', action }));
const perms = (resources, actions) => resources.flatMap((resource) => actions.map((action) => ({ resource, action })));
exports.ROLE_TEMPLATES = {
    FARMER: [
        { key: 'FARMER_OWNER', name: 'Owner', capability: 'FARMER', permissions: ownerPerms() },
        {
            key: 'FARMER_MANAGER',
            name: 'Farm Manager',
            capability: 'FARMER',
            permissions: [
                ...perms(['farm', 'shed', 'batch', 'dailyLog', 'feed', 'health'], ['View', 'Create', 'Edit', 'Report']),
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
function ownerRoleKey(capability) {
    return exports.ROLE_TEMPLATES[capability][0].key;
}
/** Flatten a role's permissions into `resource:Action` keys. */
function permissionKeys(template) {
    return template.permissions.map((p) => `${p.resource}:${p.action}`);
}
/**
 * Create org-scoped roles (+ permissions) for the given capabilities.
 * Idempotent per (orgId, key). Returns a map of roleKey -> roleId.
 */
async function createOrgRoles(tx, orgId, capabilities) {
    const map = {};
    for (const capability of capabilities) {
        for (const template of exports.ROLE_TEMPLATES[capability]) {
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
            const role = existing ??
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
//# sourceMappingURL=rbac.js.map