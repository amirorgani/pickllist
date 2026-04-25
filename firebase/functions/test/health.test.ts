import assert from 'node:assert/strict';
import { describe, it } from 'node:test';

import { healthPayload } from '../src/index';

describe('healthPayload', () => {
  it('returns a stable smoke-test payload', () => {
    assert.deepEqual(healthPayload(), {
      ok: true,
      service: 'pickllist-functions',
    });
  });
});
