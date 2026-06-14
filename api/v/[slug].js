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

    // 1. LocalBusiness JSON-LD Schema
    const localBusiness = {
      '@context': 'https://schema.org',
      '@type': 'LocalBusiness',
      'name': (store.name || '').trim(),
      'description': (store.description || store.corporate_bio || '').trim(),
    };

    if (store.address && store.address.trim().length > 0) {
      const trimmedAddress = store.address.trim();
      localBusiness['address'] = {
        '@type': 'PostalAddress',
        'streetAddress': trimmedAddress,
      };

      // Parse city/district from address for areaServed
      const parts = trimmedAddress.split(',').map(p => p.trim()).filter(p => p.length > 0);
      if (parts.length > 0) {
        const city = parts[parts.length - 1];
        localBusiness['areaServed'] = {
          '@type': 'AdministrativeArea',
          'name': city,
        };
      }
    }

    if (store.latitude != null && store.longitude != null) {
      localBusiness['geo'] = {
        '@type': 'GeoCoordinates',
        'latitude': store.latitude,
        'longitude': store.longitude,
      };
      // hasMap Local SEO link
      localBusiness['hasMap'] = `https://www.google.com/maps/search/?api=1&query=${store.latitude},${store.longitude}`;
    }

    if (store.whatsapp && store.whatsapp.trim().length > 0) {
      localBusiness['telephone'] = store.whatsapp.trim();
    }

    if (store.logo_url && store.logo_url.trim().length > 0) {
      localBusiness['logo'] = store.logo_url.trim();
    }

    // Cover image mapping
    if (store.shelf_image_url && store.shelf_image_url.trim().length > 0) {
      localBusiness['image'] = store.shelf_image_url.trim();
    } else {
      let galleryItems = [];
      try {
        if (typeof store.gallery_items === 'string') {
          galleryItems = JSON.parse(store.gallery_items);
        } else if (Array.isArray(store.gallery_items)) {
          galleryItems = store.gallery_items;
        }
      } catch (e) {}

      if (galleryItems.length > 0 && galleryItems[0].imageUrl) {
        localBusiness['image'] = galleryItems[0].imageUrl.trim();
      }
    }

    if (publicUrl) {
      localBusiness['url'] = publicUrl;
    }

    // Working Hours
    if (store.working_hours) {
      const hoursRegex = /^(\d{2}:\d{2})\s*-\s*(\d{2}:\d{2})$/;
      const match = hoursRegex.exec(store.working_hours.trim());
      if (match) {
        localBusiness['openingHoursSpecification'] = {
          '@type': 'OpeningHoursSpecification',
          'dayOfWeek': ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
          'opens': match[1],
          'closes': match[2],
        };
      }
    }

    // 2. BreadcrumbList Schema
    const breadcrumbList = {
      '@context': 'https://schema.org',
      '@type': 'BreadcrumbList',
      'itemListElement': [
        {
          '@type': 'ListItem',
          'position': 1,
          'name': 'VitrinX',
          'item': `${protocol}://${host}/`,
        },
        {
          '@type': 'ListItem',
          'position': 2,
          'name': store.kategori || 'Keşfet',
          'item': `${protocol}://${host}/explore`,
        },
        {
          '@type': 'ListItem',
          'position': 3,
          'name': (store.name || '').trim(),
          'item': publicUrl,
        },
      ],
    };

    // Products Parser
    let products = [];
    try {
      if (typeof store.products === 'string') {
        products = JSON.parse(store.products);
      } else if (Array.isArray(store.products)) {
        products = store.products;
      }
    } catch (e) {}

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
      productsList.push(productSchema);
    }

    // Always use @graph representation containing LocalBusiness and BreadcrumbList
    const jsonLdMap = {
      '@context': 'https://schema.org',
      '@graph': [
        localBusiness,
        breadcrumbList,
        ...productsList,
      ],
    };

    const jsonLdString = JSON.stringify(jsonLdMap).replace(/</g, '\\u003c');

    const rawTitle = store.name ? `${store.name} - VitrinX` : 'VitrinX';
    const rawDesc = store.description || store.corporate_bio || 'Küçük işletmeler için dijital vitrin kartı.';
    const shareImage = store.logo_url || store.shelf_image_url || `${protocol}://${host}/favicon.png`;

    const title = escapeHtmlAttr(rawTitle);
    const description = escapeHtmlAttr(rawDesc);
    const imageUrl = escapeHtmlAttr(shareImage);

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
  <meta property="og:image" content="${imageUrl}">
  <meta property="og:url" content="${publicUrl}">
  <meta property="og:site_name" content="VitrinX">

  <!-- Twitter -->
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="${title}">
  <meta name="twitter:description" content="${description}">
  <meta name="twitter:image" content="${imageUrl}">

  <!-- iOS meta tags & icons -->
  <meta name="mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black">
  <meta name="apple-mobile-web-app-title" content="VitrinX">
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
