const { test } = require('node:test');
const assert = require('node:assert/strict');
const express = require('express');
const jwt = require('jsonwebtoken');

process.env.JWT_SECRET = 'test-only-secret-never-use-in-production';
const router = require('../dist/routes/ai').default;

test('AI routes enforce authentication and keep provider keys server-side', async () => {
  const app = express();
  app.use(express.json());
  app.use('/api/ai', router);
  app.use((err, req, res, next) => res.status(err.statusCode || 500).json({ error: err.message }));
  const server = app.listen(0, '127.0.0.1');
  await new Promise(resolve => server.once('listening', resolve));
  const url = 'http://127.0.0.1:' + server.address().port + '/api/ai';
  const nativeFetch = global.fetch;
  const token = jwt.sign({ userId: 'test-user', email: 'test@example.com' }, process.env.JWT_SECRET);
  const headers = { 'Content-Type': 'application/json', Authorization: 'Bearer ' + token };
  try {
    const denied = await nativeFetch(url + '/search', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{}' });
    assert.equal(denied.status, 401);
    delete process.env.TAVILY_API_KEY;
    const disabled = await nativeFetch(url + '/search', { method: 'POST', headers, body: JSON.stringify({ companyName: 'Example', kind: 'events' }) });
    assert.equal(disabled.status, 503);
    process.env.TAVILY_API_KEY = 'test-provider-key';
    global.fetch = async (providerUrl, options) => {
      assert.equal(providerUrl, 'https://api.tavily.com/search');
      assert.equal(JSON.parse(options.body).api_key, 'test-provider-key');
      assert.equal(options.headers.Authorization, undefined);
      return new Response(JSON.stringify({ results: [], query: 'Example' }), { status: 200 });
    };
    const success = await nativeFetch(url + '/search', { method: 'POST', headers, body: JSON.stringify({ companyName: 'Example', kind: 'events' }) });
    assert.equal(success.status, 200);
    assert.deepEqual(await success.json(), { results: [], query: 'Example' });
  } finally {
    global.fetch = nativeFetch;
    delete process.env.TAVILY_API_KEY;
    server.closeAllConnections();
    await new Promise(resolve => server.close(resolve));
  }
});
