import { chromium } from '@playwright/test';
const dir = 'C:/Users/Casper/AppData/Local/Temp/claude/C--Projects-vixrex/4e55bd78-e44c-4f52-a8d6-e11becd3a0ce/scratchpad';
const HOST = 'https://vixrex-public-ndt76d20q-xpodiumyours-projects.vercel.app';
const b = await chromium.launch();
const ctx = await b.newContext({
  viewport: { width: 430, height: 950 },
  extraHTTPHeaders: {
    'x-vercel-protection-bypass': 'i1QOkjniMfGRAmvqHKOfZG9L4tQ7VCLy',
    'x-vercel-set-bypass-cookie': 'true',
  },
});
const p = await ctx.newPage();
const log = (m) => console.log('ADIM:', m);
p.on('response', r => { const u = r.url(); if (u.includes('/api/') || u.includes('/auth/v1/')) console.log('ISTEK:', r.status(), u.replace(HOST,'').split('?')[0]); });
await p.goto(HOST + '/', { waitUntil: 'domcontentloaded', timeout: 60000 });
log('adres: ' + p.url());
await p.waitForTimeout(2500);
const k = p.getByRole('button', { name: /Tümünü kabul et/i });
if (await k.first().isVisible().catch(()=>false)) await k.first().click();
await p.getByPlaceholder(/isletmeniz|işletmeniz/i).first().fill('Deneme Kart ' + Date.now().toString().slice(-5));
await p.getByRole('button', { name: /Ücretsiz Vitrinimi Hazırla/i }).click();
await p.getByRole('button', { name: /Giyim/ }).first().click({ timeout: 25000 });
log('kategori secildi');
const tel = p.getByPlaceholder(/05xx/i).first();
await tel.waitFor({ timeout: 20000 }); await tel.fill('05321234567');
await p.getByRole('button', { name: /WhatsApp Ekle/i }).first().click();
await p.waitForTimeout(2500);
await p.getByRole('button', { name: /Vixrex Oluştur/i }).first().click({ timeout: 15000 });
log('olustur tiklandi');
await p.waitForURL(/\/app|\/v\//, { timeout: 60000 }).catch(()=>log('yonlendirme olmadi'));
await p.waitForTimeout(6000);
log('son adres: ' + p.url());
await p.screenshot({ path: dir + '/onizleme-uctan-uca.png' });
const t = await p.locator('body').innerText().catch(()=>'');
console.log('--- EKRAN (ilk 300) ---'); console.log(t.slice(0,300).replace(/\n+/g,' | '));
await b.close();
