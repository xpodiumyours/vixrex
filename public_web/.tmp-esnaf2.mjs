import { chromium } from '@playwright/test';
const dir = 'C:/Users/Casper/AppData/Local/Temp/claude/C--Projects-vixrex/4e55bd78-e44c-4f52-a8d6-e11becd3a0ce/scratchpad';
const b = await chromium.launch();
const p = await b.newPage({ viewport: { width: 430, height: 900 } });
const log = (m) => console.log('ADIM:', m);
async function butonlar() {
  const ad = await p.getByRole('button').allInnerTexts();
  return ad.map(t => t.replace(/\s+/g,' ').trim()).filter(Boolean).slice(0, 14).join(' | ');
}
await p.goto('http://localhost:3000/', { waitUntil: 'domcontentloaded', timeout: 60000 });
await p.waitForTimeout(2500);
const kabul = p.getByRole('button', { name: /Tümünü kabul et/i });
if (await kabul.first().isVisible().catch(()=>false)) await kabul.first().click();
await p.waitForTimeout(600);
await p.getByPlaceholder(/isletmeniz|işletmeniz/i).first().fill('Deneme Ic Giyim ' + Date.now().toString().slice(-5));
await p.getByRole('button', { name: /Ücretsiz Vitrinimi Hazırla/i }).click();
await p.waitForTimeout(4000);
log('kategori adimi. butonlar: ' + await butonlar());
await p.getByRole('button', { name: /Giyim/ }).first().click();
await p.waitForTimeout(3500);
log('giyim sonrasi. butonlar: ' + await butonlar());
const hazirla = p.getByRole('button', { name: /hazırlayayım|Hazırla|Devam|Evet/i });
if (await hazirla.first().isVisible().catch(()=>false)) {
  await hazirla.first().click();
  await p.waitForTimeout(6000);
  log('hazirla sonrasi adres: ' + p.url());
  log('butonlar: ' + await butonlar());
}
await p.screenshot({ path: dir + '/esnaf-akis.png' });
await b.close();
