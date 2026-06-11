import puppeteer from 'puppeteer';
const b=await puppeteer.launch({args:['--no-sandbox','--disable-setuid-sandbox']});
const p=await b.newPage();
await p.setViewport({width:968,height:1300,deviceScaleFactor:2});
await p.goto('file://'+process.cwd()+'/executive-summary.html',{waitUntil:'networkidle0',timeout:60000});
await new Promise(r=>setTimeout(r,1200));
await p.screenshot({path:'executive-summary.png',fullPage:true});
console.log('rendered'); await b.close();
