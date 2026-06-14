export default function handler(req, res) {
  res.setHeader('Content-Type', 'text/plain');
  res.status(200).send(`User-agent: *
Allow: /
Sitemap: https://${req.headers.host}/sitemap.xml`);
}
