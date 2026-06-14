export default function handler(req, res) {
  const host = req.headers.host || 'vitrinx.app';
  const protocol = req.headers['x-forwarded-proto'] || 'https';

  res.setHeader('Content-Type', 'text/plain');
  
  // Vercel CDN Caching: Cache for 24 hours, stale-while-revalidate for 1 hour
  res.setHeader('Cache-Control', 'public, s-maxage=86400, stale-while-revalidate=3600');

  res.status(200).send(`User-agent: *
Allow: /
Allow: /v/
Allow: /explore
Disallow: /auth
Disallow: /store-editor
Disallow: /vitrin-editor
Disallow: /api/

Sitemap: ${protocol}://${host}/sitemap.xml`);
}
