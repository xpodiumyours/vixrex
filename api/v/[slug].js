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
      // Return a standard clean 404 SEO page if the store is not found or not published
      res.status(404).send(`<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Mağaza Bulunamadı - VitrinX</title>
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
  <p><a href="/">VitrinX Ana Sayfasına Dön</a></p>
</body>
</html>`);
      return;
    }

    const store = stores[0];
    const host = req.headers.host || 'vitrinx.app';
    const protocol = req.headers['x-forwarded-proto'] || 'https';
    const publicUrl = `${protocol}://${host}/v/${store.slug}`;

    // 1. Build LocalBusiness JSON-LD Schema
    const localBusiness = {
      '@context': 'https://schema.org',
      '@type': 'LocalBusiness',
      'name': (store.name || '').trim(),
      'description': (store.description || '').trim(),
    };

    if (store.address && store.address.trim().length > 0) {
      localBusiness['address'] = {
        '@type': 'PostalAddress',
        'streetAddress': store.address.trim(),
      };
    }

    if (store.latitude != null && store.longitude != null) {
      localBusiness['geo'] = {
        '@type': 'GeoCoordinates',
        'latitude': store.latitude,
        'longitude': store.longitude,
      };
    }

    if (store.whatsapp && store.whatsapp.trim().length > 0) {
      localBusiness['telephone'] = store.whatsapp.trim();
    }

    // Handle gallery image
    let galleryItems = [];
    try {
      if (typeof store.gallery_items === 'string') {
        galleryItems = JSON.parse(store.gallery_items);
      } else if (Array.isArray(store.gallery_items)) {
        galleryItems = store.gallery_items;
      }
    } catch (e) {
      console.error('Failed to parse gallery_items', e);
    }

    if (galleryItems.length > 0 && galleryItems[0].imageUrl) {
      const imgUrl = galleryItems[0].imageUrl.trim();
      if (imgUrl.length > 0) {
        localBusiness['image'] = imgUrl;
      }
    }

    if (publicUrl) {
      localBusiness['url'] = publicUrl;
    }

    // Working Hours Parser
    if (store.working_hours) {
      const hoursRegex = /^(\d{2}:\d{2})\s*-\s*(\d{2}:\d{2})$/;
      const match = hoursRegex.exec(store.working_hours.trim());
      if (match) {
        const opens = match[1];
        const closes = match[2];
        localBusiness['openingHoursSpecification'] = {
          '@type': 'OpeningHoursSpecification',
          'dayOfWeek': [
            'Monday',
            'Tuesday',
            'Wednesday',
            'Thursday',
            'Friday',
            'Saturday',
            'Sunday',
          ],
          'opens': opens,
          'closes': closes,
        };
      }
    }

    // Products Parser
    let products = [];
    try {
      if (typeof store.products === 'string') {
        products = JSON.parse(store.products);
      } else if (Array.isArray(store.products)) {
        products = store.products;
      }
    } catch (e) {
      console.error('Failed to parse products', e);
    }

    const digitRegex = /\d/;
    let hasNumericalPrice = false;
    for (const product of products) {
      if (product.price && digitRegex.test(product.price)) {
        hasNumericalPrice = true;
        break;
      }
    }

    if (hasNumericalPrice) {
      localBusiness['priceRange'] = '$$';
    }

    const productsList = [];
    for (const product of products) {
      const productSchema = {
        '@context': 'https://schema.org',
        '@type': 'Product',
        'name': (product.name || '').trim(),
        'description': (product.description || '').trim(),
      };

      if (product.imagePath && product.imagePath.trim().length > 0) {
        productSchema['image'] = product.imagePath.trim();
      }

      if (product.price && digitRegex.test(product.price)) {
        const cleanPrice = product.price.replace(/[^0-9.,]/g, '').replace(',', '.');
        if (cleanPrice.length > 0) {
          const currency = product.price.includes('TL') || product.price.includes('₺') ? 'TRY' : 'USD';
          productSchema['offers'] = {
            '@type': 'Offer',
            'price': cleanPrice,
            'priceCurrency': currency,
            'availability': product.stockStatus === 'Tükendi'
              ? 'https://schema.org/OutOfStock'
              : 'https://schema.org/InStock',
          };
        }
      }

      productsList.add ? productsList.add(productSchema) : productsList.push(productSchema);
    }

    let jsonLdMap = localBusiness;
    if (productsList.length > 0) {
      jsonLdMap = {
        '@context': 'https://schema.org',
        '@graph': [
          localBusiness,
          ...productsList,
        ],
      };
    }

    // Escape script tags in JSON strings just in case
    const jsonLdString = JSON.stringify(jsonLdMap).replace(/</g, '\\u003c');

    const title = `${store.name || 'Vitrin'} - VitrinX`;
    const description = store.description || 'Küçük işletmeler için dijital vitrin kartı.';

    // 2. Generate HTML SEO Shell
    const html = `<!DOCTYPE html>
<html>
<head>
  <base href="/">
  <meta charset="UTF-8">
  <meta content="IE=Edge" http-equiv="X-UA-Compatible">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="description" content="${description.replace(/"/g, '&quot;')}">

  <!-- iOS meta tags & icons -->
  <meta name="mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black">
  <meta name="apple-mobile-web-app-title" content="VitrinX">
  <link rel="apple-touch-icon" href="/icons/Icon-192.png">

  <!-- Favicon -->
  <link rel="icon" type="image/png" href="/favicon.png"/>

  <title>${title.replace(/"/g, '&quot;')}</title>
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

    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.status(200).send(html);
  } catch (error) {
    console.error('SEO Shell Generation Error:', error);
    res.status(500).send('Internal Server Error');
  }
}
