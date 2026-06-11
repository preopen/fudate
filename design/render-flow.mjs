import puppeteer from 'puppeteer';
const html='flow-screen-map.html', out='flow-screen-map.png', width=1200;
const b=await puppeteer.launch({args:['--no-sandbox','--disable-setuid-sandbox']});
const p=await b.newPage();
await p.setViewport({width,height:900,deviceScaleFactor:2});
await p.goto('file://'+process.cwd()+'/'+html,{waitUntil:'networkidle0',timeout:60000});
await new Promise(r=>setTimeout(r,1200));
await p.screenshot({path:out,fullPage:true});
console.log('rendered',out); await b.close();
