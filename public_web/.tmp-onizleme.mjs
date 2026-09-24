import { chromium } from '@playwright/test';
const dir = 'C:/Users/Casper/AppData/Local/Temp/claude/C--Projects-vixrex/4e55bd78-e44c-4f52-a8d6-e11becd3a0ce/scratchpad';
const HOST = 'https://vixrex-public-ndt76d20q-xpodiumyours-projects.vercel.app';
const b = await chromium.launch();
const p = await b.newPage({ viewport: { width: 430, height: 950 } });
const log = (m)=>console.log('ADIM:', m);
const r = await p.goto(HOST + '/api/owner-session?slug=deneme-kart-testi&ocode=8a83ff229007e4a9e693c48b87cc947e', { waitUntil: 'domcontentloaded', timeout: 60000 });
log('durum ' + (r && r.status()) + ' adres: ' + p.url());
await p.waitForTimeout(4000);
const k = p.getByRole('button', { name: /Tümünü kabul et/i });
if (await k.first().isVisible().catch(()=>false)) { await k.first().click(); log('cerez kapandi'); }
await p.waitForTimeout(1500);
const t = await p.locator('body').innerText().catch(()=>'');
log('ekranda: ' + t.slice(0,180).replace(/\n+/g,' | '));
await p.screenshot({ path: dir + '/onizleme-panel.png' });
await b.close();
