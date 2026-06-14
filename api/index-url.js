import crypto from 'crypto';

function generateGoogleJwt(clientEmail, privateKey) {
  const header = Buffer.from(JSON.stringify({ alg: 'RS256', typ: 'JWT' })).toString('base64url');
  const now = Math.floor(Date.now() / 1000);
  const claim = Buffer.from(JSON.stringify({
    iss: clientEmail,
    scope: 'https://www.googleapis.com/auth/indexing',
    aud: 'https://oauth2.googleapis.com/token',
    exp: now + 3600,
    iat: now
  })).toString('base64url');

  const sign = crypto.createSign('RSA-SHA256');
  sign.update(`${header}.${claim}`);
  // Handle escaped newlines in environment variables
  const signature = sign.sign(privateKey.replace(/\\n/g, '\n'), 'base64url');

  return `${header}.${claim}.${signature}`;
}

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    res.status(405).json({ error: 'Method not allowed. Use POST.' });
    return;
  }

  const { slug } = req.body;

  if (!slug || typeof slug !== 'string') {
    res.status(400).json({ error: 'Missing or invalid store slug.' });
    return;
  }

  const clientEmail = process.env.GOOGLE_CLIENT_EMAIL;
  const privateKey = process.env.GOOGLE_PRIVATE_KEY;

  const host = req.headers.host || 'vitrinx.app';
  const protocol = req.headers['x-forwarded-proto'] || 'https';
  const targetUrl = `${protocol}://${host}/v/${slug}`;

  // Graceful fallback for local development if keys are not configured yet
  if (!clientEmail || !privateKey) {
    console.warn('Google Service Account credentials missing. Skipping Indexing API call.');
    res.status(200).json({
      success: true,
      message: 'Skipped Indexing API call: credentials not configured in this environment.',
      url: targetUrl
    });
    return;
  }

  try {
    // 1. Generate JWT Assertion
    const jwt = generateGoogleJwt(clientEmail, privateKey);

    // 2. Fetch OAuth2 Token
    const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      body: new URLSearchParams({
        grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        assertion: jwt
      }).toString()
    });

    if (!tokenResponse.ok) {
      const errText = await tokenResponse.text();
      throw new Error(`Google OAuth token fetch failed: ${tokenResponse.status} - ${errText}`);
    }

    const { access_token } = await tokenResponse.json();

    // 3. Notify Google Indexing API
    const indexingResponse = await fetch('https://indexing.googleapis.com/v3/urlNotifications:publish', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${access_token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        url: targetUrl,
        type: 'URL_UPDATED'
      })
    });

    if (!indexingResponse.ok) {
      const errText = await indexingResponse.text();
      throw new Error(`Google Indexing API call failed: ${indexingResponse.status} - ${errText}`);
    }

    const result = await indexingResponse.json();

    res.status(200).json({
      success: true,
      message: 'Successfully notified Google Indexing API.',
      url: targetUrl,
      result
    });
  } catch (error) {
    console.error('Google Indexing API Error:', error);
    res.status(500).json({ error: error.message || 'Failed to notify Google Indexing API.' });
  }
}
