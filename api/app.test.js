const request = require('supertest');
const app = require('./app');

describe('ShopFlow API', () => {
  it('GET / returns a welcome message', async () => {
    const res = await request(app).get('/');
    expect(res.statusCode).toBe(200);
    expect(res.body.message).toBe('ShopFlow API is running');
  });

  it('GET /health returns ok status', async () => {
    const res = await request(app).get('/health');
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('ok');
  });
});
