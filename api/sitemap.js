function escapeXml(unsafe) {
  return unsafe.replace(/[<>&'"]/g, (c) => {
    switch (c) {
      case '<': return '&lt;';
      case '>': return '&gt;';
      case '&': return '&amp;';
      case '\'': return '&apos;';
      case '"': return '&quot;';
      default: return c;
    }
  });
}

export default async function handler(req, res) {
  const supabaseUrl = process.env.SUPABASE_URL;
  const supabaseKey = process.env.SUPABASE_PUBLISHABLE_KEY;

  if (!supabaseUrl || !supabaseKey) {
    res.status(500).json({ error: 'Missing Supabase configuration.' });
    return;
  }

  try {
    const supabaseResponse = await fetch(
      `${supabaseUrl}/rest/v1/stores?select=slug,updated_at&is_published=eq.true&limit=5000`,
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

    // Main landing page
    xml += `  <url>\n`;
    xml += `    <loc>${protocol}://${host}/</loc>\n`;
    xml += `  </url>\n`;

    // Active vitrins
    for (const store of stores) {
      if (store.slug) {
        const safeSlug = escapeXml(store.slug);
        xml += `  <url>\n`;
        xml += `    <loc>${protocol}://${host}/v/${safeSlug}</loc>\n`;
        if (store.updated_at) {
          const updatedAt = new Date(store.updated_at);
          if (!Number.isNaN(updatedAt.getTime())) {
            xml += `    <lastmod>${updatedAt.toISOString()}</lastmod>\n`;
          }
        }
        xml += `  </url>\n`;
      }
    }

    xml += '</urlset>';

    // Configure Vercel Edge caching (Cache for 1 hour, stale-while-revalidate for 10 minutes)
    res.setHeader('Cache-Control', 'public, s-maxage=3600, stale-while-revalidate=600');
    res.setHeader('Content-Type', 'application/xml');
    res.status(200).send(xml);
  } catch (error) {
    console.error('Sitemap generation error:', error);
    res.status(500).json({ error: 'Failed to generate sitemap.' });
  }
}
