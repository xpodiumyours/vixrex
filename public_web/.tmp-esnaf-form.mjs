import { chromium } from '@playwright/test';
const dir = 'C:/Users/Casper/AppData/Local/Temp/claude/C--Projects-vixrex/4e55bd78-e44c-4f52-a8d6-e11becd3a0ce/scratchpad';
const b = await chromium.launch();
const p = await b.newPage({ viewport: { width: 430, height: 900 } });
async function not(m){ console.log('ADIM:', m); }
try {
  await p.goto('http://localhost:3000/', { waitUntil: 'domcontentloaded', timeout: 60000 });
  await not('ana sayfa');
  await p.waitForTimeout(2500);
  const kabul = p.getByRole('button', { name: /Tümünü kabul et/i });
  if (await kabul.first().isVisible().catch(()=>false)) { await kabul.first().click(); await not('cerez kabul'); }
  await p.waitForTimeout(800);
  const ad = 'Deneme Ic Giyim ' + Date.now().toString().slice(-5);
  const kutu = p.getByPlaceholder(/isletmeniz|işletmeniz/i).first();
  await kutu.waitFor({ timeout: 15000 });
  await kutu.fill(ad);
  await not('isletme adi: ' + ad);
  await p.getByRole('button', { name: /Ücretsiz Vitrinimi Hazırla/i }).click();
  await not('hazirla tiklandi');
  await p.waitForTimeout(6000);
  await not('adres: ' + p.url());
} catch (e) { await not('HATA: ' + String(e).split('\n')[0]); }
await p.screenshot({ path: dir + '/esnaf-akis.png' });
const t = await p.locator('body').innerText().catch(()=> '');
console.log('--- EKRAN ---'); console.log(t.slice(0, 500));
await b.close();
