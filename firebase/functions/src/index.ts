import { onRequest } from 'firebase-functions/v2/https';

export interface HealthPayload {
  ok: true;
  service: 'pickllist-functions';
}

export function healthPayload(): HealthPayload {
  return {
    ok: true,
    service: 'pickllist-functions',
  };
}

export const health = onRequest((_request, response) => {
  response.status(200).json(healthPayload());
});
