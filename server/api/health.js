export default function health(_req, res) {
  res.setHeader('Cache-Control', 'no-store');
  res.status(200).json({ service: 'Little Bamboo', status: 'ok' });
}
