const { chromium } = require('./public_web/node_modules/@playwright/test');
const fs = require('node:fs');
(async () => {
 const browser = await chromium.launch({headless:true});
 const page = await browser.newPage({viewport:{width:1440,height:1000}});
 const errors=[];page.on('pageerror',e=>errors.push(e.message));
 await page.goto('http://127.0.0.1:3107/blog',{waitUntil:'networkidle',timeout:120000});
 fs.mkdirSync('../blog-review',{recursive:true});
 await page.screenshot({path:'../blog-review/blog-desktop.png',fullPage:true});
 console.log(JSON.stringify({title:await page.title(),headings:await page.locator('h1,h2,h3').allTextContents(),overflow:await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth),errors}));
 await page.setViewportSize({width:390,height:844});
 await page.screenshot({path:'../blog-review/blog-mobile.png',fullPage:true});
 await page.goto('http://127.0.0.1:3107/blog/dijital-vitrin-hazirlik-listesi',{waitUntil:'networkidle',timeout:120000});
 await page.screenshot({path:'../blog-review/article-mobile.png',fullPage:true});
 console.log(JSON.stringify({article:await page.title(),overflow:await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth),errors}));
 await browser.close();
})().catch(e=>{console.error(e);process.exit(1)});
