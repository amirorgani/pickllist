import { test, before, after, beforeEach } from 'node:test';
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { makeEnv, seedFixture, PUB_LIST, DRAFT_LIST } from './helpers.mjs';

let env;

before(async () => {
  env = await makeEnv();
});

after(async () => {
  if (env) await env.cleanup();
});

beforeEach(async () => {
  if (env) await env.clearFirestore();
  await seedFixture(env);
});

function asManager() {
  return env.authenticatedContext('manager_1').firestore();
}
function asWorker(uid = 'worker_a') {
  return env.authenticatedContext(uid).firestore();
}
function asUnsigned() {
  return env.unauthenticatedContext().firestore();
}

test('manager can do anything: read/create/update/delete picking lists', async () => {
  const db = asManager();
  await assertSucceeds(db.doc(PUB_LIST).get());
  await assertSucceeds(db.doc(DRAFT_LIST).get());

  await assertSucceeds(db.collection('pickingLists').doc('mgr_new').set({
    name: 'New', scheduledAt: new Date(), status: 'draft',
    createdBy: 'manager_1', updatedAt: new Date(),
  }));
  await assertSucceeds(db.doc('pickingLists/mgr_new').update({ name: 'Renamed' }));
  await assertSucceeds(db.doc('pickingLists/mgr_new').delete());
});

test('worker can read published list but not a draft list', async () => {
  const db = asWorker();
  await assertSucceeds(db.doc(PUB_LIST).get());
  await assertFails(db.doc(DRAFT_LIST).get());
});

test('worker cannot read items of a draft list', async () => {
  const db = asWorker();
  await assertSucceeds(db.doc(`${PUB_LIST}/items/free`).get());
  await assertFails(db.doc(`${DRAFT_LIST}/items/d1`).get());
});

test('unsigned user cannot read or write anything', async () => {
  const db = asUnsigned();
  await assertFails(db.doc(PUB_LIST).get());
  await assertFails(db.doc('users/worker_a').get());
  await assertFails(db.doc('crops/c_t').get());
  await assertFails(db.collection('pickingLists').doc('x').set({
    name: 'x', scheduledAt: new Date(), status: 'draft',
    createdBy: 'x', updatedAt: new Date(),
  }));
});

test('worker can claim an unassigned row (assignedTo: null -> self)', async () => {
  const db = asWorker('worker_a');
  await assertSucceeds(
    db.doc(`${PUB_LIST}/items/free`).update({ assignedTo: 'worker_a' }),
  );
});

test('worker cannot claim a row that belongs to another worker', async () => {
  const db = asWorker('worker_b');
  await assertFails(
    db.doc(`${PUB_LIST}/items/owned_by_a`).update({ assignedTo: 'worker_b' }),
  );
});

test('worker cannot claim a row by setting assignedTo to a third party', async () => {
  // Even if the row is unassigned, a worker can only assign to themselves.
  const db = asWorker('worker_a');
  await assertFails(
    db.doc(`${PUB_LIST}/items/free`).update({ assignedTo: 'worker_b' }),
  );
});

test('worker can release their own row (assignedTo: self -> null)', async () => {
  const db = asWorker('worker_a');
  await assertSucceeds(
    db.doc(`${PUB_LIST}/items/owned_by_a`).update({ assignedTo: null }),
  );
});

test('worker cannot reassign their row to someone else', async () => {
  const db = asWorker('worker_a');
  await assertFails(
    db.doc(`${PUB_LIST}/items/owned_by_a`).update({ assignedTo: 'worker_b' }),
  );
});

test('worker cannot mutate arbitrary fields like quantity or cropName', async () => {
  const db = asWorker('worker_a');
  await assertFails(
    db.doc(`${PUB_LIST}/items/owned_by_a`).update({ quantity: 999 }),
  );
  await assertFails(
    db.doc(`${PUB_LIST}/items/owned_by_a`).update({ cropName: 'Hacked' }),
  );
});

test('worker cannot create or delete picking list items', async () => {
  const db = asWorker('worker_a');
  await assertFails(
    db.doc(`${PUB_LIST}/items/new_by_worker`).set({
      cropId: 'c_t', cropName: 'Tomatoes', quantity: 1, unit: 'kg',
      assignedTo: null, pickedQuantity: null, pickedAt: null, completedBy: null,
    }),
  );
  await assertFails(db.doc(`${PUB_LIST}/items/free`).delete());
});

test('worker can mark their own row picked', async () => {
  const db = asWorker('worker_a');
  await assertSucceeds(
    db.doc(`${PUB_LIST}/items/owned_by_a`).update({
      pickedQuantity: 4.5,
      pickedAt: new Date(),
      completedBy: 'worker_a',
    }),
  );
});

test('worker cannot mark another worker\'s row picked', async () => {
  const db = asWorker('worker_b');
  await assertFails(
    db.doc(`${PUB_LIST}/items/owned_by_a`).update({
      pickedQuantity: 4.5,
      pickedAt: new Date(),
      completedBy: 'worker_b',
    }),
  );
});

test('worker cannot create or update picking list documents', async () => {
  const db = asWorker('worker_a');
  await assertFails(
    db.collection('pickingLists').doc('worker_made').set({
      name: 'x', scheduledAt: new Date(), status: 'published',
      createdBy: 'worker_a', updatedAt: new Date(),
    }),
  );
  await assertFails(
    db.doc(PUB_LIST).update({ name: 'Renamed by worker' }),
  );
});

test('worker can read user directory and crops', async () => {
  const db = asWorker('worker_a');
  await assertSucceeds(db.doc('users/worker_b').get());
  await assertSucceeds(db.doc('crops/c_t').get());
});

test('worker cannot write users or crops', async () => {
  const db = asWorker('worker_a');
  await assertFails(db.doc('users/new').set({ role: 'worker', email: 'x', displayName: 'x' }));
  await assertFails(db.doc('crops/c_x').set({ name: 'x', defaultUnit: 'kg', active: true }));
});

test('manager can write users and crops and templates', async () => {
  const db = asManager();
  await assertSucceeds(db.doc('users/new').set({ role: 'worker', email: 'x', displayName: 'x' }));
  await assertSucceeds(db.doc('crops/c_x').set({ name: 'x', defaultUnit: 'kg', active: true }));
  await assertSucceeds(db.doc('templates/t2').set({ name: 'Saturday', items: [] }));
});
