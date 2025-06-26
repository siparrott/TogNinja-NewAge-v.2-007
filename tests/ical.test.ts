import handler from '../../src/api/ical';
import { createMocks } from 'node-mocks-http';

describe('iCal handler', () => {
  it('returns 400 if no userId', async () => {
    const { req, res } = createMocks({
      method: 'GET',
      query: {},
    });

    await handler(req as any, res as any);
    expect(res._getStatusCode()).toBe(400);
  });
});
