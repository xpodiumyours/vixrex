import { chromium } from '@playwright/test';
const dir = 'C:/Users/Casper/AppData/Local/Temp/claude/C--Projects-vixrex/4e55bd78-e44c-4f52-a8d6-e11becd3a0ce/scratchpad';
const b = await chromium.launch();
const p = await b.newPage({ viewport: { width: 430, height: 900 } });
const log = (m) => console.log('ADIM:', m);
const butonlar = async () => (await p.getByRole('button').allInnerTexts()).map(t=>t.replace(/\s+/g,' ').trim()).filter(Boolean).slice(0,12).join(' | ');
await p.goto('http://localhost:3000/', { waitUntil: 'domcontentloaded', timeout: 60000 });
await p.waitForTimeout(2500);
const kabul = p.getByRole('button', { name: /Tümünü kabul et/i });
if (await kabul.first().isVisible().catch(()=>false)) await kabul.first().click();
await p.waitForTimeout(600);
await p.getByPlaceholder(/isletmeniz|işletmeniz/i).first().fill('Deneme Ic Giyim ' + Date.now().toString().slice(-5));
await p.getByRole('button', { name: /Ücretsiz Vitrinimi Hazırla/i }).click();
await p.waitForTimeout(3500);
await p.getByRole('button', { name: /Giyim/ }).first().click();
await p.waitForTimeout(3000);
const kutular = p.locator('input[type="text"], input[type="tel"]');
const sayi = await kutular.count();
log('girdi kutusu sayisi: ' + sayi);
for (let i = sayi - 1; i >= 0; i--) {
  const k = kutular.nth(i);
  if (await k.isVisible().catch(()=>false)) {
    const ph = await k.getAttribute('placeholder');
    log('kutu ' + i + ' placeholder: ' + ph);
    if (ph && /\d|telefon|whatsapp|5/i.test(ph)) { await k.fill('5321234567'); log('telefon yazildi'); break; }
  }
}
await p.getByRole('button', { name: /WhatsApp Ekle/i }).click().catch(()=>log('whatsapp butonu yok'));
await p.waitForTimeout(3000);
log('butonlar: ' + await butonlar());
await p.getByRole('button', { name: /Vixrex Oluştur/i }).first().click().catch(()=>log('olustur yok'));
await p.waitForTimeout(9000);
log('adres: ' + p.url());
log('butonlar: ' + await butonlar());
await p.screenshot({ path: dir + '/esnaf-akis.png' });
await b.close();
