import { timingSafeEqual } from 'node:crypto';
import { validateInput, systemFor } from '../lib/parenting.js';

function authorized(value, key) {
  if (!key || key.length < 32 || typeof value !== 'string') return false;
  const actual = Buffer.from(value);
  const expected = Buffer.from(`Bearer ${key}`);
  return actual.length === expected.length && timingSafeEqual(actual, expected);
}

// Best-effort per-instance throttling for a private prototype, not a distributed quota.
export function createHandler({ env = process.env, fetchImpl = fetch, now = Date.now } = {}) {
  let windowStart = now();
  let requests = 0;
  let inFlight = 0;
  return async function chat(req, res) {
    res.setHeader('Cache-Control', 'no-store');
    const send = (status, body) => res.status(status).json(body);
    if (req.method !== 'POST') {
      res.setHeader('Allow', 'POST');
      return send(405, { error: 'Use POST to send a message.' });
    }
    if (!env.CHAT_ACCESS_KEY || env.CHAT_ACCESS_KEY.length < 32 || !env.ANTHROPIC_API_KEY) {
      return send(503, { error: 'Little Bamboo’s AI connection is not set up yet.' });
    }
    if (!authorized(req.headers.authorization, env.CHAT_ACCESS_KEY)) {
      return send(401, { error: 'Add a valid private access key in AI connection.' });
    }
    const contentType = req.headers['content-type'] ?? '';
    if (!contentType.toLowerCase().includes('application/json')) return send(415, { error: 'Send application/json.' });
    let input;
    try {
      const body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
      input = validateInput(body);
    } catch (error) {
      return send(400, { error: error instanceof SyntaxError ? 'Invalid JSON.' : error.message });
    }
    if (now() - windowStart >= 60000) { windowStart = now(); requests = 0; }
    if (requests >= 12 || inFlight >= 3) {
      res.setHeader('Retry-After', '60');
      return send(429, { error: 'Let’s take a short pause. Please try again in a minute.' });
    }
    requests++;
    inFlight++;
    try {
      const upstream = await fetchImpl('https://api.anthropic.com/v1/messages', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'x-api-key': env.ANTHROPIC_API_KEY, 'anthropic-version': '2023-06-01' },
        body: JSON.stringify({ model: env.ANTHROPIC_MODEL || 'claude-haiku-4-5', max_tokens: 1200,
          system: systemFor(input.profile, input.language), messages: input.messages }),
        signal: AbortSignal.timeout(50000)
      });
      if (!upstream.ok) {
        return send(upstream.status === 429 ? 429 : 503, {
          error: 'Little Bamboo is having trouble connecting. Please try again shortly.'
        });
      }
      const output = await upstream.json();
      const reply = output.content?.filter(block => block.type === 'text').map(block => block.text).join('\n').trim();
      if (!reply || output.stop_reason === 'max_tokens') {
        return send(502, { error: 'That reply couldn’t be completed. Please try a shorter question.' });
      }
      return send(200, { reply });
    } catch {
      return send(503, { error: 'The connection took too long. Please try again.' });
    } finally { inFlight--; }
  };
}

export default createHandler();
