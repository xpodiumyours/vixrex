import { chromium } from '@playwright/test';
const dir = 'C:/Users/Casper/AppData/Local/Temp/claude/C--Projects-vixrex/4e55bd78-e44c-4f52-a8d6-e11becd3a0ce/scratchpad';
const HOST = 'https://vixrex-public-lncxtx1y8-xpodiumyours-projects.vercel.app';
const b = await chromium.launch();
const ctx = await b.newContext({ viewport:{width:430,height:950}, deviceScaleFactor:1, extraHTTPHeaders:{
  'x-vercel-protection-bypass':'i1QOkjniMfGRAmvqHKOfZG9L4tQ7VCLy','x-vercel-set-bypass-cookie':'true' }});
const p = await ctx.newPage();
await p.goto(HOST+'/v/kiralik-giyim-erkek',{waitUntil:'networkidle',timeout:60000});
const k = p.getByRole('button',{name:/Tümünü kabul et/i});
if (await k.first().isVisible({timeout:8000}).catch(()=>false)) await k.first().click();
await p.waitForTimeout(1200);
const kart = p.getByText(/Oxford Gömlek/).first();
await kart.scrollIntoViewIfNeeded({timeout:20000});
await p.waitForTimeout(1000);
await p.screenshot({path: dir+'/musteri-kart.jpg', type:'jpeg', quality:70});
const t = await p.locator('body').innerText().catch(()=>'');
const i = t.indexOf('Oxford');
console.log('--- KART ---'); console.log(t.slice(Math.max(0,i-80), i+260).replace(/\n{2,}/g,'\n'));
await b.close();
