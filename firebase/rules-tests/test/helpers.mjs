import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';
import {
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';

const here = dirname(fileURLToPath(import.meta.url));

export const RULES_PATH = resolve(here, '..', '..', 'firestore.rules');
export const PROJECT_ID = 'demo-pickllist';

export function loadRules() {
  return readFileSync(RULES_PATH, 'utf8');
}

export async function makeEnv() {
  return initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: loadRules(),
      // Talk to the emulator on the host firebase.json declares
      // (firebase emulators:exec sets FIRESTORE_EMULATOR_HOST for us).
      host: '127.0.0.1',
      port: 8080,
    },
  });
}

/**
 * Seed a small fixture using the privileged context (rules are bypassed).
 * The fixture has:
 *   - users/manager_1   role=manager
 *   - users/worker_a    role=worker
 *   - users/worker_b    role=worker
 *   - pickingLists/list_pub        status=published
 *   - pickingLists/list_pub/items/free            assignedTo=null
 *   - pickingLists/list_pub/items/owned_by_a      assignedTo=worker_a
 *   - pickingLists/list_draft      status=draft
 *   - pickingLists/list_draft/items/d1            assignedTo=null
 */
export async function seedFixture(env) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await db.doc('users/manager_1').set({ role: 'manager', email: 'm@x', displayName: 'M' });
    await db.doc('users/worker_a').set({ role: 'worker',  email: 'a@x', displayName: 'A' });
    await db.doc('users/worker_b').set({ role: 'worker',  email: 'b@x', displayName: 'B' });

    await db.doc('pickingLists/list_pub').set({
      name: 'Published list',
      scheduledAt: new Date('2026-04-10'),
      status: 'published',
      createdBy: 'manager_1',
      updatedAt: new Date('2026-04-09'),
    });
    await db.doc('pickingLists/list_pub/items/free').set({
      cropId: 'c_t', cropName: 'Tomatoes', quantity: 10, unit: 'kg',
      assignedTo: null, pickedQuantity: null, pickedAt: null, completedBy: null,
    });
    await db.doc('pickingLists/list_pub/items/owned_by_a').set({
      cropId: 'c_p', cropName: 'Peppers', quantity: 5, unit: 'units',
      assignedTo: 'worker_a', pickedQuantity: null, pickedAt: null, completedBy: null,
    });

    await db.doc('pickingLists/list_draft').set({
      name: 'Draft list',
      scheduledAt: new Date('2026-04-12'),
      status: 'draft',
      createdBy: 'manager_1',
      updatedAt: new Date('2026-04-09'),
    });
    await db.doc('pickingLists/list_draft/items/d1').set({
      cropId: 'c_t', cropName: 'Tomatoes', quantity: 1, unit: 'kg',
      assignedTo: null, pickedQuantity: null, pickedAt: null, completedBy: null,
    });

    await db.doc('crops/c_t').set({ name: 'Tomatoes', defaultUnit: 'kg', active: true });

    await db.doc('templates/t1').set({ name: 'Friday', items: [] });
  });
}

export const PUB_LIST = 'pickingLists/list_pub';
export const DRAFT_LIST = 'pickingLists/list_draft';
