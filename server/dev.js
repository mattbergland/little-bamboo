import http from 'node:http';
import chat from './api/chat.js';
import health from './api/health.js';
import { readFile } from 'node:fs/promises';

http.createServer(async (req, res) => {
  res.status = code => { res.statusCode = code; return res; };
  res.json = body => { res.setHeader('Content-Type', 'application/json'); res.end(JSON.stringify(body)); };
  if (req.url === '/api/health') return health(req, res);
  if (req.url === '/api/chat') {
    let length = 0;
    const chunks = [];
    for await (const chunk of req) {
      length += chunk.length;
      if (length > 48000) return res.status(413).json({ error: 'Request too large.' });
      chunks.push(chunk);
    }
    req.body = Buffer.concat(chunks).toString('utf8');
    return chat(req, res);
  }
  if (req.url === '/') {
    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    return res.end(await readFile(new URL('./public/index.html', import.meta.url)));
  }
  res.status(404).json({ error: 'Not found.' });
}).listen(process.env.PORT || 3000, () => console.log('Little Bamboo service ready'));
