export default async function handler(req, res) {
  const supabaseUrl = process.env.SUPABASE_URL;
  const supabaseKey = process.env.SUPABASE_PUBLISHABLE_KEY;

  if (!supabaseUrl || !supabaseKey) {
    res.status(500).json({ error: 'Missing Supabase environment variables.' });
    return;
  }

  try {
    const supabaseResponse = await fetch(
      `${supabaseUrl}/rest/v1/stores?select=slug&is_published=eq.true`,
      {
        headers: {
          'apikey': supabaseKey,
          'Authorization': `Bearer ${supabaseKey}`,
        },
      }
    );

    if (!supabaseResponse.ok) {
      throw new Error(`Supabase query failed with status: ${supabaseResponse.status}`);
    }

    const stores = await supabaseResponse.json();
    const host = req.headers.host || 'vitrinx.app';
    const protocol = req.headers['x-forwarded-proto'] || 'https';

    let xml = '<?xml version="1.0" encoding="UTF-8"?>\n';
    xml += '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n';

    // Add main landing page
    xml += `  <url>\n`;
    xml += `    <loc>${protocol}://${host}/</loc>\n`;
    xml += `    <changefreq>daily</changefreq>\n`;
    xml += `    <priority>1.0</priority>\n`;
    xml += `  </url>\n`;

    // Add each store
    for (const store of stores) {
      if (store.slug) {
        xml += `  <url>\n`;
        xml += `    <loc>${protocol}://${host}/v/${encodeURIComponent(store.slug)}</loc>\n`;
        xml += `    <changefreq>daily</changefreq>\n`;
        xml += `    <priority>0.8</priority>\n`;
        xml += `  </url>\n`;
      }
    }

    xml += '</urlset>';

    res.setHeader('Content-Type', 'application/xml');
    res.status(200).send(xml);
  } catch (error) {
    console.error('Sitemap generation error:', error);
    res.status(500).json({ error: 'Failed to generate sitemap.' });
  }
}
