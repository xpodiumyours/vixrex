function escapeHtmlAttr(unsafe) {
  if (!unsafe) return '';
  return unsafe
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}

export default async function handler(req, res) {
  const { slug } = req.query;
  const supabaseUrl = process.env.SUPABASE_URL;
  const supabaseKey = process.env.SUPABASE_PUBLISHABLE_KEY;

  if (!supabaseUrl || !supabaseKey) {
    res.status(500).send('Internal Server Error: Missing configuration.');
    return;
  }

  try {
    const supabaseResponse = await fetch(
      `${supabaseUrl}/rest/v1/stores?slug=eq.${encodeURIComponent(slug)}&is_published=eq.true`,
      {
        headers: {
          'apikey': supabaseKey,
          'Authorization': `Bearer ${supabaseKey}`,
        },
      }
    );

    if (!supabaseResponse.ok) {
      throw new Error(`Supabase query failed: ${supabaseResponse.status}`);
    }

    const stores = await supabaseResponse.json();

    if (!stores || stores.length === 0) {
      res.status(404).send(`<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Mağaza Bulunamadı - VixRex</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; text-align: center; padding: 50px; background: #fafafa; color: #333; }
    h1 { color: #e53e3e; }
    a { color: #3182ce; text-decoration: none; }
  </style>
</head>
<body>
  <h1>404 - Mağaza Bulunamadı</h1>
  <p>Aradığınız dijital vitrin bulunamadı veya henüz yayınlanmadı.</p>
  <p><a href="/">VixRex Ana Sayfasına Dön</a></p>
</body>
</html>`);
      return;
    }

    const store = stores[0];
    const host = req.headers.host || 'vixrex.app';
    const protocol = req.headers['x-forwarded-proto'] || 'https';
    const publicUrl = `${protocol}://${host}/v/${store.slug}`;

    const storeName = (store.name || '').trim();
    const storeDescription = (store.description || store.corporate_bio || '').trim();
    const hasPhysicalLocation =
      Boolean(store.address && store.address.trim()) &&
      store.latitude != null &&
      store.longitude != null;
    const entityId = `${publicUrl}#business`;

    let galleryItems = [];
    try {
      if (typeof store.gallery_items === 'string') {
        galleryItems = JSON.parse(store.gallery_items);
      } else if (Array.isArray(store.gallery_items)) {
        galleryItems = store.gallery_items;
      }
    } catch (e) {}

    const galleryCover =
      galleryItems.length > 0 && galleryItems[0].imageUrl
        ? galleryItems[0].imageUrl.trim()
        : '';
    const imageUrl =
      (store.shelf_image_url || '').trim() ||
      galleryCover ||
      (store.logo_url || '').trim();
    const phoneDigits = String(store.whatsapp || '').replace(/[^0-9]/g, '');
    const normalizedPhone =
      /^05\d{9}$/.test(phoneDigits)
        ? `+90${phoneDigits.substring(1)}`
        : /^5\d{9}$/.test(phoneDigits)
          ? `+90${phoneDigits}`
          : /^905\d{9}$/.test(phoneDigits)
            ? `+${phoneDigits}`
            : '';

    const entity = {
      '@type': hasPhysicalLocation ? 'LocalBusiness' : 'Organization',
      '@id': entityId,
      'name': storeName,
      'url': publicUrl,
    };

    if (storeDescription) entity.description = storeDescription;
    if (imageUrl) entity.image = imageUrl;
    if (store.logo_url && store.logo_url.trim()) {
      entity.logo = store.logo_url.trim();
    }
    if (normalizedPhone) entity.telephone = normalizedPhone;

    if (hasPhysicalLocation) {
      entity.address = {
        '@type': 'PostalAddress',
        'streetAddress': store.address.trim(),
        'addressCountry': 'TR',
      };
      entity.geo = {
        '@type': 'GeoCoordinates',
        'latitude': store.latitude,
        'longitude': store.longitude,
      };
      entity.hasMap = `https://www.google.com/maps/search/?api=1&query=${store.latitude},${store.longitude}`;

      if (store.working_hours) {
        const hoursMatch = /^(\d{2}:\d{2})\s*-\s*(\d{2}:\d{2})$/.exec(
          store.working_hours.trim(),
        );
        if (hoursMatch) {
          entity.openingHoursSpecification = {
            '@type': 'OpeningHoursSpecification',
            'dayOfWeek': ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
            'opens': hoursMatch[1],
            'closes': hoursMatch[2],
          };
        }
      }
    }

    const webPage = {
      '@type': 'WebPage',
      '@id': `${publicUrl}#webpage`,
      'url': publicUrl,
      'name': storeName ? `${storeName} | VixRex` : 'VixRex',
      'about': { '@id': entityId },
    };
    if (storeDescription) webPage.description = storeDescription;
    if (imageUrl) {
      webPage.primaryImageOfPage = {
        '@type': 'ImageObject',
        'url': imageUrl,
      };
    }

    const jsonLdMap = {
      '@context': 'https://schema.org',
      '@graph': [entity, webPage],
    };

    const jsonLdString = JSON.stringify(jsonLdMap).replace(/</g, '\\u003c');

    const rawTitle = store.name ? `${store.name} - VixRex` : 'VixRex';
    const rawDesc = store.description || store.corporate_bio || 'Küçük işletmeler için dijital vitrin kartı.';
    const shareImage = imageUrl || `${protocol}://${host}/favicon.png`;

    const title = escapeHtmlAttr(rawTitle);
    const description = escapeHtmlAttr(rawDesc);
    const escapedImageUrl = escapeHtmlAttr(shareImage);

    // 2. Dynamic HTML Shell with Social Share Meta Tags
    const html = `<!DOCTYPE html>
<html>
<head>
  <base href="/">
  <meta charset="UTF-8">
  <meta content="IE=Edge" http-equiv="X-UA-Compatible">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="description" content="${description}">

  <!-- Open Graph / Facebook / WhatsApp -->
  <meta property="og:type" content="profile">
  <meta property="og:title" content="${title}">
  <meta property="og:description" content="${description}">
  <meta property="og:image" content="${escapedImageUrl}">
  <meta property="og:url" content="${publicUrl}">
  <meta property="og:site_name" content="VixRex">

  <!-- Twitter -->
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="${title}">
  <meta name="twitter:description" content="${description}">
  <meta name="twitter:image" content="${escapedImageUrl}">

  <!-- iOS meta tags & icons -->
  <meta name="mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black">
  <meta name="apple-mobile-web-app-title" content="VixRex">
  <link rel="apple-touch-icon" href="/icons/Icon-192.png">

  <!-- Favicon -->
  <link rel="icon" type="image/png" href="/favicon.png"/>

  <title>${title}</title>
  <link rel="canonical" href="${publicUrl}">
  <link rel="manifest" href="/manifest.json">

  <!-- Dynamic Google Schema (JSON-LD) -->
  <script type="application/ld+json">
    ${jsonLdString}
  </script>
</head>
<body>
  <script>
    if ('serviceWorker' in navigator) {
      navigator.serviceWorker.getRegistrations().then(function(registrations) {
        registrations.forEach(function(registration) {
          registration.unregister();
        });
      });
    }
  </script>
  <!-- Bootstrapping Flutter Web App -->
  <script src="/flutter_bootstrap.js" async></script>
</body>
</html>`;

    // 30 Min cache, stale-while-revalidate for 5 minutes
    res.setHeader('Cache-Control', 'public, s-maxage=1800, stale-while-revalidate=300');
    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.status(200).send(html);
  } catch (error) {
    console.error('SEO Shell Generation Error:', error);
    res.status(500).send('Internal Server Error');
  }
}
