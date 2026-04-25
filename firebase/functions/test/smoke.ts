import assert from 'node:assert/strict';

import { healthPayload } from '../src/index';

const payload = healthPayload();

assert.equal(payload.ok, true);
assert.equal(payload.service, 'pickllist-functions');

console.log('Functions smoke check passed.');
