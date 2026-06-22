/**
 * Sanitizes HTML content to prevent XSS attacks while keeping basic layout formatting tags.
 * Preserves safe tags: <p>, <br>, <strong>, <b>, <em>, <i>, <u>, <ul>, <ol>, <li>, <a>.
 */
export function sanitizeHtml(html: string): string {
  if (!html) return "";

  // 1. Remove script tags and all content inside them
  let clean = html.replace(/<script[^>]*>([\s\S]*?)<\/script>/gi, "");

  // 2. Remove iframe tags and all content inside them
  clean = clean.replace(/<iframe[^>]*>([\s\S]*?)<\/iframe>/gi, "");

  // 3. Remove inline event handlers (e.g. onload, onerror, onclick, onmouseover)
  clean = clean.replace(/\s+on\w+\s*=\s*("[^"]*"|'[^']*'|[^\s>]*)/gi, "");

  // 4. Sanitize javascript: and data: URIs in href or src attributes
  clean = clean.replace(/(href|src)\s*=\s*["']\s*(javascript|data):[^"']*["']/gi, '$1="#"');
  clean = clean.replace(/(href|src)\s*=\s*(javascript|data):[^\s>]*/gi, '$1="#"');

  // 5. Remove object, embed, applet, and form/input tags
  clean = clean.replace(/<(object|embed|applet|form|input|button|textarea|select|option)[^>]*>([\s\S]*?)<\/\1>/gi, "");
  clean = clean.replace(/<(object|embed|applet|form|input|button|textarea|select|option)[^>]*\/?>/gi, "");

  // 6. Remove style and link tags to prevent arbitrary layout hijacking
  clean = clean.replace(/<(style|link)[^>]*>([\s\S]*?)<\/\1>/gi, "");
  clean = clean.replace(/<(style|link)[^>]*\/?>/gi, "");

  return clean;
}
